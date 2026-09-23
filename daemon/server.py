import asyncio
import os
import re
import tempfile
from contextlib import asynccontextmanager

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from tetherto.qvac_sdk import Client, TranscribeRequest, completion, load_model, transcribe
from tetherto.qvac_sdk.models import (
    QWEN3_1_7B_INST_Q4,
    QWEN3_4B_INST_Q4_K_M,
    QWEN3_8B_INST_Q4_K_M,
    WHISPER_BASE_Q8_0,
)

WHISPER_MODEL = WHISPER_BASE_Q8_0
SILENCE_HALLUCINATIONS = {
    "you",
    "thank you",
    "thanks for watching",
    "thanks for listening",
    "subscribe",
    "please subscribe",
}

_loaded: dict[str, str] = {}      # model name -> model_id (loaded once, reused)
_load_lock = asyncio.Lock()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # One QVAC worker connection for the whole server (not one per request)
    async with Client() as client:
        app.state.transport = client.transport
        yield


app = FastAPI(lifespan=lifespan)


def print_progress(p):
    print(f"[LoCribe] Downloading model... {p.percentage:.0f}%", end="\r", flush=True)


def _sentence_count(text: str) -> int:
    return len([part for part in re.split(r"[.!?]+", text) if part.strip()])


def _extract_concise_summary(text: str, max_bullets: int) -> str:
    cleaned = re.sub(r"\s+", " ", text).strip()
    if not cleaned:
        return ""
    segments = [part.strip() for part in re.split(r"[.!?]+", cleaned) if part.strip()]
    if not segments:
        return f"- {cleaned[:220]}"
    return "\n".join(f"- {segment}" for segment in segments[:max_bullets])


async def get_model(model_const) -> str:
    """Load a model the first time it's needed, then reuse it."""
    async with _load_lock:
        if model_const.name not in _loaded:
            print(f"[LoCribe] Loading {model_const.name}...")
            _loaded[model_const.name] = await load_model(
                app.state.transport,          # <- the transport, NOT the string "local"
                model_src=model_const,        # <- a registry constant, NOT "whisper-base-q4"
                on_progress=print_progress,
            )
        return _loaded[model_const.name]


def get_optimal_llm():
    # Llama 3 3B/8B are not in the QVAC registry; Qwen3 4B/8B are the closest sizes.
    try:
        ram_gb = os.sysconf("SC_PAGE_SIZE") * os.sysconf("SC_PHYS_PAGES") / (1024 ** 3)
    except Exception:
        return QWEN3_4B_INST_Q4_K_M
    if ram_gb >= 16:
        return QWEN3_8B_INST_Q4_K_M
    if ram_gb >= 8:
        return QWEN3_4B_INST_Q4_K_M
    return QWEN3_1_7B_INST_Q4


@app.get("/status")
async def status():
    print("[LoCribe] Status ping")
    return {"status": "ready"}


@app.post("/transcribe")
async def transcribe_audio(file: UploadFile = File(...)):
    tmp_path = None
    try:
        model_id = await get_model(WHISPER_MODEL)

        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
            tmp.write(await file.read())
            tmp_path = tmp.name

        print("[LoCribe] Processing audio locally...")

        request = TranscribeRequest.model_validate({
            "type": "transcribe",
            "modelId": model_id,
            "audioChunk": {"type": "filePath", "value": tmp_path},
        })

        text = ""
        async for chunk in transcribe(app.state.transport, request):
            if chunk.error:
                raise RuntimeError(chunk.error)
            if chunk.text:
                text += chunk.text
            if chunk.done:
                break

        cleaned_text = text.strip()
        if cleaned_text.casefold() in SILENCE_HALLUCINATIONS:
            cleaned_text = ""
        return {"text": cleaned_text}

    except HTTPException:
        raise
    except Exception as e:
        print(f"[Error] {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if tmp_path and os.path.exists(tmp_path):
            os.remove(tmp_path)


@app.post("/summarize")
async def summarize_text(
    text: str = Form(...),
    mode: str = Form("concise"),
    max_bullets: int = Form(3),
):
    try:
        cleaned_text = text.strip()
        if not cleaned_text:
            raise HTTPException(status_code=400, detail="Text for summarization is empty.")

        bounded_bullets = max(1, min(max_bullets, 6))
        sentence_count = _sentence_count(cleaned_text)

        # For very short transcripts, skip the LLM entirely for faster UX.
        if len(cleaned_text) <= 220 or sentence_count <= 2:
            return {"summary": _extract_concise_summary(cleaned_text, bounded_bullets)}

        llm = get_optimal_llm()
        model_id = await get_model(llm)

        prompt = f"""
You are summarizing a transcript.
Return Markdown only as bullet points.
Keep it concise and faithful to the transcript.
Do not add details not present in input.
Maximum bullet points: {bounded_bullets}.
Maximum total words: {80 if mode == "concise" else 150}.

Transcript:
{cleaned_text}
""".strip()

        print(f"[LoCribe] Generating summary offline with {llm.name}...")

        run = completion(
            app.state.transport,
            model_id=model_id,
            history=[{"role": "user", "content": prompt}],
            generation_params={
                "temp": 0.2,
                "predict": 220 if mode == "concise" else 360,
            },
        )
        final = await run.final

        summary = re.sub(r"<think>.*?</think>", "", final.content_text, flags=re.S).strip()
        if not summary:
            summary = _extract_concise_summary(cleaned_text, bounded_bullets)

        lines = [line.strip() for line in summary.splitlines() if line.strip()]
        bullet_lines = [line for line in lines if line.startswith(("-", "*"))]
        if bullet_lines:
            summary = "\n".join(bullet_lines[:bounded_bullets])
        else:
            summary = _extract_concise_summary(summary, bounded_bullets)

        return {"summary": summary}

    except Exception as e:
        print(f"[Error] {e}")
        raise HTTPException(status_code=500, detail=str(e))

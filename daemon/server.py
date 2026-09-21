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

        return {"text": text.strip()}

    except Exception as e:
        print(f"[Error] {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if tmp_path and os.path.exists(tmp_path):
            os.remove(tmp_path)


@app.post("/summarize")
async def summarize_text(text: str = Form(...)):
    try:
        llm = get_optimal_llm()
        model_id = await get_model(llm)

        prompt = (
            "Provide a clean, formatted Markdown executive summary with bullet points "
            f"for the following text:\n\n{text}"
        )

        print(f"[LoCribe] Generating summary offline with {llm.name}...")

        run = completion(
            app.state.transport,
            model_id=model_id,
            history=[{"role": "user", "content": prompt}],
            generation_params={"temp": 0.3, "predict": 1024},
        )
        final = await run.final

        summary = re.sub(r"<think>.*?</think>", "", final.content_text, flags=re.S).strip()
        return {"summary": summary}

    except Exception as e:
        print(f"[Error] {e}")
        raise HTTPException(status_code=500, detail=str(e))

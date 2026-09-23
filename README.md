# LoCribe

LoCribe is a local-first conversation transcription workspace. It lets you record a conversation or import an audio file, transcribe the speech locally, generate a concise summary, and keep the result in a searchable local vault.

The project is designed around a simple principle: useful meeting and conversation notes should not require sending private audio to a hosted AI service.

## Why LoCribe?

Conversation recordings often contain private, sensitive, or commercially valuable information. Existing transcription tools can be convenient, but they commonly require uploading recordings to a third-party cloud service.

LoCribe was started to explore a different workflow:

- Keep audio processing on the user's machine.
- Make recording and transcription a single, low-friction flow.
- Turn a long conversation into a useful summary immediately.
- Keep saved transcripts available locally without requiring an account.
- Provide a focused workspace instead of a collection of disconnected tools.

The current application is intentionally small and practical. It combines a Flutter desktop interface with a local Python service that uses QVAC models for speech recognition and summarization.

## Features

- Record a conversation from the microphone.
- Import `.mp3`, `.wav`, or `.m4a` audio files.
- Transcribe audio locally with Whisper through the QVAC SDK.
- Detect empty recordings and common speech-recognition hallucinations caused by silence.
- Generate concise Markdown summaries.
- Save transcript sessions to a local SQLite database.
- Browse previous recordings from the Audio Vault.
- Play saved session audio with:
  - Play and pause.
  - Seek through the recording.
  - Playback speeds from `0.75x` to `2x`.
- Copy summaries to the clipboard.
- Export transcript content as a PDF.
- Delete saved transcript sessions.
- Use a local service status indicator to show whether the transcription daemon is available.

## Project structure

```text
.
├── daemon/
│   ├── server.py
│   └── requirments.txt
└── locribe/
    ├── lib/
    │   ├── data/          # API client and local SQLite database
    │   ├── logic/         # BLoC state and application events
    │   └── ui/            # Layouts, views, widgets, and theme
    ├── macos/
    ├── ios/
    └── pubspec.yaml
```

The repository currently contains a Flutter client and a separate local Python daemon. Start both processes when developing locally.

## Requirements

### General

- Git
- Flutter SDK with Dart `3.10.0` or newer
- Python `3.10+`
- A working microphone for recording
- Sufficient disk space for the QVAC models downloaded on first use

### macOS development

- macOS
- Xcode and Xcode Command Line Tools
- CocoaPods
- macOS microphone permission for recording

The current responsive entry point uses the desktop workspace layout, so macOS is the primary development target at this stage.

## Installation

Clone the repository and enter the project directory:

```bash
git clone <repository-url>
cd locribe-repo
```

### 1. Install and configure the local daemon

Create a Python virtual environment:

```bash
cd daemon
python3 -m venv .venv
source .venv/bin/activate
```

On Windows PowerShell, activate it with:

```powershell
.venv\Scripts\Activate.ps1
```

Install the daemon dependencies:

```bash
pip install -r requirments.txt
```

The dependency file is currently named `requirments.txt` in the repository. Keep that spelling when running the command.

Start the local API:

```bash
uvicorn server:app --host 127.0.0.1 --port 8000
```

The daemon should be available at:

```text
http://127.0.0.1:8000
```

You can verify it manually:

```bash
curl http://127.0.0.1:8000/status
```

Expected response:

```json
{"status":"ready"}
```

Keep this terminal running.

### 2. Install Flutter dependencies

Open a second terminal:

```bash
cd locribe
flutter pub get
```

For macOS, install the native pods if Flutter does not do this automatically:

```bash
cd macos
pod install
cd ..
```

## Running the application

### macOS

From the `locribe/` directory:

```bash
flutter run -d macos
```

Or build a debug application without attaching the Flutter runner:

```bash
flutter build macos --debug
```

The built application is located at:

```text
build/macos/Build/Products/Debug/locribe.app
```

### iOS simulator

List available devices:

```bash
flutter devices
```

Then run on a simulator:

```bash
flutter run -d "iPhone 17 Pro"
```

The iOS deployment target is configured for iOS 14 or newer because of the native file-picker dependency.

## How it works

### Recording or importing audio

The Flutter client supports two input paths:

1. **Record** uses the `record` package to capture microphone audio as an `.m4a` file in the operating system's temporary directory.
2. **Choose file** uses `file_picker` to select an existing `.mp3`, `.wav`, or `.m4a` file.

Both paths produce an audio file path and send the same `AudioDropped` event to the application state layer.

### Transcription

The `ScribeBloc` sends the file to the local daemon at:

```text
POST http://127.0.0.1:8000/transcribe
```

The daemon:

1. Loads the Whisper model through the QVAC SDK on first use.
2. Writes the uploaded audio to a temporary file.
3. Runs local speech recognition.
4. Returns the transcript text.
5. Removes the temporary server-side file.

Empty responses and common silence hallucinations such as `you` or `thank you` are rejected so a silent recording is not saved as a real conversation.

### Summarization

After transcription, the Flutter client requests:

```text
POST http://127.0.0.1:8000/summarize
```

Short transcripts are summarized deterministically into concise bullet points. Longer transcripts use a locally selected Qwen model based on available system memory. The daemon limits the number of returned bullets and removes model thinking tags before returning Markdown.

### Local vault

Successful sessions are stored in SQLite using `sqflite`. The database is created in the native application documents directory as:

```text
locribe_vault.db
```

Each saved session currently stores:

- A title derived from the audio filename.
- The raw transcript.
- The generated summary.
- The creation timestamp.

The current database schema does not yet persist the audio file itself. The active session can play its source path while the application is running; durable audio-library storage is part of the planned roadmap.

### State management

The Flutter client uses BLoC:

- `DaemonBloc` tracks whether the local Python service is online.
- `ScribeBloc` manages idle, processing, complete, and error transcription states.
- `VaultBloc` loads and refreshes saved transcript sessions.

## Permissions and native configuration

### macOS

The macOS runner includes entitlements for:

- Microphone input.
- User-selected file read/write access.
- Local network client access.
- Debug network server access where required by the Flutter tooling.

If recording does not start, open **System Settings → Privacy & Security → Microphone** and enable access for the built LoCribe application or your terminal/IDE.

### iOS

The iOS project requires microphone permission for conversation recording and uses an iOS deployment target of 14.0 or newer.

When distributing the application, verify that the production app's `Info.plist` contains an appropriate microphone usage description.

## Troubleshooting

### “Service offline”

The Flutter app expects the daemon at `127.0.0.1:8000`. Confirm that the daemon terminal is running:

```bash
cd daemon
source .venv/bin/activate
uvicorn server:app --host 127.0.0.1 --port 8000
```

Then verify:

```bash
curl http://127.0.0.1:8000/status
```

### The first transcription is slow

The QVAC model is loaded and may be downloaded on its first use. Later requests reuse the loaded model while the daemon remains running.

### Recording permission errors

Grant microphone permission to the app in the operating system settings, stop the Flutter application, and launch it again.

### Silent recordings

A recording with no usable speech is intentionally rejected. Record closer to the microphone, check the system input device, and make sure the microphone level is moving before stopping the recording.

### macOS file-picker entitlement errors

Run:

```bash
flutter clean
flutter pub get
flutter run -d macos
```

The macOS entitlements in `macos/Runner/` must include user-selected read/write access.

## Development checks

From `locribe/`:

```bash
flutter analyze
flutter build macos --debug
```

The analyzer may report an existing `path` package dependency warning in the local database file. The macOS build should still complete successfully.

## Motivation and design principles

### Local by default

Audio is sensitive. The application sends audio only to the local daemon running on the same machine rather than to a hosted LoCribe service.

### One workflow from voice to notes

The useful result is not merely a text dump. LoCribe connects recording, transcription, summary generation, playback, and local retrieval in one workspace.

### Transparent failure

The interface reports when the daemon is offline, when microphone access is unavailable, and when no speech is detected. It should not present an empty or hallucinated result as a successful transcript.

### Small, replaceable components

The Flutter client, local API, model layer, and local database are separated so each can evolve without rewriting the whole application.

## Future plans

The roadmap is intentionally focused on making the local workflow reliable before expanding the feature set.

### Near term

- Persist audio files or managed audio references in the local vault.
- Restore audio playback when a saved recording is reopened.
- Add a recording waveform and live input-level indicator.
- Add pause/resume recording.
- Add better microphone and audio-device selection.
- Add transcript search and filtering.
- Improve empty-audio detection using duration and signal-level checks.
- Add automated tests for the daemon API and core BLoC flows.

### Medium term

- Add speaker labels and speaker-aware formatting.
- Support editing transcripts and summaries.
- Add configurable summary styles and note templates.
- Add export formats such as Markdown, plain text, and JSON.
- Add background transcription with a visible job queue.
- Improve mobile-specific navigation and layout.
- Add encrypted local vault storage and optional user-controlled backups.

### Longer term

- Support live streaming transcription during a conversation.
- Offer model selection based on speed, accuracy, and device capability.
- Add optional local semantic search across the vault.
- Provide a privacy-preserving sync option that users can host themselves.
- Package the daemon and model setup into a simpler first-run installer.

## Current limitations

- The local daemon must be started separately.
- Model downloads and inference depend on the machine's available resources.
- The current saved vault stores transcript content and metadata, not a durable copy of every source audio file.
- Speaker diarization is not implemented yet.
- The desktop layout is currently the most complete user experience.
- This is an actively evolving project and the local API is not intended to be exposed to the public internet.

## License

No license has been selected for this repository yet. Add a license before distributing LoCribe outside the project team.

# Content Ingestion: Add Dedicated ASR Engine for Audio/Video Transcription

**Severity:** minor
**Affected area:** Content Ingestion — Transcription
**Reported by:** codebase audit

## Description

The current transcription system (`lib/core/data/extraction/transcription_extractor.dart`) relies on two mechanisms:

1. **YouTube transcripts** — Fetches from `youtubetranscript.com` third-party API (could break)
2. **LLM-based transcription** — For all other audio/video, sends base64-encoded content to the LLM

The LLM-based approach has the same problems as the OCR approach:
- Expensive (LLM audio tokens are costly)
- Slow (3-15s per minute of audio)
- Model-dependent (requires multimodal model with audio support)
- No offline capability
- No chunking for long audio (entire file sent as one prompt)

## Expected behavior

Audio/video transcription should:
- Use a dedicated ASR engine (Whisper, or on-device speech recognition)
- Work offline
- Process audio faster than real-time (e.g., 10-min audio in <2 min)
- Be cost-effective (free ASR vs paid LLM tokens)
- Handle long audio (chunked processing)
- Provide confidence scores per segment

## Actual behavior

Only YouTube transcripts use a dedicated API. All other audio goes through the generic LLM.

## Code analysis

- `lib/core/data/extraction/transcription_extractor.dart:1-358` — Entire file: YouTube API fallback chain + LLM fallback
- `lib/core/data/extraction/transcription_extractor.dart:190-280` — `_transcribeFile()` sends base64 audio to LLM
- `lib/features/ingestion/services/document_extractor.dart:230-260` — `_extractVideo()` and `_extractAudio()` route to `TranscriptionExtractor`
- `lib/features/ingestion/presentation/upload_screen.dart:248-278` — Shows warning about model capability for audio

## Suggested approach

1. **Integrate a local ASR engine**:
   - `whisper_flutter` or `whisper.cpp` bindings — OpenAI's Whisper model for on-device transcription. Supports 100+ languages. Free, fast, works offline.
   - `google_mlkit_speech_recognition` — On-device speech recognition (smaller vocabulary but faster)
   - `speech_to_text` (already used for STT input) — Could be repurposed for file transcription

2. **Create a `TranscriptionPipeline`** that:
   - Detects input type (YouTube URL, local file, remote URL)
   - For YouTube: try dedicated API first, fall back to page scrape, then ASR
   - For local files: try Whisper first, fall back to LLM
   - For long audio: chunk into 30-second segments, transcribe in parallel, merge results

3. **Add transcription model selection** in Settings:
   - "Fast (local)" — Whisper tiny/base for quick transcription
   - "Accurate (local)" — Whisper small/medium for better quality
   - "Best (LLM)" — Use LLM when highest accuracy needed

4. **Report transcription confidence** — Store per-segment confidence scores from the ASR engine in `Source.extractionMeta`

5. **Reduce LLM dependency** — The LLM should only be used for the most challenging audio (heavy accents, poor audio quality, specialized vocabulary) where local ASR confidence is low.

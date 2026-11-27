// Edge Function: process-voice
//
// The app uploads a recording to the private `voice` bucket, then calls this
// function. It transcribes the audio with Groq Whisper (using the sender's
// language as a hint), translates the transcript for the recipient, and
// stores ONE row in `public.messages` of type `voice`.
//
// Request (POST, user JWT in the Authorization header):
//   { "conversation_id": "<uuid>", "audio_path": "<conversation_id>/<user_id>_<time>.m4a" }

import {
  admin,
  authenticate,
  enforceRateLimit,
  insertMessage,
  loadChatContext,
} from '../_shared/chat.ts';
import { transcribe, translateForRecipient } from '../_shared/groq.ts';
import { errorResponse, handlePreflight, HttpError, json } from '../_shared/http.ts';

const VOICE_BUCKET = 'voice';
// The app records at most 60 s at ~64 kbps (about 0.5 MB). A tight limit keeps
// storage and Groq audio quota small.
const MAX_AUDIO_BYTES = 2 * 1024 * 1024;

Deno.serve(async (req) => {
  const preflight = handlePreflight(req);
  if (preflight) return preflight;

  try {
    if (req.method !== 'POST') throw new HttpError(405, 'Method not allowed.');

    const userId = await authenticate(req);

    let payload: { conversation_id?: unknown; audio_path?: unknown };
    try {
      payload = await req.json();
    } catch {
      throw new HttpError(400, 'Invalid request.');
    }

    const conversationId =
      typeof payload.conversation_id === 'string' ? payload.conversation_id : '';
    const audioPath = typeof payload.audio_path === 'string' ? payload.audio_path : '';

    if (!conversationId || !audioPath) throw new HttpError(400, 'Invalid request.');

    // The file must live in this conversation's folder and be named after the
    // caller, so nobody can attach somebody else's recording.
    const expectedPrefix = `${conversationId}/${userId}_`;
    const fileName = audioPath.slice(expectedPrefix.length);
    if (!audioPath.startsWith(expectedPrefix) || !/^[A-Za-z0-9._-]+$/.test(fileName)) {
      throw new HttpError(400, 'Invalid audio file.');
    }

    const { sourceLang, targetLang } = await loadChatContext(userId, conversationId);
    await enforceRateLimit(userId);

    // 1. Fetch the recording.
    const { data: audio, error: downloadError } = await admin.storage
      .from(VOICE_BUCKET)
      .download(audioPath);
    if (downloadError || !audio) throw new HttpError(404, 'Voice message not found.');
    if (audio.size === 0) throw new HttpError(400, 'The recording is empty.');
    if (audio.size > MAX_AUDIO_BYTES) throw new HttpError(413, 'The recording is too large.');

    // 2. Speech to text.
    let transcript: string;
    try {
      transcript = await transcribe(audio, `${userId}_${fileName}`, sourceLang);
    } catch (error) {
      console.error('Transcription failed:', error);
      throw new HttpError(502, 'Could not transcribe the voice message. Please try again.');
    }
    if (!transcript) {
      throw new HttpError(422, 'No speech was detected. Please try again.');
    }

    // 3. Translate (skipped when both people use the same language).
    const result = await translateForRecipient(transcript, sourceLang, targetLang);

    // 4. Store the message.
    const message = await insertMessage({
      conversationId,
      senderId: userId,
      type: 'voice',
      originalText: transcript,
      translatedText: result.translatedText,
      sourceLang: result.sourceLang,
      targetLang,
      audioPath,
    });

    return json({ message, translation_failed: result.translationFailed });
  } catch (error) {
    return errorResponse(error);
  }
});

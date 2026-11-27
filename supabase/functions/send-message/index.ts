// Edge Function: send-message
//
// Receives a text message from the app, translates it into the recipient's
// language with Groq, and stores ONE row in `public.messages`.
//
// Request (POST, user JWT in the Authorization header):
//   { "conversation_id": "<uuid>", "text": "Hello" }
//
// The message is saved even when translation fails, so chat never breaks
// because of the AI provider. The response then has `translation_failed: true`.

import {
  authenticate,
  enforceRateLimit,
  insertMessage,
  loadChatContext,
} from '../_shared/chat.ts';
import { translateForRecipient } from '../_shared/groq.ts';
import { errorResponse, handlePreflight, HttpError, json } from '../_shared/http.ts';

const MAX_TEXT_LENGTH = 1000;

Deno.serve(async (req) => {
  const preflight = handlePreflight(req);
  if (preflight) return preflight;

  try {
    if (req.method !== 'POST') throw new HttpError(405, 'Method not allowed.');

    const userId = await authenticate(req);

    let payload: { conversation_id?: unknown; text?: unknown };
    try {
      payload = await req.json();
    } catch {
      throw new HttpError(400, 'Invalid request.');
    }

    const conversationId =
      typeof payload.conversation_id === 'string' ? payload.conversation_id : '';
    const text = typeof payload.text === 'string' ? payload.text.trim() : '';

    if (!conversationId) throw new HttpError(400, 'Invalid request.');
    if (!text) throw new HttpError(400, 'Message cannot be empty.');
    if (text.length > MAX_TEXT_LENGTH) {
      throw new HttpError(400, `Message is too long (max ${MAX_TEXT_LENGTH} characters).`);
    }

    const { sourceLang, targetLang } = await loadChatContext(userId, conversationId);
    await enforceRateLimit(userId);

    const result = await translateForRecipient(text, sourceLang, targetLang);

    const message = await insertMessage({
      conversationId,
      senderId: userId,
      type: 'text',
      originalText: text,
      translatedText: result.translatedText,
      sourceLang: result.sourceLang,
      targetLang,
    });

    return json({ message, translation_failed: result.translationFailed });
  } catch (error) {
    return errorResponse(error);
  }
});

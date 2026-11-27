// Chat helpers shared by the Edge Functions: authentication, membership
// checks, language lookup, rate limiting and message storage. All of them use
// the service role client, so every check here is the only thing protecting
// the data.

import { createClient } from 'npm:@supabase/supabase-js@2';
import { HttpError } from './http.ts';

/** Supported languages. Keep in sync with the SQL checks and the Flutter app. */
export const LANGUAGES = ['en', 'ur', 'ar', 'hi', 'fr', 'es', 'pa', 'sd'] as const;
export type Lang = (typeof LANGUAGES)[number];

export function isLang(value: unknown): value is Lang {
  return typeof value === 'string' && (LANGUAGES as readonly string[]).includes(value);
}

export const admin = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  { auth: { persistSession: false, autoRefreshToken: false } },
);

/** Returns the id of the signed-in user, or throws a 401. */
export async function authenticate(req: Request): Promise<string> {
  const token = req.headers.get('Authorization')?.replace(/^Bearer\s+/i, '');
  if (!token) throw new HttpError(401, 'You are not signed in.');

  const { data, error } = await admin.auth.getUser(token);
  if (error || !data.user) {
    throw new HttpError(401, 'Your session has expired. Please sign in again.');
  }
  return data.user.id;
}

// Free-tier protection. Groq's free plan has small per-minute and per-day
// request limits shared by every user, so one person cannot be allowed to use
// them all. Counting stored messages needs no extra table.
const MAX_MESSAGES_PER_MINUTE = 10;
const MAX_MESSAGES_PER_DAY = 200;

async function countRecentMessages(userId: string, windowMs: number): Promise<number> {
  const since = new Date(Date.now() - windowMs).toISOString();
  const { count, error } = await admin
    .from('messages')
    .select('id', { count: 'exact', head: true })
    .eq('sender_id', userId)
    .gte('created_at', since);

  if (error) {
    // Never block chat because the counter failed.
    console.error('Rate limit check failed:', error);
    return 0;
  }
  return count ?? 0;
}

/** Throws a 429 when [userId] is sending too many messages. */
export async function enforceRateLimit(userId: string): Promise<void> {
  if ((await countRecentMessages(userId, 60_000)) >= MAX_MESSAGES_PER_MINUTE) {
    throw new HttpError(429, 'You are sending messages too quickly. Please wait a moment.');
  }
  if ((await countRecentMessages(userId, 24 * 60 * 60_000)) >= MAX_MESSAGES_PER_DAY) {
    throw new HttpError(429, 'Daily message limit reached. Please try again tomorrow.');
  }
}

export interface ChatContext {
  /** Language of the sender (the caller), from their profile. */
  sourceLang: Lang;
  /** Language of the other participant, from their profile. */
  targetLang: Lang;
}

/**
 * Checks that [userId] belongs to [conversationId] and returns both
 * participants' languages. Languages always come from the profiles table,
 * never from the client.
 */
export async function loadChatContext(
  userId: string,
  conversationId: string,
): Promise<ChatContext> {
  const { data: conversation, error } = await admin
    .from('conversations')
    .select('user1_id, user2_id')
    .eq('id', conversationId)
    .maybeSingle();

  if (
    error ||
    !conversation ||
    (conversation.user1_id !== userId && conversation.user2_id !== userId)
  ) {
    throw new HttpError(404, 'Conversation not found.');
  }

  const recipientId =
    conversation.user1_id === userId ? conversation.user2_id : conversation.user1_id;

  const { data: profiles, error: profilesError } = await admin
    .from('profiles')
    .select('id, preferred_language')
    .in('id', [userId, recipientId]);

  const sourceLang = profiles?.find((p) => p.id === userId)?.preferred_language;
  const targetLang = profiles?.find((p) => p.id === recipientId)?.preferred_language;

  if (profilesError || !isLang(sourceLang) || !isLang(targetLang)) {
    throw new HttpError(500, 'Could not load the chat participants.');
  }
  return { sourceLang, targetLang };
}

export interface NewMessage {
  conversationId: string;
  senderId: string;
  type: 'text' | 'voice';
  originalText: string;
  translatedText: string | null;
  sourceLang: Lang;
  targetLang: Lang;
  audioPath?: string;
}

/** Inserts the message row and returns it. */
export async function insertMessage(message: NewMessage) {
  const { data, error } = await admin
    .from('messages')
    .insert({
      conversation_id: message.conversationId,
      sender_id: message.senderId,
      type: message.type,
      original_text: message.originalText,
      translated_text: message.translatedText,
      source_lang: message.sourceLang,
      target_lang: message.targetLang,
      audio_path: message.audioPath ?? null,
    })
    .select()
    .single();

  if (error) {
    console.error('Insert failed:', error);
    throw new HttpError(500, 'Could not send the message. Please try again.');
  }
  return data;
}

export interface TranslatedMessage {
  /** Stored `translated_text`; null when no translation is needed or possible. */
  translatedText: string | null;
  /** The language the text was really written in. */
  sourceLang: Lang;
  translationFailed: boolean;
}

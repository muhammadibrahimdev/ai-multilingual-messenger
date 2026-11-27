-- AI Multilingual Messenger: Phase 2 hardening
-- Run AFTER the `send-message` Edge Function is deployed and tested.
--
-- From now on only the Edge Function (service role) can create messages, so a
-- user can no longer insert rows with a forged `translated_text` or a fake
-- sender. Reading messages and realtime are unaffected.

drop policy if exists "messages_insert" on public.messages;

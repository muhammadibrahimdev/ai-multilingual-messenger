-- AI Multilingual Messenger: more languages
-- Run in the Supabase SQL Editor (safe to run more than once).
--
-- Allows English, Urdu, Arabic, Hindi, French, Spanish, Punjabi and Sindhi
-- in the profile and message language columns.

alter table public.profiles
  drop constraint if exists profiles_preferred_language_check;
alter table public.profiles
  add constraint profiles_preferred_language_check
  check (preferred_language in ('en', 'ur', 'ar', 'hi', 'fr', 'es', 'pa', 'sd'));

alter table public.messages
  drop constraint if exists messages_source_lang_check;
alter table public.messages
  add constraint messages_source_lang_check
  check (source_lang in ('en', 'ur', 'ar', 'hi', 'fr', 'es', 'pa', 'sd'));

alter table public.messages
  drop constraint if exists messages_target_lang_check;
alter table public.messages
  add constraint messages_target_lang_check
  check (target_lang in ('en', 'ur', 'ar', 'hi', 'fr', 'es', 'pa', 'sd'));

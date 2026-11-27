-- AI Multilingual Messenger: chat list function + permission hardening
-- Run AFTER 01_schema.sql: Supabase Dashboard -> SQL Editor -> New query -> Run

-- Returns one row per conversation of the signed-in user, with the other
-- participant and the latest message. SECURITY INVOKER (the default) means
-- row level security still applies, so users only ever see their own data.
-- The preview shows the sender's original text for your own messages and the
-- translation (when available) for messages you received.
create or replace function public.get_my_conversations()
returns table (
  conversation_id uuid,
  conversation_created_at timestamptz,
  other_user_id uuid,
  other_username text,
  other_display_name text,
  other_language text,
  last_message_type text,
  last_message_text text,
  last_message_at timestamptz
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    c.id,
    c.created_at,
    p.id,
    p.username,
    p.display_name,
    p.preferred_language,
    m.type,
    case
      when m.sender_id = auth.uid() then m.original_text
      else coalesce(m.translated_text, m.original_text)
    end,
    m.created_at
  from public.conversations c
  join public.profiles p
    on p.id = case when c.user1_id = auth.uid() then c.user2_id else c.user1_id end
  left join lateral (
    select mm.type, mm.sender_id, mm.original_text, mm.translated_text, mm.created_at
    from public.messages mm
    where mm.conversation_id = c.id
    order by mm.created_at desc
    limit 1
  ) m on true
  where auth.uid() in (c.user1_id, c.user2_id)
  order by coalesce(m.created_at, c.created_at) desc;
$$;

-- Only signed-in users may call the RPC functions.
revoke execute on function public.get_my_conversations() from public, anon;
grant execute on function public.get_my_conversations() to authenticated;

revoke execute on function public.get_or_create_conversation(uuid) from public, anon;
grant execute on function public.get_or_create_conversation(uuid) to authenticated;

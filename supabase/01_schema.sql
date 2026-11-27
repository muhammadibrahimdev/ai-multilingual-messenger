-- AI Multilingual Messenger: Supabase schema
-- Run once in Supabase Dashboard -> SQL Editor -> New query -> Run

-- 1. TABLES -----------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  display_name text,
  preferred_language text not null default 'en' check (preferred_language in ('en', 'ur')),
  created_at timestamptz not null default now()
);

create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  user1_id uuid not null references public.profiles(id) on delete cascade,
  user2_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  check (user1_id < user2_id),
  unique (user1_id, user2_id)
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  type text not null default 'text' check (type in ('text', 'voice')),
  original_text text,
  translated_text text,
  source_lang text check (source_lang in ('en', 'ur')),
  target_lang text check (target_lang in ('en', 'ur')),
  audio_path text,
  created_at timestamptz not null default now()
);

create index messages_conv_created_idx on public.messages (conversation_id, created_at);

-- 2. AUTO-CREATE PROFILE ON SIGNUP -------------------------------------
-- Flutter signUp() must pass data: {username, display_name, preferred_language}

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, username, display_name, preferred_language)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'preferred_language', 'en')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 3. HELPERS -----------------------------------------------------------

create or replace function public.is_conversation_member(conv uuid)
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1 from public.conversations c
    where c.id = conv
      and auth.uid() in (c.user1_id, c.user2_id)
  );
$$;

-- Call from Flutter: supabase.rpc('get_or_create_conversation', params: {'other_user': id})
create or replace function public.get_or_create_conversation(other_user uuid)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
  me uuid := auth.uid();
  u1 uuid;
  u2 uuid;
  conv_id uuid;
begin
  if me is null then raise exception 'Not authenticated'; end if;
  if other_user = me then raise exception 'Cannot chat with yourself'; end if;

  u1 := least(me, other_user);
  u2 := greatest(me, other_user);

  select id into conv_id from conversations where user1_id = u1 and user2_id = u2;
  if conv_id is null then
    insert into conversations (user1_id, user2_id) values (u1, u2) returning id into conv_id;
  end if;
  return conv_id;
end;
$$;

-- 4. ROW LEVEL SECURITY ------------------------------------------------

alter table public.profiles enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;

-- profiles: any logged-in user can search/read, only edit your own
create policy "profiles_select" on public.profiles
  for select to authenticated using (true);
create policy "profiles_update_own" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- conversations: only participants (creation goes through get_or_create_conversation)
create policy "conversations_select" on public.conversations
  for select to authenticated using (auth.uid() in (user1_id, user2_id));

-- messages: participants can read; can only insert as yourself into your own conversations
create policy "messages_select" on public.messages
  for select to authenticated using (public.is_conversation_member(conversation_id));
create policy "messages_insert" on public.messages
  for insert to authenticated
  with check (sender_id = auth.uid() and public.is_conversation_member(conversation_id));

-- 5. REALTIME ----------------------------------------------------------

alter publication supabase_realtime add table public.messages;

-- 6. STORAGE (private voice bucket) -----------------------------------
-- File path convention: <conversation_id>/<filename>.m4a

insert into storage.buckets (id, name, public)
values ('voice', 'voice', false)
on conflict (id) do nothing;

create policy "voice_select_members" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'voice'
    and public.is_conversation_member(((storage.foldername(name))[1])::uuid)
  );

create policy "voice_insert_members" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'voice'
    and public.is_conversation_member(((storage.foldername(name))[1])::uuid)
  );

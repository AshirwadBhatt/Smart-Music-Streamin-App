-- ASHU – Supabase Initial Schema
-- Run this ENTIRE file in Supabase → SQL Editor

-- Profiles
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  username    text,
  avatar_url  text,
  email       text,
  phone       text,
  created_at  timestamptz default now()
);

-- Songs catalogue
create table if not exists public.songs (
  id               text primary key,
  title            text not null,
  artist           text not null,
  album            text,
  artwork_url      text,
  audio_url        text not null,
  duration_seconds integer default 0,
  genre            text,
  jamendo_id       text,
  indexed_at       timestamptz default now()
);

-- User playlists
create table if not exists public.playlists (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  name        text not null,
  cover_url   text,
  is_public   boolean default false,
  created_at  timestamptz default now()
);

-- Playlist songs join
create table if not exists public.playlist_songs (
  playlist_id uuid references public.playlists(id) on delete cascade,
  song_id     text references public.songs(id) on delete cascade,
  position    integer default 0,
  added_at    timestamptz default now(),
  primary key (playlist_id, song_id)
);

-- Liked songs
create table if not exists public.liked_songs (
  user_id  uuid references public.profiles(id) on delete cascade,
  song_id  text references public.songs(id) on delete cascade,
  liked_at timestamptz default now(),
  primary key (user_id, song_id)
);

-- Recently played
create table if not exists public.recently_played (
  id         bigserial primary key,
  user_id    uuid references public.profiles(id) on delete cascade,
  song_id    text references public.songs(id) on delete cascade,
  played_at  timestamptz default now()
);

-- Listening history
create table if not exists public.listening_history (
  id                    bigserial primary key,
  user_id               uuid references public.profiles(id) on delete cascade,
  song_id               text references public.songs(id) on delete cascade,
  play_duration_seconds integer default 0,
  played_at             timestamptz default now()
);

-- Followed artists
create table if not exists public.followed_artists (
  user_id      uuid references public.profiles(id) on delete cascade,
  artist_id    text not null,
  artist_name  text,
  followed_at  timestamptz default now(),
  primary key (user_id, artist_id)
);

-- ── Row Level Security ────────────────────────────────────────
alter table public.profiles          enable row level security;
alter table public.playlists         enable row level security;
alter table public.playlist_songs    enable row level security;
alter table public.liked_songs       enable row level security;
alter table public.recently_played   enable row level security;
alter table public.listening_history enable row level security;
alter table public.followed_artists  enable row level security;
alter table public.songs             enable row level security;

-- Drop existing policies safely before recreating
drop policy if exists "profiles_select"       on public.profiles;
drop policy if exists "profiles_insert"       on public.profiles;
drop policy if exists "profiles_update"       on public.profiles;
drop policy if exists "songs_select"          on public.songs;
drop policy if exists "songs_insert"          on public.songs;
drop policy if exists "songs_update"          on public.songs;
drop policy if exists "playlists_select"      on public.playlists;
drop policy if exists "playlists_insert"      on public.playlists;
drop policy if exists "playlists_update"      on public.playlists;
drop policy if exists "playlists_delete"      on public.playlists;
drop policy if exists "playlist_songs_all"    on public.playlist_songs;
drop policy if exists "liked_songs_all"       on public.liked_songs;
drop policy if exists "recently_played_all"   on public.recently_played;
drop policy if exists "listening_history_all" on public.listening_history;
drop policy if exists "followed_artists_all"  on public.followed_artists;

-- Profiles
create policy "profiles_select" on public.profiles for select using (auth.uid() = id);
create policy "profiles_insert" on public.profiles for insert with check (auth.uid() = id);
create policy "profiles_update" on public.profiles for update using (auth.uid() = id);

-- Songs: authenticated users can read, insert AND update (needed for upsert)
create policy "songs_select" on public.songs for select using (true);
create policy "songs_insert" on public.songs for insert with check (auth.role() = 'authenticated');
create policy "songs_update" on public.songs for update using (auth.role() = 'authenticated');

-- Playlists
create policy "playlists_select" on public.playlists for select using (auth.uid() = user_id or is_public);
create policy "playlists_insert" on public.playlists for insert with check (auth.uid() = user_id);
create policy "playlists_update" on public.playlists for update using (auth.uid() = user_id);
create policy "playlists_delete" on public.playlists for delete using (auth.uid() = user_id);

-- Playlist songs
create policy "playlist_songs_all" on public.playlist_songs for all
  using (auth.uid() = (select user_id from public.playlists where id = playlist_id));

-- Liked songs
create policy "liked_songs_all" on public.liked_songs for all using (auth.uid() = user_id);

-- Recently played
create policy "recently_played_all" on public.recently_played for all using (auth.uid() = user_id);

-- Listening history
create policy "listening_history_all" on public.listening_history for all using (auth.uid() = user_id);

-- Followed artists
create policy "followed_artists_all" on public.followed_artists for all using (auth.uid() = user_id);

-- ── Auto-create profile on signup ──────────────────────────────
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, username, avatar_url)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

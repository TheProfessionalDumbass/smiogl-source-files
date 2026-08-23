

A public, Supabase-backed mathematics learning platform.

## Included

- Supabase email/password authentication
- PostgreSQL persistence with protected database functions and Row Level Security enabled
- Per-user profiles, roles, progress, attempts, rewards, inventory, streaks, and achievements
- Sequential lesson locking, adaptive hints, verification problems, revives, and the Math-io Mart
- Teacher-created quiz rooms with up to 50 authored questions, invitation codes, polling-based live updates, and browser review signals
- Responsive, installable PWA experience

## Stack

- React 19, TypeScript, and Vinext/Next App Router
- Supabase Auth + PostgreSQL
- Cloudflare Workers-compatible output

## Quick local setup

1. Create a free Supabase project.
2. On a new/empty Supabase project, run `supabase/migrations/20260823000000_initial.sql` in the Supabase SQL Editor. This is the complete fresh-install query.
3. Copy `.env.example` to `.env.local` and fill in the Project URL and publishable key.
4. Run `pnpm install`.
5. Run `pnpm dev`.

For the complete public deployment walkthrough, see [docs/DEPLOY_SUPABASE.md](docs/DEPLOY_SUPABASE.md).

## Validation

- `pnpm exec tsc --noEmit`
- `pnpm lint`
- `pnpm build`

## Security model

The browser receives only the Supabase Project URL and publishable key. Every application request also sends the signed-in user’s access token. Direct table access is revoked from browser roles; narrowly scoped PostgreSQL functions validate `auth.uid()` and apply the application’s rules atomically. No service-role key is stored in the app.

Before a controlled school rollout, replace self-service teacher role selection with an administrator-maintained allowlist and complete the institution’s privacy/accessibility review.

Browser visibility, focus, fullscreen, and connection events are contextual review signals. They are not proof of cheating and cannot identify which external app or site was used.



A public, Supabase-backed mathematics learning platform.
# 
## Included

- Supabase email/password authentication
- PostgreSQL persistence with protected database functions and Row Level Security enabled
- Per-user profiles, roles, progress, attempts, rewards, inventory, streaks, and achievements
- Responsive, installable PWA experience

## Stack

- React 19, TypeScript, and Vinext/Next App Router
- Supabase Auth + PostgreSQL
- Cloudflare Workers-compatible output

## Quick local setup

1. Create a free Supabase project.
2. On a new/empty Supabase project, run the files in `supabase/migrations` in timestamp order in the Supabase SQL Editor. Existing projects only need migrations newer than the last one already applied.
3. Copy `.env.example` to `.env.local` and fill in the Project URL and publishable key.
4. Run `pnpm install`.
5. Run `pnpm dev`.

For the complete public deployment walkthrough, see [docs/DEPLOY_SUPABASE.md](docs/DEPLOY_SUPABASE.md).

## Validation

- `pnpm exec tsc --noEmit`
- `pnpm lint`
- `pnpm build`

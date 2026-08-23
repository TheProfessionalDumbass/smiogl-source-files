

Supabase hosts this app’s authentication and database, but it does not host a full Vinext/Next.js frontend. The deployment below uses the Supabase Free plan for the backend and the Cloudflare Workers Free plan for the public website. No paid plan is required for a small school/demo deployment within the free quotas.

## 1. Create the Supabase backend

1. Open the Supabase Dashboard and select **New project**.
2. Choose the **Free** plan, enter a project name such as `smiogl-mathio`, create a strong database password, and choose the closest region.
3. Wait for the project to finish provisioning.
4. Open **SQL Editor** and select **New query**.
5. Open `supabase/migrations/20260823000000_initial.sql` from this project, copy all of it into the query, and select **Run**. Use this complete query on a new/empty Supabase project.
6. Confirm that the query finishes successfully. This creates the tables, starter lessons, security rules, application functions, and support for up to 50 teacher-authored questions in each room.

## 2. Get the two public Supabase values

1. In the Supabase project, open **Connect** (or **Project Settings → API Keys**).
2. Copy the **Project URL**. It looks like `https://abc123.supabase.co`.
3. Copy the **Publishable key**. It normally starts with `sb_publishable_`.
4. Do not use the secret/service-role key.

## 3. Configure the app locally

1. In the project folder, duplicate `.env.example` and name the copy `.env.local`.
2. Fill it in like this:

```env
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_YOUR_KEY
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

3. In a terminal opened in the project folder, run:

```powershell
pnpm install
pnpm dev
```

4. Open the local URL printed by the terminal.
5. Create a test account. If email confirmation is enabled, open the confirmation message before signing in.
6. Verify that the dashboard loads, a lesson opens, and switching between Student and Teacher works.

## 4. Create the public Cloudflare URL

1. In the same terminal, sign in to Cloudflare:

```powershell
pnpm exec wrangler login
```

2. Approve the browser prompt.
3. Cloudflare will ask you to create a `workers.dev` subdomain if your account does not already have one. Complete that one-time step.
4. Your final URL will normally be:

```text
https://smiogl-mathio.YOUR-WORKERS-SUBDOMAIN.workers.dev
```

## 5. Add the production settings

1. Duplicate `.env.example` again and name this copy `.env.production.local`.
2. Use your real Supabase values and expected Cloudflare URL:

```env
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_YOUR_KEY
NEXT_PUBLIC_SITE_URL=https://smiogl-mathio.YOUR-WORKERS-SUBDOMAIN.workers.dev
```

3. These `.env*` files are ignored by Git. Never commit credentials, even though the publishable key is designed for browser use.

## 6. Deploy the website

Run:

```powershell
pnpm deploy:cloudflare
```


If Cloudflare assigns a different URL, update `NEXT_PUBLIC_SITE_URL` in `.env.production.local` and run `pnpm deploy:cloudflare` one more time.

## 7. Finish Supabase Auth settings

1. Return to Supabase.
2. Open **Authentication → URL Configuration**.
3. Set **Site URL** to the exact Cloudflare URL Wrangler printed.
4. Add the same URL under **Redirect URLs**. Also add `http://localhost:3000/**` while developing locally.
5. Open **Authentication → Providers → Email** and keep Email/Password enabled.
6. For a quick private demo, you may temporarily disable email confirmation. For a public deployment, keep confirmation enabled and configure your own SMTP provider before relying on it for a classroom-scale rollout.

## 8. Final test

Use a private/incognito browser window and test the public URL:

1. Create a new student account and confirm the email.
2. Complete the first practice problem and its verification problem.
3. Switch a second account to Teacher, choose a question count greater than one, complete each problem card, create the quiz room, and copy the invite code.
4. Join that code from the student account.
5. Start and close the room from the teacher account.

## Updating later

If the Supabase project was created before support for multiple teacher-authored questions, first run this file once in **Supabase Dashboard → SQL Editor**:

```text
supabase/migrations/20260823010000_multiple_room_questions.sql
```

After making changes, run:

```powershell
pnpm deploy:cloudflare
```

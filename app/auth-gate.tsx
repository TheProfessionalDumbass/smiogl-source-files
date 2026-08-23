'use client';

import type { Session } from '@supabase/supabase-js';
import { FormEvent, useEffect, useState } from 'react';
import DashboardClient from './dashboard-client';
import { BrandLogo } from './brand-logo';
import { getSupabaseBrowserClient } from '@/lib/supabase-client';

export default function AuthGate() {
  const [session, setSession] = useState<Session | null>(null);
  const [ready, setReady] = useState(false);
  const [mode, setMode] = useState<'signin' | 'signup'>('signin');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState('');

  useEffect(() => {
    let active = true;
    let supabase;
    try {
      supabase = getSupabaseBrowserClient();
    } catch (error) {
      queueMicrotask(() => {
        if (active) {
          setMessage(error instanceof Error ? error.message : 'Supabase is not configured.');
          setReady(true);
        }
      });
      return;
    }
    void supabase.auth.getSession().then(({ data }) => {
      if (active) {
        setSession(data.session);
        setReady(true);
      }
    });
    const { data: listener } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      if (active) {
        setSession(nextSession);
        setReady(true);
      }
    });
    return () => {
      active = false;
      listener.subscription.unsubscribe();
    };
  }, []);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setMessage('');
    try {
      const supabase = getSupabaseBrowserClient();
      if (mode === 'signup') {
        const { data, error } = await supabase.auth.signUp({
          email,
          password,
          options: { data: { full_name: name.trim() || email.split('@')[0] } },
        });
        if (error) throw error;
        setMessage(
          data.session
            ? 'Account created. Your learning space is ready.'
            : 'Check your email to confirm your account, then sign in.',
        );
      } else {
        const { error } = await supabase.auth.signInWithPassword({ email, password });
        if (error) throw error;
      }
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Could not authenticate.');
    } finally {
      setBusy(false);
    }
  }

  if (!ready) {
    return <main className="loading"><div className="loading-brand"><BrandLogo priority /><small>Opening your learning space…</small></div></main>;
  }

  if (session?.user) {
    const displayName = String(session.user.user_metadata.full_name || session.user.email || 'Learner');
    return (
      <DashboardClient
        authenticatedUser={{
          id: session.user.id,
          email: session.user.email || '',
          name: displayName,
        }}
      />
    );
  }

  return (
    <main className="authpage">
      <section className="authintro">
        <div className="authbrand"><BrandLogo priority /></div>
        <p>MADE FOR SENIOR HIGH MATH*</p>
        <h1>Math gets easier when you take it one step at a time.</h1>
        <span>Practice at your own pace, see how you&apos;re improving, and join quizzes with your class.</span>
        <div className="authperks"><b>◆ Adaptive hints</b><b>✓ Verified mastery</b><b>⚡ Live quiz rooms</b></div>
      </section>
      <section className="authcard">
        <p>{mode === 'signin' ? 'WELCOME BACK' : 'CREATE YOUR ACCOUNT'}</p>
        <h2>{mode === 'signin' ? 'Sign in to Math-io' : 'Start learning for free'}</h2>
        <form onSubmit={submit}>
          {mode === 'signup' && <label>Display name<input autoComplete="name" value={name} onChange={(event) => setName(event.target.value)} required /></label>}
          <label>Email<input type="email" autoComplete="email" value={email} onChange={(event) => setEmail(event.target.value)} required /></label>
          <label>Password<input type="password" autoComplete={mode === 'signin' ? 'current-password' : 'new-password'} minLength={8} value={password} onChange={(event) => setPassword(event.target.value)} required /></label>
          <button disabled={busy}>{busy ? 'Please wait…' : mode === 'signin' ? 'Sign in' : 'Create account'}</button>
        </form>
        {message && <div className="authmessage">{message}</div>}
        <button className="authswitch" onClick={() => { setMode(mode === 'signin' ? 'signup' : 'signin'); setMessage(''); }}>
          {mode === 'signin' ? 'New here? Create an account' : 'Already have an account? Sign in'}
        </button>
      </section>
    </main>
  );
}

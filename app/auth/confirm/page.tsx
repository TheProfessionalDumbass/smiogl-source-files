'use client';

import { useEffect, useState } from 'react';
import { BrandLogo } from '../../brand-logo';
import { getSupabaseBrowserClient } from '@/lib/supabase-client';

const REDIRECT_DELAY_SECONDS = 5;

type ConfirmationState = 'confirming' | 'success' | 'error';

export default function ConfirmEmailPage() {
  const [confirmationState, setConfirmationState] = useState<ConfirmationState>('confirming');
  const [countdown, setCountdown] = useState(REDIRECT_DELAY_SECONDS);
  const [errorMessage, setErrorMessage] = useState('');

  useEffect(() => {
    let active = true;
    let confirmationTimeout: ReturnType<typeof setTimeout> | undefined;
    const markSuccess = () => {
      if (!active) return;
      if (confirmationTimeout) clearTimeout(confirmationTimeout);
      setConfirmationState('success');
    };

    const finishConfirmation = async () => {
      const url = new URL(window.location.href);
      const hashParameters = new URLSearchParams(url.hash.slice(1));
      const authError =
        url.searchParams.get('error_description') ||
        hashParameters.get('error_description') ||
        url.searchParams.get('error') ||
        hashParameters.get('error');

      if (authError) {
        setErrorMessage(authError.replaceAll('+', ' '));
        setConfirmationState('error');
        return;
      }

      try {
        const supabase = getSupabaseBrowserClient();
        const { data: listener } = supabase.auth.onAuthStateChange((_event, session) => {
          if (session?.user) markSuccess();
        });

        const { data, error } = await supabase.auth.getSession();
        if (!active) {
          listener.subscription.unsubscribe();
          return;
        }
        if (error) throw error;
        if (data.session?.user) {
          markSuccess();
        } else {
          confirmationTimeout = setTimeout(() => {
            if (active) {
              setErrorMessage('This confirmation link is invalid or has expired. Please sign up again.');
              setConfirmationState('error');
            }
          }, 8000);
        }

        return () => listener.subscription.unsubscribe();
      } catch (error) {
        if (active) {
          setErrorMessage(error instanceof Error ? error.message : 'We could not confirm your email.');
          setConfirmationState('error');
        }
      }
    };

    let unsubscribe: (() => void) | undefined;
    void finishConfirmation().then((cleanup) => {
      if (typeof cleanup === 'function') unsubscribe = cleanup;
    });

    return () => {
      active = false;
      if (confirmationTimeout) clearTimeout(confirmationTimeout);
      unsubscribe?.();
    };
  }, []);

  useEffect(() => {
    if (confirmationState !== 'success') return;

    const interval = window.setInterval(() => {
      setCountdown((current) => Math.max(0, current - 1));
    }, 1000);
    const redirect = window.setTimeout(() => {
      window.location.replace('/');
    }, REDIRECT_DELAY_SECONDS * 1000);

    return () => {
      window.clearInterval(interval);
      window.clearTimeout(redirect);
    };
  }, [confirmationState]);

  return (
    <main className="confirmation-page">
      <div className="confirmation-glow confirmation-glow-one" />
      <div className="confirmation-glow confirmation-glow-two" />
      <section className="confirmation-card" aria-live="polite">
        <BrandLogo className="confirmation-logo" priority />

        {confirmationState === 'confirming' && (
          <>
            <div className="confirmation-spinner" aria-hidden="true" />
            <p className="confirmation-eyebrow">ONE LAST STEP</p>
            <h1>Confirming your email…</h1>
            <p className="confirmation-copy">We&apos;re getting your learning space ready.</p>
          </>
        )}

        {confirmationState === 'success' && (
          <>
            <div className="confirmation-check" aria-hidden="true">
              <svg viewBox="0 0 48 48">
                <path d="m14 25 7 7 14-16" />
              </svg>
            </div>
            <p className="confirmation-eyebrow">ACCOUNT CONFIRMED</p>
            <h1>You&apos;re now signed up!</h1>
            <p className="confirmation-copy">
              Redirecting you to the site in <strong>{countdown}</strong>.
            </p>
            <button type="button" onClick={() => window.location.replace('/')}>
              Go to the site now
            </button>
          </>
        )}

        {confirmationState === 'error' && (
          <>
            <div className="confirmation-error-mark" aria-hidden="true">!</div>
            <p className="confirmation-eyebrow">LINK PROBLEM</p>
            <h1>We couldn&apos;t confirm that email.</h1>
            <p className="confirmation-copy">{errorMessage}</p>
            <button type="button" onClick={() => window.location.replace('/')}>
              Return to sign in
            </button>
          </>
        )}
      </section>
      <p className="confirmation-footer">Learn. Play. Master.</p>
    </main>
  );
}

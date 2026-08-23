'use client';

import { useEffect, useRef } from 'react';
import type { MouseEvent } from 'react';

type Theme = 'light' | 'dark';
type ViewTransitionDocument = Document & {
  startViewTransition?: (update: () => void) => { finished: Promise<void> };
};

const STORAGE_KEY = 'mathio-theme';

function setDocumentTheme(theme: Theme) {
  document.documentElement.dataset.theme = theme;
  document.documentElement.style.colorScheme = theme;
}

export function ThemeToggle({ className = '' }: { className?: string }) {
  const buttonRef = useRef<HTMLButtonElement>(null);

  function syncButton(theme: Theme) {
    buttonRef.current?.setAttribute('aria-pressed', String(theme === 'dark'));
  }

  useEffect(() => {
    const root = document.documentElement;
    const saved = localStorage.getItem(STORAGE_KEY);
    const current: Theme = root.dataset.theme === 'dark' ? 'dark' : 'light';
    syncButton(current);
    root.classList.add('theme-ready');

    if (saved) return;

    const preference = window.matchMedia('(prefers-color-scheme: dark)');
    const followSystem = (event: MediaQueryListEvent) => {
      const nextTheme: Theme = event.matches ? 'dark' : 'light';
      setDocumentTheme(nextTheme);
      syncButton(nextTheme);
    };
    preference.addEventListener('change', followSystem);
    return () => preference.removeEventListener('change', followSystem);
  }, []);

  function toggleTheme(event: MouseEvent<HTMLButtonElement>) {
    const nextTheme: Theme = document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark';
    const root = document.documentElement;
    const rect = event.currentTarget.getBoundingClientRect();
    const x = rect.left + rect.width / 2;
    const y = rect.top + rect.height / 2;
    // Overscan keeps rounded display corners and browser chrome from exposing
    // the outgoing snapshot during the final frame of the reveal.
    const radius = Math.hypot(Math.max(x, innerWidth - x), Math.max(y, innerHeight - y)) + 160;

    root.style.setProperty('--theme-x', `${x}px`);
    root.style.setProperty('--theme-y', `${y}px`);
    root.style.setProperty('--theme-radius', `${radius}px`);

    const apply = () => {
      setDocumentTheme(nextTheme);
      localStorage.setItem(STORAGE_KEY, nextTheme);
      syncButton(nextTheme);
    };

    const transitionDocument = document as ViewTransitionDocument;
    if (!window.matchMedia('(prefers-reduced-motion: reduce)').matches && transitionDocument.startViewTransition) {
      transitionDocument.startViewTransition(apply);
    } else {
      root.classList.add('theme-changing');
      apply();
      window.setTimeout(() => root.classList.remove('theme-changing'), 760);
    }
  }

  return (
    <button
      ref={buttonRef}
      type="button"
      className={`theme-toggle ${className}`.trim()}
      onClick={toggleTheme}
      aria-label="Toggle light and dark mode"
      aria-pressed="false"
      title="Toggle light and dark mode"
    >
      <svg className="theme-flat-icon" viewBox="0 0 64 64" aria-hidden="true">
        <circle className="theme-icon-backdrop" cx="32" cy="32" r="30" />
        <g className="theme-sun-rays">
          <path d="M26 7v7M26 50v7M1 32h7M44 32h7M8.3 14.3l6 4M8.3 49.7l6-4M43.7 14.3l-6 4M43.7 49.7l-6-4" />
        </g>
        <circle className="theme-sun-ring" cx="26" cy="32" r="13" />
        <circle className="theme-moon-left" cx="39" cy="32" r="15" />
        <path className="theme-moon-right" d="M39 17a15 15 0 0 1 0 30Z" />
      </svg>
    </button>
  );
}

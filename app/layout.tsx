import type { Metadata } from 'next';
import { Geist, Geist_Mono } from 'next/font/google';
import './globals.css';
import './features.css';
import './forms.css';
import './clay.css';
import './auth.css';
import './responsive.css';
import { ServiceWorkerRegister } from './service-worker-register';

const geistSans = Geist({
  variable: '--font-geist-sans',
  subsets: ['latin'],
});

const geistMono = Geist_Mono({
  variable: '--font-geist-mono',
  subsets: ['latin'],
});

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000'),
  title: 'S.M.I.O.G.L. | Super Math-io',
  description:
    'A game-based mathematics learning platform for Grade 11 STEM students and their teachers.',
  openGraph: {
    title: 'S.M.I.O.G.L. | Super Math-io',
    description:
      'Learn, play, and master Grade 11 mathematics through guided lessons, verification challenges, and live quiz rooms.',
    images: [{ url: '/og.png', width: 1672, height: 941, alt: 'Math-io — Learn. Play. Master.' }],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'S.M.I.O.G.L. | Super Math-io',
    description:
      'Learn, play, and master Grade 11 mathematics through guided lessons, verification challenges, and live quiz rooms.',
    images: ['/og.png'],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        <ServiceWorkerRegister />
        {children}
      </body>
    </html>
  );
}

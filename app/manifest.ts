import type { MetadataRoute } from 'next';

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'S.M.I.O.G.L. — Super Math-io',
    short_name: 'Math-io',
    description: 'Game-based mathematics learning for Grade 11 STEM.',
    start_url: '/',
    display: 'standalone',
    background_color: '#f8f8fb',
    theme_color: '#6f55d9',
    icons: [{ src: '/favicon.svg', sizes: 'any', type: 'image/svg+xml' }],
  };
}

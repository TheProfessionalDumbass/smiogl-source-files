import Image from 'next/image';

export function BrandLogo({ className = '', priority = false }: { className?: string; priority?: boolean }) {
  return (
    <Image
      src="/mathio-logo.png"
      alt="Math-io"
      width={960}
      height={430}
      priority={priority}
      className={`mathio-logo ${className}`.trim()}
    />
  );
}

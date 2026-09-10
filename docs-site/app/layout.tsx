import { createSiteMetadata } from '@conceptadev/docs-theme';
import type { ReactNode } from 'react';
import { Provider } from '@/components/provider';
import { docsConfig } from '@/docs.config';
import './global.css';

export const metadata = createSiteMetadata(docsConfig);

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className="flex min-h-screen flex-col">
        <Provider>{children}</Provider>
      </body>
    </html>
  );
}

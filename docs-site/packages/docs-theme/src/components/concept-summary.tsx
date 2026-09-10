import type { ComponentProps, ReactNode } from 'react';

export interface ConceptSummaryProps
  extends Omit<ComponentProps<'section'>, 'title'> {
  title?: ReactNode;
}

export function ConceptSummary({
  title = 'Concept summary',
  children,
  className,
  ...props
}: ConceptSummaryProps) {
  return (
    <section
      {...props}
      className={[
        'not-prose my-6 rounded-xl border border-fd-border bg-fd-card p-5',
        className,
      ]
        .filter(Boolean)
        .join(' ')}
    >
      <h2 className="mb-2 text-sm font-semibold uppercase tracking-wide text-fd-muted-foreground">
        {title}
      </h2>
      <div className="text-sm leading-6 text-fd-foreground">{children}</div>
    </section>
  );
}

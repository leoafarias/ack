import type { ComponentProps } from 'react';
import type { PageStatus } from '../types';

export interface StatusProps extends Omit<ComponentProps<'span'>, 'children'> {
  status: PageStatus;
  label?: string;
}

export function Status({
  status,
  label = status,
  className,
  ...props
}: StatusProps) {
  return (
    <span
      {...props}
      data-status={status}
      className={['concepta-status', className].filter(Boolean).join(' ')}
    >
      {label}
    </span>
  );
}

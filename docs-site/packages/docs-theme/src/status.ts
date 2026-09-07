export const PAGE_STATUSES = ['beta', 'deprecated', 'draft', 'experimental', 'stable'] as const;
export type PageStatus = (typeof PAGE_STATUSES)[number];

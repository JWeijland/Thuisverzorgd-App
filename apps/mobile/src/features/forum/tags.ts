import type { ForumTag } from '@/features/forum/api';

/** Filterchips van het forum, in vaste volgorde. */
export const TAGS: { key: ForumTag; labelKey: string }[] = [
  { key: 'wonen', labelKey: 'steun.tagWonen' },
  { key: 'werk', labelKey: 'steun.tagWerk' },
  { key: 'financien', labelKey: 'steun.tagFinancien' },
  { key: 'dementie', labelKey: 'steun.tagDementie' },
];

export const TAG_LABEL: Record<ForumTag, string> = {
  wonen: 'steun.tagWonen',
  werk: 'steun.tagWerk',
  financien: 'steun.tagFinancien',
  dementie: 'steun.tagDementie',
  overig: 'steun.tagOverig',
};

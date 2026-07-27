import nl from '@/i18n/nl.json';

/**
 * Alle UI-copy komt uit nl.json (geen hardcoded strings in schermen).
 * t('checkMail.uitleg', { email: 'x@y.nl' }) — {var} wordt ingevuld.
 * Structuur is voorbereid op een tweede taal (Engels) later.
 */

type Dict = { [key: string]: string | Dict };

const dictionaries: Record<string, Dict> = { nl };
const language = 'nl';

export function t(path: string, vars?: Record<string, string | number>): string {
  const parts = path.split('.');
  let node: string | Dict | undefined = dictionaries[language];
  for (const part of parts) {
    if (node === undefined || typeof node === 'string') {
      node = undefined;
      break;
    }
    node = node[part];
  }
  if (typeof node !== 'string') {
    if (__DEV__) {
      console.warn(`i18n: ontbrekende sleutel "${path}"`);
    }
    return path;
  }
  if (!vars) return node;
  return node.replace(/\{(\w+)\}/g, (match, name: string) =>
    name in vars ? String(vars[name]) : match,
  );
}

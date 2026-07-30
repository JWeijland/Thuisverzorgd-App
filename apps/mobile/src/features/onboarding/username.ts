/**
 * Registreren en inloggen met alleen een gebruikersnaam.
 *
 * Supabase Auth werkt met e-mailadressen, dus achter de schermen krijgt zo'n
 * account het adres <gebruikersnaam>@tvz.invalid. Dat domein is door RFC 2606
 * gereserveerd en bestaat nooit echt, dus er kan geen mail naartoe. Omdat het
 * adres rechtstreeks uit de gebruikersnaam volgt, is er geen opzoekactie nodig
 * bij het inloggen.
 */

export const INTERN_DOMEIN = 'tvz.invalid';

/** Alleen letters, cijfers, punt, liggend streepje en onderstrepingsteken. */
const GELDIG = /^[a-z0-9][a-z0-9._-]{2,23}$/;

export function normaliseerGebruikersnaam(input: string): string {
  return input.trim().toLowerCase();
}

export function gebruikersnaamFout(input: string): 'kort' | 'tekens' | null {
  const naam = normaliseerGebruikersnaam(input);
  if (naam.length < 3) return 'kort';
  if (!GELDIG.test(naam)) return 'tekens';
  return null;
}

/** Het interne adres dat bij een gebruikersnaam hoort. */
export function internEmail(gebruikersnaam: string): string {
  return `${normaliseerGebruikersnaam(gebruikersnaam)}@${INTERN_DOMEIN}`;
}

/**
 * Inlognaam → adres voor Supabase. Een echte e-mail blijft ongewijzigd; iets
 * zonder @ wordt als gebruikersnaam behandeld.
 */
export function inlogEmail(input: string): string {
  const waarde = input.trim();
  return waarde.includes('@') ? waarde.toLowerCase() : internEmail(waarde);
}

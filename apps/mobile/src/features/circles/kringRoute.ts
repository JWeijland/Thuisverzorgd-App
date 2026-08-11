/**
 * De kringpagina hoort bij het hulp-pad, maar de buddy heeft dat pad niet.
 * Die krijgt dezelfde inhoud onder zijn eigen kop (/vrijwilliger/kring), met
 * de schuifjes uit. Eén plek die dat bepaalt, zodat elke knop hetzelfde doet.
 */
export function kringRoute(role: string | null | undefined, tab?: 'berichten'): string {
  const basis = role === 'vrijwilliger' ? '/vrijwilliger/kring' : '/regelen/kring';
  return tab ? `${basis}?tab=${tab}` : basis;
}

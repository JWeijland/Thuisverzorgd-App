/**
 * Pure hulpjes voor het zoeken in de Wegwijzer. Alles wat hier staat is
 * testbaar zonder database: normaliseren van wat iemand intypt, en het
 * uitpakken van de treffer die de server terugstuurt.
 */

/** Kleine letters, zonder accenten en zonder dubbele spaties. */
export function normaliseer(term: string): string {
  return term
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();
}

/** Vanaf twee tekens gaan we pas zoeken; daaronder is alles een treffer. */
export function magZoeken(term: string): boolean {
  return normaliseer(term).length >= 2;
}

export type TrefferDeel = { text: string; raak: boolean };

/**
 * De server markeert het gevonden woord met « en ». Dat knippen we hier uit
 * elkaar, zodat het scherm alleen dat woord dik kan zetten.
 */
export function splitsTreffer(treffer: string | null | undefined): TrefferDeel[] {
  if (!treffer) return [];
  const delen: TrefferDeel[] = [];
  const regex = /«([^»]*)»/g;
  let laatste = 0;
  let match = regex.exec(treffer);
  while (match) {
    if (match.index > laatste) {
      delen.push({ text: treffer.slice(laatste, match.index), raak: false });
    }
    if (match[1]) delen.push({ text: match[1], raak: true });
    laatste = match.index + match[0].length;
    match = regex.exec(treffer);
  }
  if (laatste < treffer.length) {
    delen.push({ text: treffer.slice(laatste), raak: false });
  }
  return delen;
}

/**
 * Zoeken zonder verbinding, of terwijl het serverantwoord onderweg is:
 * filtert de al ingeladen onderwerpen op titel, samenvatting en synoniemen.
 */
export function filterLokaal<
  T extends { titel: string; samenvatting: string; zoektermen: string[] },
>(modules: T[], term: string): T[] {
  const naald = normaliseer(term);
  if (naald.length < 2) return [];
  const woorden = naald.split(' ');
  return modules.filter((module) => {
    const hooiberg = normaliseer(
      [module.titel, module.samenvatting, module.zoektermen.join(' ')].join(' '),
    );
    return woorden.every((woord) => hooiberg.includes(woord));
  });
}

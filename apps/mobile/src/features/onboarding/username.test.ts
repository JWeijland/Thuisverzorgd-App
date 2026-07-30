import { gebruikersnaamFout, inlogEmail, internEmail } from '@/features/onboarding/username';

describe('gebruikersnaam', () => {
  it('keurt te korte namen af', () => {
    expect(gebruikersnaamFout('jo')).toBe('kort');
  });

  it('keurt spaties en rare tekens af', () => {
    expect(gebruikersnaamFout('jelle weijland')).toBe('tekens');
    expect(gebruikersnaamFout('jelle@thuis')).toBe('tekens');
  });

  it('keurt gewone namen goed', () => {
    expect(gebruikersnaamFout('jelle')).toBeNull();
    expect(gebruikersnaamFout('Jelle_W.2')).toBeNull();
  });

  it('maakt het interne adres uit de gebruikersnaam', () => {
    expect(internEmail(' Jelle ')).toBe('jelle@tvz.invalid');
  });

  it('laat een echt e-mailadres staan en zet een naam om', () => {
    expect(inlogEmail('Naam@Voorbeeld.nl')).toBe('naam@voorbeeld.nl');
    expect(inlogEmail('jelle')).toBe('jelle@tvz.invalid');
  });
});

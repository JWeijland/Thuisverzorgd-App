import { Marktplaats } from '@/features/voorzieningen/Marktplaats';
import { useStatusBalk } from '@/lib/statusbalk';

/** Hulp aan huis als losse pagina (hulpvrager): dezelfde marktplaats, met terugweg. */
export default function DienstenScreen() {
  useStatusBalk('donker');
  return <Marktplaats terug />;
}

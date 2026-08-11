import { BuurtScherm } from '@/features/map/BuurtScherm';

/**
 * De volledige buurtkaart voor beheerder en hulpvrager. Die is niet meer
 * prominent (handoff §3b): je komt hier via de buurt-scan van de buddy-flow
 * of via het knopje "Laat Bo een buddy in de buurt zoeken" op de kringpagina.
 */
export default function BuurtKaart() {
  return <BuurtScherm />;
}

import { Image } from 'expo-image';

import { useAvatarUrl } from '@/features/avatars/api';
import { Avatar } from '@/ui';

/**
 * Profielfoto per aanbieder, meegeleverd met de app (Pexels, zie
 * assets/images/aanbieders/BRONNEN.md). De sleutel is de slug van de dienst.
 */
const AANBIEDER_FOTOS: Record<string, number> = {
  kapper: require('../../../assets/images/aanbieders/kapper.jpg'),
  boodschappen: require('../../../assets/images/aanbieders/boodschappen.jpg'),
  maaltijden: require('../../../assets/images/aanbieders/maaltijden.jpg'),
  schoonmaak: require('../../../assets/images/aanbieders/schoonmaak.jpg'),
  tuinman: require('../../../assets/images/aanbieders/tuinman.jpg'),
  'massage-fysio': require('../../../assets/images/aanbieders/massage-fysio.jpg'),
  vervoer: require('../../../assets/images/aanbieders/vervoer.jpg'),
  'hond-uitlaten': require('../../../assets/images/aanbieders/hond-uitlaten.jpg'),
  klusjesman: require('../../../assets/images/aanbieders/klusjesman.jpg'),
};

type Props = {
  /** Slug van de dienst; bepaalt welke meegeleverde foto erbij hoort. */
  slug: string;
  naam: string;
  /** Eigen upload van de aanbieder; die gaat altijd voor. */
  avatarPad?: string | null;
  size?: number;
};

/**
 * De aanbieder als mens in beeld. Een rondje met een letter erin voelt niet
 * als iemand die bij je thuis komt (feedback Jelle 11-08), dus we tonen een
 * echte foto. Volgorde: eigen upload, dan de meegeleverde foto, dan pas de
 * initiaal als vangnet.
 */
export function AanbiederAvatar({ slug, naam, avatarPad, size = 96 }: Props) {
  const eigenFoto = useAvatarUrl(avatarPad ?? null);
  const meegeleverd = AANBIEDER_FOTOS[slug];
  const rond = { width: size, height: size, borderRadius: size / 2 };

  if (eigenFoto.data) {
    return <Image source={{ uri: eigenFoto.data }} style={rond} accessibilityLabel={naam} />;
  }
  if (meegeleverd) {
    return <Image source={meegeleverd} style={rond} accessibilityLabel={naam} />;
  }
  return <Avatar name={naam} size={size} />;
}

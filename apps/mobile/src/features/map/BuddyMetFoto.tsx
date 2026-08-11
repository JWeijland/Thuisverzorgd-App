import { useAvatarUrl } from '@/features/avatars/api';
import type { MapBuddy } from '@/features/map/api';
import { BuddyMarker } from '@/features/map/TvzMap';

/**
 * Buddy op de kaart met zijn eigen foto. De foto's staan in een privé-bucket,
 * dus de URL wordt per buddy opgehaald; daarom is dit een eigen component en
 * geen losse functie.
 */
export function BuddyMetFoto({ buddy, onPress }: { buddy: MapBuddy; onPress?: () => void }) {
  const url = useAvatarUrl(buddy.avatar_path);
  return (
    <BuddyMarker
      lat={buddy.lat}
      lon={buddy.lon}
      voornaam={buddy.voornaam}
      onPress={onPress}
      uri={url.data ?? undefined}
    />
  );
}

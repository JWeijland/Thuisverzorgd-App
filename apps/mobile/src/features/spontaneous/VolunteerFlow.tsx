import { useState } from 'react';
import { Linking, Modal, StyleSheet, View } from 'react-native';
import { Zap } from 'lucide-react-native';

import { useProfile } from '@/features/onboarding/useAuth';
import {
  useAcceptedRequest,
  useMyOffer,
  useOpenRequests,
  useRequestAddress,
  useRequestContact,
  useSpontaneousActions,
  type OpenRequest,
} from '@/features/spontaneous/api';
import { REQUEST_TYPE_LABEL } from '@/features/spontaneous/RequesterFlow';
import { formatDistance, haversineKm, type LatLng } from '@/lib/geo';
import { t } from '@/i18n';
import { colors, radius, shadows, spacing } from '@/theme';
import { Button, EmptyState, PulseDot, TextField, TvzText } from '@/ui';

type Props = {
  selected: OpenRequest | null;
  onCloseSelected: () => void;
  ownLocation: LatLng | null;
};

/**
 * Directe hulp, kant van de vrijwilliger (screen 21):
 * aanvraag → berichtje → "Ik kan helpen" → wachten → adres zichtbaar → afronden;
 * plus het fullscreen "hulpvraag ingetrokken"-scherm.
 */
export function VolunteerFlow({ selected, onCloseSelected, ownLocation }: Props) {
  const profile = useProfile();
  const openRequests = useOpenRequests();
  const myOffer = useMyOffer();
  const actions = useSpontaneousActions();
  const [message, setMessage] = useState('');
  const [dismissedGone, setDismissedGone] = useState<string | null>(null);

  const offer = myOffer.data;
  const accepted = useAcceptedRequest(offer?.request_id, offer?.status === 'geaccepteerd');
  const contact = useRequestContact(offer?.request_id, offer?.status === 'geaccepteerd');
  const address = useRequestAddress(offer?.request_id, offer?.status === 'geaccepteerd');

  // Ingetrokken? Mijn openstaand aanbod, maar de aanvraag is weg of geannuleerd.
  const requestGone =
    offer &&
    offer.request_id !== dismissedGone &&
    ((offer.status === 'aangeboden' &&
      !openRequests.isLoading &&
      !(openRequests.data ?? []).some((request) => request.id === offer.request_id)) ||
      (offer.status === 'geaccepteerd' && accepted.data?.status === 'geannuleerd'));

  if (requestGone) {
    return (
      <Modal visible animationType="fade">
        <View style={styles.goneScreen}>
          <EmptyState
            title={t('directeHulp.ingetrokkenTitel')}
            body={t('directeHulp.ingetrokkenTekst', { naam: 'De aanvrager' })}
          />
          {accepted.data?.cancelled_message ? (
            <TvzText preset="secondary" style={styles.goneMessage}>
              {t('directeHulp.ingetrokkenBericht', {
                naam: 'de aanvrager',
                bericht: accepted.data.cancelled_message,
              })}
            </TvzText>
          ) : null}
          <Button
            label={t('directeHulp.terugNaarKaart')}
            variant="cta"
            size="lg"
            onPress={() => setDismissedGone(offer!.request_id)}
            style={styles.goneButton}
          />
        </View>
      </Modal>
    );
  }

  // Geaccepteerd aanbod: adres + bellen + afronden.
  if (offer?.status === 'geaccepteerd' && accepted.data?.status === 'onderweg') {
    const naam = contact.data?.naam.split(' ')[0] ?? 'de aanvrager';
    return (
      <View style={[styles.card, shadows.floating]}>
        <View style={styles.titleRow}>
          <View style={styles.zapBadge}>
            <Zap color={colors.primaryDark} size={16} strokeWidth={2.2} fill={colors.accent} />
          </View>
          <TvzText preset="cardTitle" style={styles.flexTitle}>
            {t('directeHulp.akkoordTitel')}
          </TvzText>
          <PulseDot size={8} />
        </View>
        {address.data ? (
          <TvzText preset="body" style={styles.address}>
            {t('directeHulp.akkoordAdres', { adres: address.data })}
          </TvzText>
        ) : null}
        {contact.data?.telefoon ? (
          <Button
            label={t('directeHulp.belAanvrager', { naam })}
            variant="primary"
            onPress={() => Linking.openURL(`tel:${contact.data!.telefoon}`)}
            style={styles.action}
          />
        ) : null}
        <Button
          label={t('directeHulp.afronden')}
          variant="cta"
          onPress={() => actions.completeRequest.mutate(offer.request_id)}
          style={styles.action}
        />
        <Button
          label={t('directeHulp.annuleren')}
          variant="danger"
          onPress={() => actions.cancelRequest.mutate({ requestId: offer.request_id })}
          style={styles.action}
        />
      </View>
    );
  }

  // Aanbod verstuurd, wachten op akkoord.
  if (offer?.status === 'aangeboden') {
    return (
      <View style={[styles.card, shadows.floating]}>
        <View style={styles.titleRow}>
          <PulseDot size={8} />
          <TvzText preset="cardTitle" style={styles.flexTitle}>
            {t('directeHulp.verstuurdTitel')}
          </TvzText>
        </View>
        <TvzText preset="secondary" style={styles.uitleg}>
          {t('directeHulp.verstuurdTekst', { naam: 'de aanvrager' })}
        </TvzText>
      </View>
    );
  }

  // Aanvraag op de kaart aangetikt.
  if (selected) {
    const distance =
      ownLocation && selected.lat != null && selected.lon != null
        ? formatDistance(haversineKm(ownLocation, { lat: selected.lat, lon: selected.lon }))
        : null;
    const verified = profile.data?.id_verified ?? false;
    return (
      <View style={[styles.card, shadows.floating]}>
        <View style={styles.titleRow}>
          <View style={styles.zapBadge}>
            <Zap color={colors.primaryDark} size={16} strokeWidth={2.2} fill={colors.accent} />
          </View>
          <View style={styles.flexTitle}>
            <TvzText preset="cardTitle">{t('directeHulp.gevraagdTitel')}</TvzText>
            {distance ? (
              <TvzText preset="secondary">
                {t('directeHulp.gevraagdMeta', { afstand: distance })}
              </TvzText>
            ) : null}
          </View>
          <TvzText preset="cardTitle" onPress={onCloseSelected} accessibilityRole="button">
            ✕
          </TvzText>
        </View>
        <TvzText preset="body" style={styles.requestType}>
          <TvzText preset="body" style={styles.greenDot}>
            ●{' '}
          </TvzText>
          {t('directeHulp.gevraagdDoor', {
            type: t(REQUEST_TYPE_LABEL[selected.type]),
            naam: selected.voornaam,
          })}
        </TvzText>
        {selected.note ? (
          <TvzText preset="secondary" style={styles.requestNote}>
            “{selected.note}”
          </TvzText>
        ) : null}
        {verified ? (
          <>
            <TextField
              label={t('directeHulp.gevraagdTitel')}
              placeholder={t('directeHulp.berichtPlaceholder')}
              value={message}
              onChangeText={setMessage}
            />
            <Button
              label={t('directeHulp.ikKanHelpen')}
              variant="cta"
              size="lg"
              disabled={actions.offerHelp.isPending}
              onPress={() =>
                actions.offerHelp.mutate(
                  { requestId: selected.id, message: message.trim() },
                  { onSuccess: onCloseSelected },
                )
              }
            />
            <TvzText preset="secondary" style={styles.note}>
              {t('directeHulp.adresNa')}
            </TvzText>
          </>
        ) : (
          <TvzText preset="secondary" style={styles.note}>
            {t('directeHulp.idNodig')}
          </TvzText>
        )}
      </View>
    );
  }

  return null;
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.white,
    borderRadius: radius.card,
    padding: spacing.cardPadding,
    marginHorizontal: spacing.screen,
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  zapBadge: {
    width: 30,
    height: 30,
    borderRadius: 15,
    backgroundColor: colors.successBg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  flexTitle: { flex: 1 },
  uitleg: {
    marginTop: spacing.sm,
  },
  requestType: {
    marginTop: spacing.sm,
    marginBottom: spacing.xs,
  },
  requestNote: {
    fontStyle: 'italic',
    marginBottom: spacing.xs,
  },
  greenDot: {
    color: colors.accent,
  },
  address: {
    marginTop: spacing.sm,
  },
  action: {
    marginTop: spacing.sm,
  },
  note: {
    textAlign: 'center',
    marginTop: spacing.sm,
    fontSize: 12.5,
    color: colors.inkFaint,
  },
  goneScreen: {
    flex: 1,
    backgroundColor: colors.bg,
    justifyContent: 'center',
    padding: spacing.screen,
  },
  goneMessage: {
    textAlign: 'center',
    fontStyle: 'italic',
  },
  goneButton: {
    marginTop: spacing.xl,
  },
});

import { useState } from 'react';
import { Linking, StyleSheet, View } from 'react-native';
import { Zap } from 'lucide-react-native';

import {
  useMyRequest,
  useRequestContact,
  useRequestOffers,
  useSpontaneousActions,
  type RequestType,
} from '@/features/spontaneous/api';
import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import { useMyCircle } from '@/features/circles/api';
import { t } from '@/i18n';
import { colors, radius, shadows, spacing } from '@/theme';
import { BottomSheet, Button, Chip, PulseDot, TextField, TvzText } from '@/ui';

const TYPES: RequestType[] = ['boodschappen', 'vervoer', 'medicijnen', 'gezelschap', 'anders'];

export const REQUEST_TYPE_LABEL: Record<RequestType, string> = {
  boodschappen: 'directeHulp.typeBoodschappen',
  vervoer: 'directeHulp.typeVervoer',
  medicijnen: 'directeHulp.typeMedicijnen',
  gezelschap: 'directeHulp.typeGezelschap',
  anders: 'directeHulp.typeAnders',
};

type Props = {
  ownLocation: { lat: number; lon: number } | null;
};

/**
 * Directe hulp, kant van de aanvrager (screens 08/09):
 * plaatsen → aanbod → toestaan/afwijzen → onderweg → afronden; annuleren met bericht.
 */
export function RequesterFlow({ ownLocation }: Props) {
  const circle = useMyCircle();
  const myRequest = useMyRequest();
  const offers = useRequestOffers(myRequest.data?.id);
  const contact = useRequestContact(myRequest.data?.id, myRequest.data?.status === 'onderweg');
  const actions = useSpontaneousActions();

  const [composeOpen, setComposeOpen] = useState(false);
  const [type, setType] = useState<RequestType>('boodschappen');
  const [customNote, setCustomNote] = useState('');
  const [address, setAddress] = useState('');
  const [cancelOpen, setCancelOpen] = useState(false);
  const [cancelMessage, setCancelMessage] = useState('');

  const request = myRequest.data;

  if (!request) {
    return (
      <>
        {composeOpen ? (
          <View style={[styles.card, shadows.floating]}>
            <View style={styles.titleRow}>
              <View style={styles.zapBadge}>
                <Zap color={colors.primaryDark} size={16} strokeWidth={2.2} fill={colors.accent} />
              </View>
              <TvzText preset="cardTitle" style={styles.title}>
                {t('directeHulp.titel')}
              </TvzText>
              <TvzText
                preset="cardTitle"
                onPress={() => setComposeOpen(false)}
                accessibilityRole="button"
              >
                ✕
              </TvzText>
            </View>
            <TvzText preset="secondary" style={styles.uitleg}>
              {t('directeHulp.uitleg')}
            </TvzText>
            <View style={styles.chips}>
              {TYPES.map((option) => (
                <Chip
                  key={option}
                  label={t(REQUEST_TYPE_LABEL[option])}
                  selected={type === option}
                  onPress={() => setType(option)}
                />
              ))}
            </View>
            {type === 'anders' ? (
              <TextField
                label={t('directeHulp.andersLabel')}
                placeholder={t('directeHulp.andersPlaceholder')}
                value={customNote}
                onChangeText={setCustomNote}
              />
            ) : null}
            <TextField
              label={t('directeHulp.adresLabel')}
              placeholder={t('directeHulp.adresPlaceholder')}
              value={address}
              onChangeText={setAddress}
            />
            <Button
              label={t('directeHulp.zetOpDeKaart')}
              variant="cta"
              size="lg"
              disabled={
                actions.createRequest.isPending ||
                (type === 'anders' && customNote.trim().length === 0)
              }
              onPress={() =>
                actions.createRequest.mutate({
                  type,
                  note: type === 'anders' ? customNote.trim() : undefined,
                  address: address.trim() || undefined,
                  lat: ownLocation?.lat,
                  lon: ownLocation?.lon,
                  circleId: circle.data?.id,
                })
              }
            />
            <TvzText preset="secondary" style={styles.note}>
              {t('directeHulp.adresNote')}
            </TvzText>
          </View>
        ) : (
          <Button
            label={t('directeHulp.titel')}
            variant="cta"
            size="lg"
            onPress={() => setComposeOpen(true)}
            style={styles.cta}
          />
        )}
      </>
    );
  }

  const firstOffer = (offers.data ?? [])[0];

  return (
    <>
      <View style={[styles.card, shadows.floating]}>
        {request.status === 'onderweg' ? (
          <>
            <View style={styles.titleRow}>
              <ProfileAvatar
                name={contact.data?.naam ?? 'B'}
                avatarPath={contact.data?.avatar_path}
                size={40}
              />
              <View style={styles.flexInfo}>
                <TvzText preset="cardTitle">
                  {t('directeHulp.onderwegTitel', {
                    naam: contact.data?.naam.split(' ')[0] ?? 'Je buddy',
                  })}
                </TvzText>
                <TvzText preset="secondary">
                  {t('directeHulp.onderwegTekst', {
                    naam: contact.data?.naam.split(' ')[0] ?? 'je buddy',
                  })}
                </TvzText>
              </View>
              <PulseDot size={8} />
            </View>
            {contact.data?.telefoon ? (
              <Button
                label={t('rooster.belKort', { naam: contact.data.naam.split(' ')[0]! })}
                variant="primary"
                onPress={() => Linking.openURL(`tel:${contact.data!.telefoon}`)}
                style={styles.action}
              />
            ) : null}
            <Button
              label={t('directeHulp.afronden')}
              variant="cta"
              onPress={() => actions.completeRequest.mutate(request.id)}
              style={styles.action}
            />
            <Button
              label={t('directeHulp.annuleren')}
              variant="danger"
              onPress={() => setCancelOpen(true)}
              style={styles.action}
            />
          </>
        ) : firstOffer ? (
          <>
            <View style={styles.titleRow}>
              <ProfileAvatar
                name={firstOffer.voornaam}
                avatarPath={firstOffer.avatar_path}
                size={40}
              />
              <View style={styles.flexInfo}>
                <TvzText preset="cardTitle">
                  {t('directeHulp.aanbodTitel', { naam: firstOffer.voornaam })}
                </TvzText>
                {firstOffer.message ? (
                  <TvzText preset="secondary" style={styles.offerMessage}>
                    “{firstOffer.message}”
                  </TvzText>
                ) : null}
              </View>
            </View>
            <Button
              label={t('directeHulp.toestaan')}
              variant="cta"
              size="lg"
              disabled={actions.acceptOffer.isPending}
              onPress={() => actions.acceptOffer.mutate(firstOffer.id)}
              style={styles.action}
            />
            <Button
              label={t('directeHulp.afwijzen')}
              variant="outline"
              disabled={actions.rejectOffer.isPending}
              onPress={() => actions.rejectOffer.mutate(firstOffer.id)}
              style={styles.action}
            />
          </>
        ) : (
          <>
            <View style={styles.titleRow}>
              <View style={styles.zapBadge}>
                <Zap color={colors.primaryDark} size={16} strokeWidth={2.2} fill={colors.accent} />
              </View>
              <TvzText preset="cardTitle" style={styles.title}>
                {t('directeHulp.openTitel')}
              </TvzText>
              <PulseDot size={8} />
            </View>
            <TvzText preset="secondary" style={styles.uitleg}>
              {t('directeHulp.openTekst')}
            </TvzText>
            <Button
              label={t('directeHulp.annuleren')}
              variant="outline"
              onPress={() => setCancelOpen(true)}
              style={styles.action}
            />
          </>
        )}
      </View>

      <BottomSheet
        visible={cancelOpen}
        onClose={() => setCancelOpen(false)}
        title={t('directeHulp.annulerenTitel')}
      >
        <TvzText preset="secondary">{t('directeHulp.annulerenUitleg')}</TvzText>
        <TextField
          label={t('directeHulp.annulerenTitel')}
          placeholder={t('directeHulp.annulerenPlaceholder')}
          value={cancelMessage}
          onChangeText={setCancelMessage}
        />
        <Button
          label={t('directeHulp.annulerenBevestig')}
          variant="danger"
          size="lg"
          disabled={actions.cancelRequest.isPending}
          onPress={() =>
            actions.cancelRequest.mutate(
              { requestId: request.id, message: cancelMessage.trim() || undefined },
              { onSuccess: () => setCancelOpen(false) },
            )
          }
        />
      </BottomSheet>
    </>
  );
}

const styles = StyleSheet.create({
  cta: {
    marginHorizontal: spacing.screen,
  },
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
  title: { flex: 1 },
  flexInfo: { flex: 1 },
  uitleg: {
    marginTop: spacing.sm,
    marginBottom: spacing.sm,
  },
  chips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.chipGap,
    marginBottom: spacing.md,
  },
  note: {
    textAlign: 'center',
    marginTop: spacing.sm,
    fontSize: 12.5,
    color: colors.inkFaint,
  },
  action: {
    marginTop: spacing.sm,
  },
  offerMessage: {
    fontStyle: 'italic',
  },
});

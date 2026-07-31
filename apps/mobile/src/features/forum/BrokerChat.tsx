import { LinearGradient } from 'expo-linear-gradient';
import { useEffect, useRef, useState } from 'react';
import {
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  TextInput,
  View,
} from 'react-native';
import { Send } from 'lucide-react-native';

import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import {
  useBrokerMessages,
  useBrokerPresenceIds,
  useMakelaars,
  useMyBrokerChat,
  useSendBrokerMessage,
  type Makelaar,
} from '@/features/forum/api';
import { useSession } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { useKeyboardOpen } from '@/lib/keyboard';
import { colors, gradient, radius, shadows, spacing } from '@/theme';
import { Avatar, BottomSheet, Button, Chip, Pill, PulseDot, TvzText } from '@/ui';

const START_QUESTIONS = ['steun.startvraag1', 'steun.startvraag2', 'steun.startvraag3'];

/** Afwisselende scheefstand voor het kaartendeck (net echte kaartjes). */
const DECK_TILT = ['-5deg', '4deg', '-3deg', '5deg', '-4deg', '3deg'];

/**
 * Hulpmakelaar-chat (screen 14): live chat met wachtrij-gevoel en "x online".
 * Rechts hangt een kaartendeck met de makelaars; tik = profiel bekijken en
 * van daaruit een gesprek met die ene makelaar starten.
 */
export function BrokerChat({ startVraag }: { startVraag?: string } = {}) {
  const { session } = useSession();
  const makelaars = useMakelaars();
  const onlineIds = useBrokerPresenceIds();
  const keyboardOpen = useKeyboardOpen();

  // Gekozen makelaar = eigen gesprek met die persoon; zonder keuze de wachtrij.
  const [gekozen, setGekozen] = useState<Makelaar | null>(null);
  const [profiel, setProfiel] = useState<Makelaar | null>(null);
  const chat = useMyBrokerChat(gekozen?.id ?? null);
  const messages = useBrokerMessages(chat.data);
  const send = useSendBrokerMessage(chat.data);
  const [draft, setDraft] = useState('');
  const scrollRef = useRef<ScrollView>(null);

  useEffect(() => {
    scrollRef.current?.scrollToEnd({ animated: true });
  }, [messages.data?.length]);

  // Kom je vanuit de Wegwijzer, dan staat je vraag alvast in het tekstvak.
  // Versturen doe je zelf, zodat je hem eerst kunt aanvullen. Bij een nieuwe
  // vraag zetten we het veld opnieuw; typ je daarna verder, dan blijft dat staan.
  const [vorigeStartVraag, setVorigeStartVraag] = useState(startVraag);
  if (startVraag !== vorigeStartVraag) {
    setVorigeStartVraag(startVraag);
    if (startVraag) setDraft(startVraag);
  }

  function submit(text?: string) {
    const body = (text ?? draft).trim();
    if (!body || !chat.data) return;
    setDraft('');
    send.mutate(body);
  }

  const online = onlineIds.length;
  const onlineText =
    online === 0
      ? t('steun.offline')
      : online === 1
        ? t('steun.online1')
        : t('steun.onlineMeer', { aantal: online });

  return (
    <KeyboardAvoidingView
      style={styles.fill}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      {gekozen ? (
        <View style={styles.statusRow}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={t('steun.deckLabel', { naam: gekozen.voornaam })}
            onPress={() => setProfiel(gekozen)}
          >
            <ProfileAvatar name={gekozen.voornaam} avatarPath={gekozen.avatar_path} size={34} />
          </Pressable>
          <TvzText preset="meta" style={styles.statusText}>
            {t('steun.chatMet', { naam: gekozen.voornaam })}
          </TvzText>
          {onlineIds.includes(gekozen.id) ? <PulseDot size={7} /> : null}
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={t('steun.chatWissel')}
            onPress={() => setGekozen(null)}
            hitSlop={8}
            style={styles.wisselPill}
          >
            <TvzText preset="meta" style={styles.wisselText}>
              {t('steun.chatWissel')}
            </TvzText>
          </Pressable>
        </View>
      ) : (
        <View style={styles.statusRow}>
          <View style={styles.avatars}>
            {(makelaars.data ?? []).length > 0
              ? makelaars.data!.slice(0, 3).map((makelaar, i) => (
                  <View
                    key={makelaar.id}
                    style={[styles.avatarWrap, { marginLeft: i === 0 ? 0 : -10 }]}
                  >
                    <ProfileAvatar
                      name={makelaar.voornaam}
                      avatarPath={makelaar.avatar_path}
                      size={30}
                      backgroundColor={i === 2 ? colors.accent : undefined}
                    />
                  </View>
                ))
              : ['M', 'S', 'J'].map((letter, i) => (
                  <View key={letter} style={[styles.avatarWrap, { marginLeft: i === 0 ? 0 : -10 }]}>
                    <Avatar
                      name={letter}
                      size={30}
                      backgroundColor={i === 2 ? colors.accent : undefined}
                    />
                  </View>
                ))}
          </View>
          <TvzText preset="meta" style={styles.statusText}>
            {onlineText}
          </TvzText>
          {online > 0 ? <PulseDot size={7} /> : null}
        </View>
      )}

      <View style={styles.fill}>
        <ScrollView ref={scrollRef} contentContainerStyle={styles.list}>
          <View style={styles.noticeCard}>
            <TvzText preset="secondary" style={styles.notice}>
              {t('steun.vertrouwelijk')}
            </TvzText>
          </View>
          {(messages.data ?? []).map((message) => {
            const own = message.sender_id === session?.user.id;
            return (
              <View key={message.id} style={[styles.bubble, own ? styles.own : styles.other]}>
                <TvzText preset="body" style={styles.bubbleText}>
                  {message.body}
                </TvzText>
              </View>
            );
          })}
        </ScrollView>

        {/* Kaartendeck met de makelaars, rechts aan de zijkant. */}
        <View pointerEvents="box-none" style={styles.deck}>
          {(makelaars.data ?? []).map((makelaar, i) => (
            <Pressable
              key={makelaar.id}
              accessibilityRole="button"
              accessibilityLabel={t('steun.deckLabel', { naam: makelaar.voornaam })}
              onPress={() => setProfiel(makelaar)}
              style={[
                styles.deckCard,
                shadows.card,
                {
                  marginTop: i === 0 ? 0 : -18,
                  transform: [{ rotate: DECK_TILT[i % DECK_TILT.length]! }],
                },
                gekozen?.id === makelaar.id && styles.deckCardActive,
              ]}
            >
              <ProfileAvatar name={makelaar.voornaam} avatarPath={makelaar.avatar_path} size={46} />
              {onlineIds.includes(makelaar.id) ? <View style={styles.deckOnlineDot} /> : null}
            </Pressable>
          ))}
        </View>
      </View>

      {(messages.data ?? []).length === 0 ? (
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.startRow}
        >
          {START_QUESTIONS.map((key) => (
            <Chip key={key} label={t(key)} onPress={() => submit(t(key))} />
          ))}
        </ScrollView>
      ) : null}

      <View style={[styles.inputRow, keyboardOpen && styles.inputRowKeyboard]}>
        <TextInput
          textContentType="none"
          autoComplete="off"
          value={draft}
          onChangeText={setDraft}
          placeholder={
            gekozen
              ? t('steun.chatPlaceholderAan', { naam: gekozen.voornaam })
              : t('steun.chatPlaceholder')
          }
          placeholderTextColor={colors.inkFaint}
          style={styles.input}
          onSubmitEditing={() => submit()}
          returnKeyType="send"
        />
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('steun.chatPlaceholder')}
          onPress={() => submit()}
          style={styles.sendButton}
        >
          <Send color={colors.white} size={18} strokeWidth={2.2} />
        </Pressable>
      </View>

      <MakelaarProfiel
        makelaar={profiel}
        online={!!profiel && onlineIds.includes(profiel.id)}
        onClose={() => setProfiel(null)}
        onStart={(makelaar) => {
          setGekozen(makelaar);
          setProfiel(null);
        }}
      />
    </KeyboardAvoidingView>
  );
}

/** Profiel-sheet van één makelaar: banner, bio, onderwerpen en de vraag-knop. */
function MakelaarProfiel({
  makelaar,
  online,
  onClose,
  onStart,
}: {
  makelaar: Makelaar | null;
  online: boolean;
  onClose: () => void;
  onStart: (makelaar: Makelaar) => void;
}) {
  return (
    <BottomSheet visible={!!makelaar} onClose={onClose}>
      {makelaar ? (
        <>
          <LinearGradient {...gradient} style={styles.profielBanner}>
            <View style={styles.profielAvatarRing}>
              <ProfileAvatar name={makelaar.voornaam} avatarPath={makelaar.avatar_path} size={84} />
            </View>
            <TvzText preset="screenTitle" style={styles.profielNaam}>
              {makelaar.voornaam}
            </TvzText>
            <View style={styles.profielMetaRow}>
              <Pill
                label={t('steun.makelaarBadge')}
                color={colors.primary}
                backgroundColor={colors.white}
              />
              {makelaar.city ? (
                <TvzText preset="meta" style={styles.profielStad}>
                  {t('steun.profielStad', { stad: makelaar.city })}
                </TvzText>
              ) : null}
            </View>
            <View style={styles.profielOnlineRow}>
              {online ? <PulseDot size={7} /> : null}
              <TvzText preset="meta" style={styles.profielOnlineText}>
                {online ? t('steun.profielOnline') : t('steun.profielOffline')}
              </TvzText>
            </View>
          </LinearGradient>

          <TvzText preset="body" style={styles.profielBio}>
            {makelaar.bio ?? t('steun.bioFallback', { naam: makelaar.voornaam })}
          </TvzText>

          {makelaar.onderwerpen.length > 0 ? (
            <>
              <TvzText preset="meta" style={styles.profielKop}>
                {t('steun.profielKanHelpen')}
              </TvzText>
              <View style={styles.profielChips}>
                {makelaar.onderwerpen.map((onderwerp) => (
                  <Pill key={onderwerp} label={onderwerp} />
                ))}
              </View>
            </>
          ) : null}

          <Button
            label={t('steun.profielStelVraag', { naam: makelaar.voornaam })}
            variant="cta"
            size="lg"
            style={styles.profielKnop}
            onPress={() => onStart(makelaar)}
          />
        </>
      ) : null}
    </BottomSheet>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  statusRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    backgroundColor: colors.white,
    paddingHorizontal: spacing.screen,
    paddingVertical: spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: colors.line,
  },
  avatars: {
    flexDirection: 'row',
  },
  avatarWrap: {
    borderWidth: 2,
    borderColor: colors.white,
    borderRadius: 17,
  },
  statusText: {
    flex: 1,
    color: colors.primary,
  },
  wisselPill: {
    borderRadius: radius.pill,
    backgroundColor: colors.surfaceAlt,
    paddingHorizontal: 12,
    paddingVertical: 6,
  },
  wisselText: {
    color: colors.inkSoft,
  },
  list: {
    padding: spacing.screen,
    paddingRight: 84,
    gap: spacing.sm,
  },
  noticeCard: {
    backgroundColor: colors.surfaceAlt,
    borderRadius: radius.row,
    padding: spacing.md,
    marginBottom: spacing.sm,
  },
  notice: {
    textAlign: 'center',
    fontSize: 13,
  },
  bubble: {
    maxWidth: '82%',
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
  },
  own: {
    alignSelf: 'flex-end',
    backgroundColor: colors.chatOwn,
    borderTopLeftRadius: radius.bubble,
    borderTopRightRadius: radius.bubble,
    borderBottomRightRadius: radius.bubbleTail,
    borderBottomLeftRadius: radius.bubble,
  },
  other: {
    alignSelf: 'flex-start',
    backgroundColor: colors.chatOther,
    borderTopLeftRadius: radius.bubble,
    borderTopRightRadius: radius.bubble,
    borderBottomRightRadius: radius.bubble,
    borderBottomLeftRadius: radius.bubbleTail,
  },
  bubbleText: {
    fontSize: 15,
    lineHeight: 21,
  },
  deck: {
    position: 'absolute',
    top: spacing.md,
    right: spacing.md,
    alignItems: 'center',
  },
  deckCard: {
    backgroundColor: colors.white,
    borderRadius: 16,
    padding: 5,
    borderWidth: 1,
    borderColor: colors.line,
  },
  deckCardActive: {
    borderWidth: 2,
    borderColor: colors.accent,
  },
  deckOnlineDot: {
    position: 'absolute',
    right: 2,
    bottom: 2,
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: colors.accent,
    borderWidth: 2,
    borderColor: colors.white,
  },
  startRow: {
    gap: spacing.chipGap,
    paddingHorizontal: spacing.screen,
    paddingBottom: spacing.sm,
  },
  inputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    paddingHorizontal: spacing.screen,
    // Boven de zwevende tabbalk uitkomen zolang het toetsenbord dicht is.
    paddingBottom: 100,
  },
  inputRowKeyboard: {
    paddingBottom: spacing.sm,
  },
  input: {
    flex: 1,
    backgroundColor: colors.white,
    borderWidth: 1.5,
    borderColor: colors.line,
    borderRadius: radius.pill,
    paddingHorizontal: 16,
    paddingVertical: 12,
    fontFamily: 'ComicNeue_400Regular',
    fontSize: 15,
    color: colors.ink,
    minHeight: 46,
  },
  sendButton: {
    width: 46,
    height: 46,
    borderRadius: 23,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  profielBanner: {
    borderRadius: radius.card,
    alignItems: 'center',
    padding: spacing.xl,
    marginBottom: spacing.lg,
  },
  profielAvatarRing: {
    borderWidth: 3,
    borderColor: colors.white,
    borderRadius: 45,
    marginBottom: spacing.sm,
  },
  profielNaam: {
    color: colors.white,
    fontSize: 23,
  },
  profielMetaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginTop: spacing.sm,
  },
  profielStad: {
    color: 'rgba(255,255,255,0.85)',
  },
  profielOnlineRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginTop: spacing.md,
  },
  profielOnlineText: {
    color: 'rgba(255,255,255,0.9)',
  },
  profielBio: {
    fontSize: 15.5,
    lineHeight: 22,
  },
  profielKop: {
    color: colors.primaryMid,
    marginTop: spacing.lg,
    marginBottom: spacing.sm,
  },
  profielChips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.chipGap,
  },
  profielKnop: {
    marginTop: spacing.xl,
  },
});

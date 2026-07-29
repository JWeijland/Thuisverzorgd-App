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
  useBrokerPresence,
  useMakelaars,
  useMyBrokerChat,
  useSendBrokerMessage,
} from '@/features/forum/api';
import { useSession } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { useKeyboardOpen } from '@/lib/keyboard';
import { colors, radius, spacing } from '@/theme';
import { Avatar, Chip, PulseDot, TvzText } from '@/ui';

const START_QUESTIONS = ['steun.startvraag1', 'steun.startvraag2', 'steun.startvraag3'];

/** Hulpmakelaar-chat (screen 14): live chat met wachtrij-gevoel en "x online". */
export function BrokerChat() {
  const { session } = useSession();
  const chat = useMyBrokerChat();
  const messages = useBrokerMessages(chat.data);
  const send = useSendBrokerMessage(chat.data);
  const online = useBrokerPresence();
  const makelaars = useMakelaars();
  const keyboardOpen = useKeyboardOpen();
  const [draft, setDraft] = useState('');
  const scrollRef = useRef<ScrollView>(null);

  useEffect(() => {
    scrollRef.current?.scrollToEnd({ animated: true });
  }, [messages.data?.length]);

  function submit(text?: string) {
    const body = (text ?? draft).trim();
    if (!body || !chat.data) return;
    setDraft('');
    send.mutate(body);
  }

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
      <View style={styles.statusRow}>
        <View style={styles.avatars}>
          {(makelaars.data ?? []).length > 0
            ? makelaars.data!.map((makelaar, i) => (
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
          value={draft}
          onChangeText={setDraft}
          placeholder={t('steun.chatPlaceholder')}
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
    </KeyboardAvoidingView>
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
  list: {
    padding: spacing.screen,
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
});

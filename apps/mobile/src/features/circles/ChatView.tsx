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

import { useMessages, useSendMessage } from '@/features/circles/api';
import { useSession } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { useKeyboardOpen } from '@/lib/keyboard';
import { chatTintFor, colors, radius, spacing } from '@/theme';
import { TvzText } from '@/ui';

type Props = {
  circleId: string | undefined;
  /** Rolbijschrift achter de naam van de afzender, bijv. "(Beheerder)". */
  roleSuffix?: (senderId: string) => string;
};

/** Kringchat (screen 10): eigen berichten rechts (blauwgrijs), ander links (lichtgroen). */
export function ChatView({ circleId, roleSuffix }: Props) {
  const { session } = useSession();
  const messages = useMessages(circleId);
  const send = useSendMessage(circleId);
  const keyboardOpen = useKeyboardOpen();
  const [draft, setDraft] = useState('');
  const scrollRef = useRef<ScrollView>(null);

  useEffect(() => {
    scrollRef.current?.scrollToEnd({ animated: true });
  }, [messages.data?.length]);

  function submit() {
    const body = draft.trim();
    if (!body) return;
    setDraft('');
    send.mutate(body);
  }

  return (
    <KeyboardAvoidingView
      style={styles.fill}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <ScrollView ref={scrollRef} contentContainerStyle={styles.list}>
        {(messages.data ?? []).map((message) => {
          const own = message.sender_id === session?.user.id;
          const name = message.sender?.name.split(' ')[0] ?? '';
          return (
            <View
              key={message.id}
              style={[
                styles.bubble,
                own ? styles.own : styles.other,
                // Per kringgenoot een vaste eigen tint, zodat je afzenders kunt onderscheiden.
                !own && { backgroundColor: chatTintFor(message.sender_id) },
              ]}
            >
              <TvzText preset="meta" style={styles.sender}>
                {name}
                {roleSuffix ? roleSuffix(message.sender_id) : ''}
              </TvzText>
              <TvzText preset="body" style={styles.body}>
                {message.body}
              </TvzText>
            </View>
          );
        })}
      </ScrollView>
      <View style={[styles.inputRow, keyboardOpen && styles.inputRowKeyboard]}>
        <TextInput
          textContentType="none"
          autoComplete="off"
          value={draft}
          onChangeText={setDraft}
          placeholder={t('kring.chatPlaceholder')}
          placeholderTextColor={colors.inkFaint}
          style={styles.input}
          onSubmitEditing={submit}
          returnKeyType="send"
        />
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('kring.chatPlaceholder')}
          onPress={submit}
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
  list: {
    padding: spacing.screen,
    gap: spacing.sm,
    paddingBottom: spacing.md,
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
  sender: {
    fontSize: 11,
    marginBottom: 1,
  },
  body: {
    fontSize: 15,
    lineHeight: 21,
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

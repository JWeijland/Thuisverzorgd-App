import { router } from 'expo-router';
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
import { SafeAreaView } from 'react-native-safe-area-context';
import { Send } from 'lucide-react-native';

import {
  useBrokerChatsOverview,
  useBrokerMessages,
  useBrokerPresence,
  useReports,
  useResolveReport,
  useSendBrokerMessage,
} from '@/features/forum/api';
import { useProfile, useSession } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { colors, radius, spacing } from '@/theme';
import { Avatar, Button, Card, EmptyState, SectionHeader, TvzText } from '@/ui';
import { useStatusBalk } from '@/lib/statusbalk';

/**
 * Hulpmakelaar-console (besluit #11): eenvoudige web/app-route voor de rol
 * `makelaar` — gesprekken beantwoorden en meldingen binnen 24 uur afhandelen.
 * De console zet ook de presence-status ("x online") aan via useBrokerPresence.
 */
export default function MakelaarConsole() {
  useStatusBalk('donker');
  const profile = useProfile();
  const [openChat, setOpenChat] = useState<{ id: string; voornaam: string } | null>(null);
  const isBroker = profile.data?.role === 'makelaar';
  const chats = useBrokerChatsOverview(isBroker);
  const reports = useReports(isBroker);
  const resolve = useResolveReport();
  useBrokerPresence();

  if (profile.data && !isBroker) {
    return (
      <SafeAreaView style={styles.safe}>
        <View style={styles.center}>
          <EmptyState title={t('algemeen.foutTitel')} body={t('placeholder.tekst')} />
          <Button label={t('algemeen.terug')} variant="outline" onPress={() => router.back()} />
        </View>
      </SafeAreaView>
    );
  }

  if (openChat) {
    return (
      <ChatDetail
        chatId={openChat.id}
        voornaam={openChat.voornaam}
        onBack={() => setOpenChat(null)}
      />
    );
  }

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView contentContainerStyle={styles.list}>
        <View style={styles.headerRow}>
          <Pressable accessibilityRole="button" onPress={() => router.back()} style={styles.back}>
            <TvzText preset="cardTitle">←</TvzText>
          </Pressable>
          <TvzText preset="screenTitle" style={styles.title}>
            {t('makelaar.titel')}
          </TvzText>
        </View>

        <SectionHeader title={t('makelaar.chats')} />
        {(chats.data ?? []).length === 0 ? (
          <Card>
            <EmptyState title={t('makelaar.geenChats')} />
          </Card>
        ) : null}
        {(chats.data ?? []).map((chat) => (
          <Pressable
            key={chat.id}
            accessibilityRole="button"
            onPress={() => setOpenChat({ id: chat.id, voornaam: chat.voornaam })}
          >
            <Card style={styles.chatCard}>
              <View style={styles.chatRow}>
                <Avatar name={chat.voornaam} />
                <View style={styles.chatInfo}>
                  <TvzText preset="cardTitle">{chat.voornaam}</TvzText>
                  {chat.makelaar_voornaam ? (
                    <TvzText preset="meta" style={styles.gerichtAan}>
                      {t('makelaar.gerichtAan', { naam: chat.makelaar_voornaam })}
                    </TvzText>
                  ) : null}
                  {chat.laatste_bericht ? (
                    <TvzText preset="secondary" numberOfLines={1}>
                      {chat.laatste_bericht}
                    </TvzText>
                  ) : null}
                </View>
              </View>
            </Card>
          </Pressable>
        ))}

        <SectionHeader title={t('makelaar.meldingen')} />
        {(reports.data ?? []).length === 0 ? (
          <Card>
            <EmptyState title={t('makelaar.geenMeldingen')} />
          </Card>
        ) : null}
        {(reports.data ?? []).map((reportItem) => (
          <Card key={reportItem.id} style={styles.chatCard}>
            <TvzText preset="cardTitle" style={styles.reportTitle}>
              {reportItem.target_kind}
              {reportItem.samenvatting ? `: “${reportItem.samenvatting}”` : ''}
            </TvzText>
            {reportItem.reason ? <TvzText preset="secondary">{reportItem.reason}</TvzText> : null}
            <View style={styles.reportActions}>
              <Button
                label={t('makelaar.verbergen')}
                variant="danger"
                style={styles.reportButton}
                onPress={() => resolve.mutate({ reportId: reportItem.id, hide: true })}
              />
              <Button
                label={t('makelaar.afhandelen')}
                variant="outline"
                style={styles.reportButton}
                onPress={() => resolve.mutate({ reportId: reportItem.id, hide: false })}
              />
            </View>
          </Card>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}

function ChatDetail({
  chatId,
  voornaam,
  onBack,
}: {
  chatId: string;
  voornaam: string;
  onBack: () => void;
}) {
  const { session } = useSession();
  const messages = useBrokerMessages(chatId);
  const send = useSendBrokerMessage(chatId);
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
    <SafeAreaView style={styles.safe}>
      <KeyboardAvoidingView
        style={styles.fill}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <Pressable accessibilityRole="button" onPress={onBack} style={styles.backLink} hitSlop={8}>
          <TvzText preset="meta" style={styles.backLinkText}>
            {t('makelaar.terug')}
          </TvzText>
        </Pressable>
        <TvzText preset="cardTitle" style={styles.chatTitle}>
          {voornaam}
        </TvzText>
        <ScrollView ref={scrollRef} contentContainerStyle={styles.messages}>
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
        <View style={styles.inputRow}>
          <TextInput
            textContentType="none"
            autoComplete="off"
            value={draft}
            onChangeText={setDraft}
            placeholder={t('steun.chatPlaceholder')}
            placeholderTextColor={colors.inkFaint}
            style={styles.input}
            onSubmitEditing={submit}
            returnKeyType="send"
          />
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Verstuur"
            onPress={submit}
            style={styles.sendButton}
          >
            <Send color={colors.white} size={18} strokeWidth={2.2} />
          </Pressable>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  fill: { flex: 1 },
  center: {
    flex: 1,
    justifyContent: 'center',
    padding: spacing.screen,
    gap: spacing.md,
  },
  list: {
    padding: spacing.screen,
    gap: spacing.cardGap,
    paddingBottom: 40,
  },
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  back: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: {
    fontSize: 22,
    flex: 1,
  },
  chatCard: {
    paddingVertical: spacing.md,
  },
  chatRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  chatInfo: { flex: 1 },
  gerichtAan: {
    color: colors.primaryMid,
  },
  reportTitle: {
    fontSize: 15,
  },
  reportActions: {
    flexDirection: 'row',
    gap: spacing.sm,
    marginTop: spacing.md,
  },
  reportButton: {
    flex: 1,
    minHeight: 40,
    paddingVertical: 6,
    paddingHorizontal: 10,
  },
  backLink: {
    paddingHorizontal: spacing.screen,
    paddingTop: spacing.md,
  },
  backLinkText: {
    color: colors.primaryMid,
  },
  chatTitle: {
    paddingHorizontal: spacing.screen,
    paddingVertical: spacing.sm,
  },
  messages: {
    padding: spacing.screen,
    gap: spacing.sm,
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
  inputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    paddingHorizontal: spacing.screen,
    paddingBottom: spacing.md,
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
    backgroundColor: colors.primaryMid,
    alignItems: 'center',
    justifyContent: 'center',
  },
});

import { router, useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
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

import { useForumActions, usePost, useReplies } from '@/features/forum/api';
import { TAG_LABEL } from '@/features/forum/tags';
import { useSession } from '@/features/onboarding/useAuth';
import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import { t } from '@/i18n';
import { colors, radius, spacing } from '@/theme';
import { BottomSheet, Button, Card, Pill, TextField, TvzText } from '@/ui';
import { useStatusBalk } from '@/lib/statusbalk';

/** Thread-detail (screen 13): vraag + antwoorden; makelaars groen met badge; melden/blokkeren. */
export default function ForumThreadScreen() {
  useStatusBalk('donker');
  const { id } = useLocalSearchParams<{ id: string }>();
  const { session } = useSession();
  const post = usePost(id);
  const replies = useReplies(id);
  const { createReply, report, block } = useForumActions();
  const [draft, setDraft] = useState('');
  const [moderating, setModerating] = useState<{
    kind: 'post' | 'reply';
    targetId: string;
    authorId: string;
  } | null>(null);
  const [reportReason, setReportReason] = useState('');
  const [feedback, setFeedback] = useState<string | null>(null);

  const item = post.data;

  function submitReply() {
    const body = draft.trim();
    if (createReply.isPending || body.length < 2 || !id) return;
    createReply.mutate({ postId: id, body }, { onSuccess: () => setDraft('') });
  }

  return (
    <SafeAreaView style={styles.safe}>
      <KeyboardAvoidingView
        style={styles.fill}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <View style={styles.headerRow}>
          <Pressable accessibilityRole="button" onPress={() => router.back()} style={styles.back}>
            <TvzText preset="cardTitle">←</TvzText>
          </Pressable>
        </View>
        <ScrollView contentContainerStyle={styles.list}>
          {item ? (
            <Card>
              <View style={styles.postMeta}>
                <View style={styles.wie}>
                  <ProfileAvatar name={item.voornaam} avatarPath={item.avatar_path} size={30} />
                  <TvzText preset="meta" style={styles.metaText}>
                    {item.voornaam}
                    {item.city ? ` · ${item.city}` : ''}
                  </TvzText>
                </View>
                <View style={styles.metaRight}>
                  <Pill label={t(TAG_LABEL[item.tag])} />
                  {item.author_id !== session?.user.id ? (
                    <Pressable
                      accessibilityRole="button"
                      accessibilityLabel={t('steun.melden')}
                      hitSlop={8}
                      onPress={() =>
                        setModerating({ kind: 'post', targetId: item.id, authorId: item.author_id })
                      }
                    >
                      <TvzText preset="cardTitle" style={styles.dots}>
                        ⋯
                      </TvzText>
                    </Pressable>
                  ) : null}
                </View>
              </View>
              <TvzText preset="cardTitle" style={styles.title}>
                {item.title}
              </TvzText>
              {item.body ? <TvzText preset="body">{item.body}</TvzText> : null}
            </Card>
          ) : null}

          {(replies.data ?? []).map((reply) => (
            <View
              key={reply.id}
              style={[styles.reply, reply.is_broker ? styles.brokerReply : null]}
            >
              <View style={styles.postMeta}>
                <View style={styles.wie}>
                  <ProfileAvatar name={reply.voornaam} avatarPath={reply.avatar_path} size={26} />
                  <TvzText preset="meta" style={styles.metaText}>
                    {reply.voornaam}
                  </TvzText>
                </View>
                <View style={styles.metaRight}>
                  {reply.is_broker ? (
                    <Pill
                      label={t('steun.makelaarBadge')}
                      color={colors.successText}
                      backgroundColor={colors.successBg}
                    />
                  ) : null}
                  {reply.author_id !== session?.user.id ? (
                    <Pressable
                      accessibilityRole="button"
                      accessibilityLabel={t('steun.melden')}
                      hitSlop={8}
                      onPress={() =>
                        setModerating({
                          kind: 'reply',
                          targetId: reply.id,
                          authorId: reply.author_id,
                        })
                      }
                    >
                      <TvzText preset="cardTitle" style={styles.dots}>
                        ⋯
                      </TvzText>
                    </Pressable>
                  ) : null}
                </View>
              </View>
              <TvzText preset="body">{reply.body}</TvzText>
            </View>
          ))}
          {feedback ? (
            <TvzText preset="secondary" style={styles.feedback}>
              {feedback}
            </TvzText>
          ) : null}
        </ScrollView>

        <View style={styles.composer}>
          <TextInput
            textContentType="none"
            autoComplete="off"
            value={draft}
            onChangeText={setDraft}
            placeholder={t('steun.reageerPlaceholder')}
            placeholderTextColor={colors.inkFaint}
            style={styles.composerInput}
            onSubmitEditing={submitReply}
            returnKeyType="send"
          />
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={t('steun.reageerPlaceholder')}
            onPress={submitReply}
            style={styles.sendButton}
          >
            <Send color={colors.white} size={18} strokeWidth={2.2} />
          </Pressable>
        </View>
      </KeyboardAvoidingView>

      <BottomSheet
        visible={!!moderating}
        onClose={() => setModerating(null)}
        title={t('steun.meldenTitel')}
      >
        <TextField
          label={t('steun.melden')}
          placeholder={t('steun.meldenPlaceholder')}
          value={reportReason}
          onChangeText={setReportReason}
        />
        <Button
          label={t('steun.meldenVerstuur')}
          variant="primary"
          onPress={() => {
            if (!moderating) return;
            report.mutate(
              {
                targetKind: moderating.kind,
                targetId: moderating.targetId,
                reason: reportReason.trim() || undefined,
              },
              {
                onSuccess: () => {
                  setModerating(null);
                  setReportReason('');
                  setFeedback(t('steun.gemeld'));
                },
              },
            );
          }}
        />
        <Button
          label={t('steun.blokkeren')}
          variant="danger"
          style={styles.blockButton}
          onPress={() => {
            if (!moderating) return;
            block.mutate(moderating.authorId, {
              onSuccess: () => {
                setModerating(null);
                setFeedback(t('steun.geblokkeerd'));
              },
            });
          }}
        />
      </BottomSheet>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  fill: { flex: 1 },
  headerRow: {
    paddingHorizontal: spacing.screen,
    paddingTop: spacing.sm,
  },
  back: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center',
    justifyContent: 'center',
  },
  list: {
    padding: spacing.screen,
    gap: spacing.cardGap,
  },
  wie: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    flexShrink: 1,
  },
  postMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 4,
  },
  metaRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  metaText: {
    color: colors.inkFaint,
  },
  dots: {
    color: colors.inkFaint,
  },
  title: {
    marginBottom: 4,
  },
  reply: {
    backgroundColor: colors.white,
    borderRadius: radius.row,
    padding: spacing.lg,
  },
  brokerReply: {
    borderWidth: 1.5,
    borderColor: colors.accent,
  },
  feedback: {
    textAlign: 'center',
    color: colors.successText,
  },
  composer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    paddingHorizontal: spacing.screen,
    paddingBottom: spacing.md,
  },
  composerInput: {
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
  blockButton: {
    marginTop: spacing.sm,
  },
});

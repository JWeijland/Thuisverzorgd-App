import { router } from 'expo-router';
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
import { Send } from 'lucide-react-native';

import { ProfileAvatar } from '@/features/avatars/ProfileAvatar';
import { useForumActions, usePosts, type ForumTag } from '@/features/forum/api';
import { TAGS, TAG_LABEL } from '@/features/forum/tags';
import { t } from '@/i18n';
import { useKeyboardOpen } from '@/lib/keyboard';
import { useStatusBalk } from '@/lib/statusbalk';
import { colors, radius, spacing } from '@/theme';
import { Card, Chip, EmptyState, Pill, TvzText } from '@/ui';
import { TerugKop } from '@/ui/TerugKop';

function timeAgo(iso: string): string {
  const minutes = Math.floor((Date.now() - new Date(iso).getTime()) / 60000);
  if (minutes < 60) return `${Math.max(minutes, 1)} min`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} u`;
  if (hours < 48) return 'gisteren';
  return `${Math.floor(hours / 24)} d`;
}

/** Forum als eigen pagina (laag 1): vragen lezen en stellen, één functie. */
export default function ForumScreen() {
  useStatusBalk('donker');
  const [filter, setFilter] = useState<ForumTag | null>(null);
  const [quick, setQuick] = useState('');
  const keyboardOpen = useKeyboardOpen();
  const posts = usePosts(filter);
  const { createPost } = useForumActions();

  // De vraag landt in de categorie die bovenin geselecteerd staat.
  function submitQuick() {
    const titel = quick.trim();
    if (titel.length < 8 || createPost.isPending) return;
    createPost.mutate(
      { title: titel, body: '', tag: filter ?? 'overig' },
      {
        onSuccess: () => setQuick(''),
      },
    );
  }

  return (
    <View style={styles.safeBg}>
      <TerugKop titel={t('steun.tabForum')} sub={t('steun.subtitel')} />
      <KeyboardAvoidingView
        style={styles.fill}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <ScrollView contentContainerStyle={styles.list}>
          <View style={styles.chips}>
            <Chip
              label={t('steun.tagAlles')}
              selected={filter === null}
              onPress={() => setFilter(null)}
            />
            {TAGS.map((tag) => (
              <Chip
                key={tag.key}
                label={t(tag.labelKey)}
                selected={filter === tag.key}
                onPress={() => setFilter(tag.key)}
              />
            ))}
          </View>

          {!posts.isLoading && (posts.data ?? []).length === 0 ? (
            <Card>
              <EmptyState title={t('steun.leegTitel')} body={t('steun.leegTekst')} />
            </Card>
          ) : null}
          {(posts.data ?? []).map((post) => (
            <Pressable
              key={post.id}
              accessibilityRole="button"
              onPress={() => router.push({ pathname: '/forum/[id]', params: { id: post.id } })}
            >
              <Card style={styles.postCard}>
                <View style={styles.postKop}>
                  <ProfileAvatar name={post.voornaam} avatarPath={post.avatar_path} size={36} />
                  <View style={styles.postKopText}>
                    <View style={styles.postMeta}>
                      <TvzText preset="meta" style={styles.metaText}>
                        {post.voornaam}
                        {post.city ? ` · ${post.city}` : ''} · {timeAgo(post.created_at)}
                      </TvzText>
                      <Pill label={t(TAG_LABEL[post.tag])} />
                    </View>
                    <TvzText preset="cardTitle" style={styles.postTitle}>
                      {post.title}
                    </TvzText>
                    <TvzText preset="secondary">
                      {post.antwoorden === 0
                        ? t('steun.nogGeen')
                        : post.antwoorden === 1
                          ? t('steun.antwoord1')
                          : t('steun.antwoorden', { aantal: post.antwoorden })}
                    </TvzText>
                  </View>
                </View>
              </Card>
            </Pressable>
          ))}
        </ScrollView>

        {/* Typebalk: de gekozen categorie staat als pil vóór het veld. */}
        <View style={[styles.inputRow, keyboardOpen && styles.inputRowKeyboard]}>
          {filter ? <Pill label={t(TAG_LABEL[filter])} /> : null}
          <TextInput
            textContentType="none"
            autoComplete="off"
            value={quick}
            onChangeText={setQuick}
            placeholder={t('steun.forumSnelPlaceholder')}
            placeholderTextColor={colors.inkFaint}
            style={styles.input}
            onSubmitEditing={submitQuick}
            returnKeyType="send"
          />
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={t('steun.plaatsVraag')}
            onPress={submitQuick}
            style={styles.sendButton}
          >
            <Send color={colors.white} size={18} strokeWidth={2.2} />
          </Pressable>
        </View>
      </KeyboardAvoidingView>
    </View>
  );
}

const styles = StyleSheet.create({
  safeBg: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  fill: { flex: 1 },
  list: {
    padding: spacing.screen,
    paddingTop: spacing.sm,
    paddingBottom: spacing.md,
    gap: spacing.cardGap,
  },
  chips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.chipGap,
    marginBottom: spacing.xs,
  },
  postCard: {
    paddingVertical: spacing.md,
  },
  postKop: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: spacing.md,
  },
  postKopText: {
    flex: 1,
  },
  postMeta: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 4,
  },
  metaText: {
    color: colors.inkFaint,
  },
  postTitle: {
    marginBottom: 2,
  },
  inputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    paddingHorizontal: spacing.screen,
    paddingBottom: spacing.xl,
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

import { LinearGradient } from 'expo-linear-gradient';
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
import { SafeAreaView } from 'react-native-safe-area-context';
import { Send } from 'lucide-react-native';

import { BrokerChat } from '@/features/forum/BrokerChat';
import { useForumActions, usePosts, type ForumTag } from '@/features/forum/api';
import { t } from '@/i18n';
import { useKeyboardOpen } from '@/lib/keyboard';
import { colors, gradient, radius, spacing } from '@/theme';
import { BottomSheet, Button, Card, Chip, EmptyState, Pill, TextField, TvzText } from '@/ui';

const TAGS: { key: ForumTag; labelKey: string }[] = [
  { key: 'wonen', labelKey: 'steun.tagWonen' },
  { key: 'werk', labelKey: 'steun.tagWerk' },
  { key: 'financien', labelKey: 'steun.tagFinancien' },
  { key: 'dementie', labelKey: 'steun.tagDementie' },
];

export const TAG_LABEL: Record<ForumTag, string> = {
  wonen: 'steun.tagWonen',
  werk: 'steun.tagWerk',
  financien: 'steun.tagFinancien',
  dementie: 'steun.tagDementie',
  overig: 'steun.tagOverig',
};

function timeAgo(iso: string): string {
  const minutes = Math.floor((Date.now() - new Date(iso).getTime()) / 60000);
  if (minutes < 60) return `${Math.max(minutes, 1)} min`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} u`;
  if (hours < 48) return 'gisteren';
  return `${Math.floor(hours / 24)} d`;
}

/** Steun & advies (screens 13/14): forum + live chat met hulpmakelaars. */
export default function SteunScreen() {
  const [tab, setTab] = useState<'forum' | 'makelaar'>('forum');
  const [filter, setFilter] = useState<ForumTag | null>(null);
  const [composerOpen, setComposerOpen] = useState(false);
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [composeTag, setComposeTag] = useState<ForumTag>('overig');
  const [quick, setQuick] = useState('');
  const keyboardOpen = useKeyboardOpen();
  const posts = usePosts(filter);
  const { createPost } = useForumActions();

  // De vraag landt in de categorie die bovenin geselecteerd staat.
  function submitQuick() {
    const quickTitle = quick.trim();
    if (quickTitle.length < 8 || createPost.isPending) return;
    createPost.mutate(
      { title: quickTitle, body: '', tag: filter ?? 'overig' },
      { onSuccess: () => setQuick('') },
    );
  }

  function openComposer() {
    setComposeTag(filter ?? 'overig');
    setComposerOpen(true);
  }

  return (
    <View style={styles.safeBg}>
      <LinearGradient {...gradient} style={styles.header}>
        <SafeAreaView edges={['top']}>
          <TvzText preset="screenTitle" style={styles.headerTitle}>
            {t('steun.titel')}
          </TvzText>
          <TvzText preset="secondary" style={styles.headerSub}>
            {t('steun.subtitel')}
          </TvzText>
          <View style={styles.subnav}>
            {(['forum', 'makelaar'] as const).map((key) => (
              <Pressable
                key={key}
                accessibilityRole="tab"
                accessibilityState={{ selected: tab === key }}
                onPress={() => setTab(key)}
                style={[styles.subnavPill, tab === key && styles.subnavActive]}
              >
                <TvzText
                  preset="meta"
                  style={tab === key ? styles.subnavTextActive : styles.subnavText}
                >
                  {t(key === 'forum' ? 'steun.tabForum' : 'steun.tabMakelaar')}
                </TvzText>
              </Pressable>
            ))}
          </View>
        </SafeAreaView>
      </LinearGradient>

      {tab === 'makelaar' ? (
        <BrokerChat />
      ) : (
        <KeyboardAvoidingView
          style={styles.fill}
          behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        >
          <ScrollView contentContainerStyle={styles.list}>
            <Button label={t('steun.stelVraag')} variant="cta" size="lg" onPress={openComposer} />
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
                </Card>
              </Pressable>
            ))}
          </ScrollView>
          {filter ? (
            <View style={styles.categorieRij}>
              <View style={styles.categorieDot} />
              <TvzText preset="meta" style={styles.categorieText}>
                {t('steun.plaatsInCategorie', { categorie: t(TAG_LABEL[filter]) })}
              </TvzText>
            </View>
          ) : null}
          <View style={[styles.inputRow, keyboardOpen && styles.inputRowKeyboard]}>
            <TextInput
              value={quick}
              onChangeText={setQuick}
              placeholder={
                filter
                  ? t('steun.forumSnelPlaceholderTag', { categorie: t(TAG_LABEL[filter]) })
                  : t('steun.forumSnelPlaceholder')
              }
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
      )}

      <BottomSheet
        visible={composerOpen}
        onClose={() => setComposerOpen(false)}
        title={t('steun.stelVraag')}
      >
        <TextField
          label={t('steun.vraagTitelLabel')}
          placeholder={t('steun.vraagTitelPlaceholder')}
          value={title}
          onChangeText={setTitle}
        />
        <TextField
          label={t('steun.vraagTekstLabel')}
          placeholder={t('steun.vraagTekstPlaceholder')}
          value={body}
          onChangeText={setBody}
          multiline
        />
        <View style={styles.chips}>
          {[...TAGS, { key: 'overig' as ForumTag, labelKey: 'steun.tagOverig' }].map((tag) => (
            <Chip
              key={tag.key}
              label={t(tag.labelKey)}
              selected={composeTag === tag.key}
              onPress={() => setComposeTag(tag.key)}
            />
          ))}
        </View>
        <Button
          label={t('steun.plaatsVraag')}
          variant="cta"
          size="lg"
          disabled={createPost.isPending || title.trim().length < 8}
          onPress={() =>
            createPost.mutate(
              { title: title.trim(), body: body.trim(), tag: composeTag },
              {
                onSuccess: () => {
                  setComposerOpen(false);
                  setTitle('');
                  setBody('');
                },
              },
            )
          }
        />
      </BottomSheet>
    </View>
  );
}

const styles = StyleSheet.create({
  safeBg: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  header: {
    paddingHorizontal: spacing.screen,
    paddingBottom: spacing.lg,
  },
  headerTitle: {
    color: colors.white,
    fontSize: 24,
    marginTop: spacing.sm,
  },
  headerSub: {
    color: 'rgba(255,255,255,0.8)',
    marginBottom: spacing.md,
  },
  subnav: {
    flexDirection: 'row',
    gap: spacing.sm,
  },
  subnavPill: {
    borderRadius: radius.pill,
    paddingHorizontal: 16,
    paddingVertical: 7,
    backgroundColor: 'rgba(255,255,255,0.18)',
  },
  subnavActive: {
    backgroundColor: colors.white,
  },
  subnavText: {
    color: colors.white,
  },
  subnavTextActive: {
    color: colors.primary,
  },
  fill: { flex: 1 },
  list: {
    padding: spacing.screen,
    paddingBottom: spacing.md,
    gap: spacing.cardGap,
  },
  categorieRij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    paddingHorizontal: spacing.screen,
    paddingBottom: spacing.xs,
  },
  categorieDot: {
    width: 7,
    height: 7,
    borderRadius: 4,
    backgroundColor: colors.primaryMid,
  },
  categorieText: {
    color: colors.primaryMid,
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
  chips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.chipGap,
    marginVertical: spacing.sm,
  },
  postCard: {
    paddingVertical: spacing.md,
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
});

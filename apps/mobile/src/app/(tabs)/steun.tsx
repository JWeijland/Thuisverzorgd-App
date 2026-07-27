import { LinearGradient } from 'expo-linear-gradient';
import { router } from 'expo-router';
import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { BrokerChat } from '@/features/forum/BrokerChat';
import { useForumActions, usePosts, type ForumTag } from '@/features/forum/api';
import { t } from '@/i18n';
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
  const posts = usePosts(filter);
  const { createPost } = useForumActions();

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
        <ScrollView contentContainerStyle={styles.list}>
          <Button
            label={t('steun.stelVraag')}
            variant="cta"
            size="lg"
            onPress={() => setComposerOpen(true)}
          />
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
  list: {
    padding: spacing.screen,
    paddingBottom: 110,
    gap: spacing.cardGap,
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

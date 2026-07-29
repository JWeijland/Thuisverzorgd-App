import { LinearGradient } from 'expo-linear-gradient';
import { useQuery } from '@tanstack/react-query';
import { router } from 'expo-router';
import { ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { useProfile } from '@/features/onboarding/useAuth';
import { t } from '@/i18n';
import { supabase } from '@/lib/supabase';
import { colors, gradient, radius, spacing } from '@/theme';
import { Button, Card, EmptyState, Pill, TvzText } from '@/ui';

type Kerncijfers = {
  actieve_hulpkringen: number;
  buddys: number;
  taken_vervuld_pct: number;
  taken_vandaag: number;
};

/**
 * Admin-inzichten (screen 25): uitsluitend geaggregeerde, geanonimiseerde data
 * uit de v_admin_*-views — de admin-rol heeft nergens tabeltoegang.
 */
export default function AdminScreen() {
  const profile = useProfile();
  const isAdmin = profile.data?.role === 'admin' || profile.data?.platform_admin === true;

  const kerncijfers = useQuery({
    queryKey: ['admin-kerncijfers'],
    enabled: isAdmin,
    queryFn: async (): Promise<Kerncijfers | null> => {
      const { data } = await supabase.from('v_admin_kerncijfers').select('*').maybeSingle();
      return data as Kerncijfers | null;
    },
  });
  const groei = useQuery({
    queryKey: ['admin-groei'],
    enabled: isAdmin,
    queryFn: async () => {
      const { data } = await supabase.from('v_admin_groei_per_maand').select('*');
      return (data ?? []) as { maand: string; nieuwe_kringen: number }[];
    },
  });
  const perType = useQuery({
    queryKey: ['admin-per-type'],
    enabled: isAdmin,
    queryFn: async () => {
      const { data } = await supabase.from('v_admin_taken_per_type').select('*');
      return (data ?? []) as { type: string; aantal: number }[];
    },
  });
  const matchtijd = useQuery({
    queryKey: ['admin-matchtijd'],
    enabled: isAdmin,
    queryFn: async () => {
      const { data } = await supabase.from('v_admin_matchtijd').select('*').maybeSingle();
      return (data as { gemiddelde_uren_tot_match: number } | null)?.gemiddelde_uren_tot_match ?? 0;
    },
  });

  if (profile.data && !isAdmin) {
    return (
      <SafeAreaView style={styles.safe}>
        <View style={styles.center}>
          <EmptyState title={t('algemeen.foutTitel')} body={t('admin.geenToegang')} />
          <Button label={t('algemeen.terug')} variant="outline" onPress={() => router.back()} />
        </View>
      </SafeAreaView>
    );
  }

  const cijfers = kerncijfers.data;
  const totalType = (perType.data ?? []).reduce((sum, row) => sum + row.aantal, 0);
  const maxGroei = Math.max(...(groei.data ?? []).map((row) => row.nieuwe_kringen), 1);

  return (
    <View style={styles.safeBg}>
      <LinearGradient {...gradient} style={styles.header}>
        <SafeAreaView edges={['top']}>
          <View style={styles.headerRow}>
            <View style={styles.logoRow}>
              <View style={[styles.logoBar, { backgroundColor: colors.accent }]} />
              <View style={[styles.logoBar, { backgroundColor: colors.primaryMid }]} />
              <TvzText preset="cardTitle" style={styles.headerTitle}>
                {t('admin.titel')}
              </TvzText>
            </View>
            <Pill
              label={t('admin.pilot')}
              color={colors.white}
              backgroundColor="rgba(255,255,255,0.2)"
            />
          </View>
          <TvzText preset="secondary" style={styles.headerSub}>
            {t('admin.subtitel')}
          </TvzText>
        </SafeAreaView>
      </LinearGradient>

      <ScrollView contentContainerStyle={styles.list}>
        <View style={styles.tiles}>
          <StatTile value={`${cijfers?.actieve_hulpkringen ?? '–'}`} label={t('admin.kringen')} />
          <StatTile value={`${cijfers?.buddys ?? '–'}`} label={t('admin.buddys')} />
          <StatTile value={`${cijfers?.taken_vervuld_pct ?? '–'}%`} label={t('admin.vervuld')} />
          <StatTile value={`${cijfers?.taken_vandaag ?? '–'}`} label={t('admin.vandaag')} />
        </View>

        <Card style={styles.chartCard}>
          <TvzText preset="cardTitle">{t('admin.groei')}</TvzText>
          <TvzText preset="secondary">{t('admin.groeiUitleg')}</TvzText>
          <View style={styles.barChart}>
            {(groei.data ?? []).map((row, i, all) => (
              <View key={row.maand} style={styles.barCol}>
                <TvzText preset="meta" style={styles.barValue}>
                  {row.nieuwe_kringen}
                </TvzText>
                <View
                  style={[
                    styles.bar,
                    {
                      height: 12 + (row.nieuwe_kringen / maxGroei) * 80,
                      backgroundColor: i === all.length - 1 ? colors.accent : colors.primary,
                    },
                  ]}
                />
                <TvzText preset="meta" style={styles.barLabel}>
                  {row.maand.slice(5)}
                </TvzText>
              </View>
            ))}
          </View>
        </Card>

        <Card style={styles.chartCard}>
          <TvzText preset="cardTitle">{t('admin.perType')}</TvzText>
          <TvzText preset="secondary">{t('admin.perTypeUitleg')}</TvzText>
          <View style={styles.typeRows}>
            {(perType.data ?? []).map((row) => (
              <View key={row.type} style={styles.typeRow}>
                <TvzText preset="secondary" style={styles.typeName}>
                  {row.type.charAt(0).toUpperCase()}
                  {row.type.slice(1)}
                </TvzText>
                <View style={styles.typeTrack}>
                  <View
                    style={[
                      styles.typeBar,
                      { width: `${Math.max(6, (row.aantal / Math.max(totalType, 1)) * 100)}%` },
                    ]}
                  />
                </View>
                <TvzText preset="meta" style={styles.typePct}>
                  {totalType > 0 ? Math.round((row.aantal / totalType) * 100) : 0}%
                </TvzText>
              </View>
            ))}
          </View>
        </Card>

        <Card style={styles.chartCard}>
          <TvzText preset="screenTitle" style={styles.matchtijd}>
            {t('admin.matchtijd', {
              uren: `${matchtijd.data ?? 0}`.replace('.', ','),
            })}
          </TvzText>
          <TvzText preset="secondary">{t('admin.matchtijdUitleg')}</TvzText>
        </Card>
      </ScrollView>
    </View>
  );
}

function StatTile({ value, label }: { value: string; label: string }) {
  return (
    <Card style={styles.tile}>
      <TvzText preset="screenTitle" style={styles.tileValue}>
        {value}
      </TvzText>
      <View style={styles.tileDash} />
      <TvzText preset="secondary" style={styles.tileLabel}>
        {label}
      </TvzText>
    </Card>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  safeBg: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  center: {
    flex: 1,
    justifyContent: 'center',
    padding: spacing.screen,
    gap: spacing.md,
  },
  header: {
    paddingHorizontal: spacing.screen,
    paddingBottom: spacing.md,
  },
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: spacing.sm,
  },
  logoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
  },
  logoBar: {
    width: 14,
    height: 8,
    borderRadius: radius.pill,
  },
  headerTitle: {
    color: colors.white,
    marginLeft: 4,
  },
  headerSub: {
    color: 'rgba(255,255,255,0.75)',
    fontSize: 12.5,
    marginTop: 4,
  },
  list: {
    padding: spacing.screen,
    gap: spacing.cardGap,
    paddingBottom: 40,
  },
  tiles: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.cardGap,
  },
  tile: {
    flexBasis: '47%',
    flexGrow: 1,
  },
  tileValue: {
    fontSize: 26,
  },
  tileDash: {
    width: 22,
    height: 4,
    borderRadius: radius.pill,
    backgroundColor: colors.accent,
    marginVertical: 6,
  },
  tileLabel: {
    fontSize: 13,
  },
  chartCard: {
    marginTop: spacing.xs,
  },
  barChart: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'space-between',
    marginTop: spacing.lg,
    minHeight: 120,
  },
  barCol: {
    alignItems: 'center',
    flex: 1,
    gap: 4,
  },
  bar: {
    width: 22,
    borderRadius: 6,
  },
  barValue: {
    color: colors.inkSoft,
    fontSize: 11,
  },
  barLabel: {
    color: colors.inkFaint,
    fontSize: 10.5,
  },
  typeRows: {
    marginTop: spacing.md,
    gap: spacing.sm,
  },
  typeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  typeName: {
    width: 100,
    fontSize: 13,
  },
  typeTrack: {
    flex: 1,
    height: 8,
    borderRadius: radius.pill,
    backgroundColor: colors.surfaceAlt,
    overflow: 'hidden',
  },
  typeBar: {
    height: 8,
    borderRadius: radius.pill,
    backgroundColor: colors.primaryMid,
  },
  typePct: {
    width: 40,
    textAlign: 'right',
  },
  matchtijd: {
    fontSize: 26,
  },
});

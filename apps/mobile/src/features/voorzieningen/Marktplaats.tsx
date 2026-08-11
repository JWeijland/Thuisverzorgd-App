import { LinearGradient } from 'expo-linear-gradient';
import { router } from 'expo-router';
import { Image, Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { Star } from 'lucide-react-native';

import { AanbiederAvatar } from '@/features/voorzieningen/AanbiederAvatar';
import { useDiensten, type Dienst } from '@/features/voorzieningen/api';
import { euro } from '@/features/voorzieningen/slots';
import { t } from '@/i18n';
import { colors, radius, spacing } from '@/theme';
import { TvzText, tvzIn } from '@/ui';
import Animated from 'react-native-reanimated';

/** Foto van de buddy-tegel: een buddy op bezoek, samen op de bank. */
const BUDDY_FOTO = require('../../../assets/images/diensten/buddy.jpg');

/** Foto per dienst (Pexels, zie assets/images/diensten/BRONNEN.md). */
const DIENST_FOTOS: Record<string, number> = {
  kapper: require('../../../assets/images/diensten/kapper.jpg'),
  boodschappen: require('../../../assets/images/diensten/boodschappen.jpg'),
  maaltijden: require('../../../assets/images/diensten/maaltijden.jpg'),
  schoonmaak: require('../../../assets/images/diensten/schoonmaak.jpg'),
  tuinman: require('../../../assets/images/diensten/tuinman.jpg'),
  'massage-fysio': require('../../../assets/images/diensten/massage-fysio.jpg'),
  vervoer: require('../../../assets/images/diensten/vervoer.jpg'),
  'hond-uitlaten': require('../../../assets/images/diensten/hond-uitlaten.jpg'),
  klusjesman: require('../../../assets/images/diensten/klusjesman.jpg'),
};

/**
 * Voorzieningen (handoff, scherm 03): het raster met bijna vierkante blokjes.
 * De kop is nu de PadHeader van het hulp-pad, dus dit scherm begint direct
 * met de tegels: Buddy uitgelicht en gratis, daarna de betaalde diensten.
 */
export function Marktplaats() {
  const diensten = useDiensten();
  // Geen zoekbalk meer (feedback Jelle 11-08): met tien tegels zoek je met je
  // ogen, niet met een toetsenbord.
  const lijst = diensten.data ?? [];

  return (
    <View style={styles.safe}>

      <ScrollView contentContainerStyle={styles.lijst}>
        <Animated.View entering={tvzIn}>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={t('voorzien.buddyTegelTitel')}
              onPress={() => router.push('/dienst/buddy')}
            >
              {/* Een echte foto in plaats van een blauw vlak: je ziet meteen
                  waar een buddy voor is (feedback Jelle 11-08). */}
              <View style={styles.buddyTegel}>
                <Image source={BUDDY_FOTO} style={styles.buddyFoto} resizeMode="cover" />
                <LinearGradient
                  colors={['transparent', 'rgba(17,38,64,0.15)', 'rgba(17,38,64,0.82)']}
                  style={styles.buddySluier}
                />
                <View style={styles.buddyTekst}>
                  <View style={styles.buddyKop}>
                    <TvzText preset="cardTitle" style={styles.buddyTitel}>
                      {t('voorzien.buddyTegelTitel')}
                    </TvzText>
                    <View style={styles.gratisPill}>
                      <TvzText preset="meta" style={styles.gratisTekst}>
                        {t('voorzien.gratisPill')}
                      </TvzText>
                    </View>
                  </View>
                  <TvzText preset="secondary" style={styles.buddySub}>
                    {t('voorzien.buddyTegelTekst')}
                  </TvzText>
                </View>
              </View>
            </Pressable>
        </Animated.View>

        <View style={styles.sectieKop}>
          <TvzText preset="sectionTitle">{t('voorzien.dienstenTitel')}</TvzText>
          <TvzText preset="secondary" style={styles.sectieSub}>
            {t('voorzien.dienstenSub')}
          </TvzText>
        </View>

        <View style={styles.grid}>
          {lijst.map((dienst) => (
            <DienstTegel key={dienst.id} dienst={dienst} />
          ))}
        </View>

      </ScrollView>
    </View>
  );
}

function DienstTegel({ dienst }: { dienst: Dienst }) {
  const foto = DIENST_FOTOS[dienst.slug];
  const prijs =
    dienst.unit === 'uur'
      ? `${euro(dienst.price_cents)}${t('voorzien.uurKort')}`
      : euro(dienst.price_cents);
  const cijfer = String(Number(dienst.rating)).replace('.', ',');
  return (
    <Animated.View entering={tvzIn} style={styles.tegelWrap}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={`${dienst.name}, ${prijs}, ${dienst.provider.business}`}
        onPress={() => router.push({ pathname: '/dienst/[slug]', params: { slug: dienst.slug } })}
        style={styles.tegel}
      >
        <View style={styles.tegelBeeld}>
          {foto ? <Image source={foto} style={styles.tegelFoto} resizeMode="cover" /> : null}
          {/* De aanbieder als gezicht op de rand van de foto: je boekt een
              mens, geen categorie. */}
          <View style={styles.aanbiederRing}>
            <AanbiederAvatar
              slug={dienst.slug}
              naam={dienst.provider.name}
              avatarPad={dienst.provider.avatar_path}
              size={34}
            />
          </View>
        </View>
        <View style={styles.tegelTekst}>
          <TvzText preset="cardTitle" numberOfLines={1} style={styles.tegelNaam}>
            {dienst.name}
          </TvzText>
          <TvzText preset="secondary" numberOfLines={1} style={styles.tegelAanbieder}>
            {dienst.provider.business}
          </TvzText>
          <View style={styles.tegelVoet}>
            <TvzText preset="meta" style={styles.tegelPrijs}>
              {prijs}
            </TvzText>
            <View style={styles.beoordeling}>
              <Star size={12} strokeWidth={2} color={colors.accentDark} fill={colors.accent} />
              <TvzText preset="meta" style={styles.beoordelingTekst}>
                {cijfer}
              </TvzText>
            </View>
          </View>
        </View>
      </Pressable>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  lijst: {
    padding: spacing.screen,
    paddingBottom: spacing.xxl,
    gap: spacing.cardGap,
  },
  // Buddy is de belangrijkste voorziening van de app, dus de tegel is een
  // brede banner met een echte foto. De verhouding volgt de foto (1200×620),
  // zodat er niets wordt uitgerekt of afgesneden.
  buddyTegel: {
    aspectRatio: 1200 / 620,
    borderRadius: radius.tile,
    overflow: 'hidden',
    justifyContent: 'flex-end',
  },
  buddyFoto: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
  buddySluier: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    height: '78%',
  },
  // Ruimte rondom de tekst, zodat hij niet tegen de rand van de foto plakt.
  buddyTekst: {
    padding: spacing.cardPadding,
    paddingBottom: spacing.lg,
  },
  buddyKop: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  buddyTitel: {
    color: colors.white,
    fontSize: 20,
  },
  buddySub: {
    color: 'rgba(255,255,255,0.85)',
    marginTop: 2,
  },
  gratisPill: {
    backgroundColor: colors.white,
    borderRadius: radius.pill,
    paddingHorizontal: 10,
    paddingVertical: 3,
  },
  gratisTekst: {
    color: colors.successText,
  },
  sectieKop: {
    marginTop: spacing.md,
  },
  sectieSub: {
    marginTop: 2,
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.cardGap,
  },
  tegelWrap: {
    flexBasis: '48%',
    flexGrow: 1,
  },
  // Rustige witte kaart met een haarlijn eromheen in plaats van een schaduw:
  // dat leest strakker in een raster (feedback Jelle 11-08).
  tegel: {
    backgroundColor: colors.white,
    borderRadius: radius.tile,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: colors.line,
    overflow: 'hidden',
  },
  tegelBeeld: {
    height: 104,
    backgroundColor: colors.surfaceAlt,
  },
  tegelFoto: {
    width: '100%',
    height: '100%',
  },
  aanbiederRing: {
    position: 'absolute',
    left: spacing.md,
    bottom: -17,
    borderRadius: 21,
    borderWidth: 2,
    borderColor: colors.white,
    backgroundColor: colors.white,
  },
  tegelTekst: {
    paddingHorizontal: spacing.md,
    paddingTop: spacing.lg,
    paddingBottom: spacing.md,
  },
  tegelNaam: {
    fontSize: 16,
  },
  tegelAanbieder: {
    marginTop: 1,
  },
  tegelVoet: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: spacing.sm,
    paddingTop: spacing.sm,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: colors.line,
  },
  tegelPrijs: {
    color: colors.ink,
  },
  beoordeling: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
  },
  beoordelingTekst: {
    color: colors.inkSoft,
  },
});

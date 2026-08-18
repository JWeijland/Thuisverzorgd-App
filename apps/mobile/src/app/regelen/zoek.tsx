import { router } from 'expo-router';
import { Pressable, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { BookOpenCheck, ChevronRight, MessagesSquare, Search, X } from 'lucide-react-native';

import { WegwijzerLijst } from '@/features/wegwijzer/WegwijzerLijst';
import { t } from '@/i18n';
import { haptics } from '@/lib/haptics';
import { useStatusBalk } from '@/lib/statusbalk';
import { colors, radius, spacing } from '@/theme';
import { Card, TvzText } from '@/ui';

/**
 * De zoek-popup van de hulp-pagina (wens Jelle 17-08): het hele info-gedeelte
 * zit achter het vergrootglas rechtsboven. Je stelt hier je vraag, de AI
 * antwoordt uitsluitend op basis van onze eigen kennisbank (officiële
 * bronnen, altijd met verwijzingen), en onder het antwoord kun je doorlezen
 * in de relevante onderwerpen. Kom je er niet uit: de verwijzing naar de
 * mantelzorgmakelaar staat er direct bij.
 *
 * Technisch een modale route (geen RN-Modal): zo kan een bronvermelding
 * gewoon het artikel bovenop deze popup openen.
 */
export default function ZoekPopup() {
  useStatusBalk('donker');

  const kop = (
    <View style={styles.kop}>
      {/* Kleine beschrijving: wat dit is en waarom je het kunt vertrouwen. */}
      <View style={styles.uitlegRij}>
        <View style={styles.uitlegIcoon}>
          <BookOpenCheck color={colors.primaryMid} size={20} strokeWidth={2.2} />
        </View>
        <TvzText preset="secondary" style={styles.uitlegTekst}>
          {t('zoekPopup.uitleg')}
        </TvzText>
      </View>

      {/* Liever een mens: rechtstreeks naar de mantelzorgmakelaar-voorziening. */}
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={t('zoekPopup.makelaarKnop')}
        onPress={() => {
          void haptics.tik();
          router.push('/regelen/makelaar');
        }}
      >
        <Card style={styles.makelaarKaart}>
          <View style={styles.makelaarIcoon}>
            <MessagesSquare color={colors.primaryMid} size={18} strokeWidth={2.2} />
          </View>
          <View style={styles.makelaarTekst}>
            <TvzText preset="bodyBold">{t('zoekPopup.makelaarTitel')}</TvzText>
            <TvzText preset="meta" style={styles.makelaarSub}>
              {t('zoekPopup.makelaarSub')}
            </TvzText>
          </View>
          <ChevronRight color={colors.inkFaint} size={18} strokeWidth={2.2} />
        </Card>
      </Pressable>
    </View>
  );

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <View style={styles.titelRij}>
        <View style={styles.titelIcoon}>
          <Search color={colors.primaryMid} size={20} strokeWidth={2.4} />
        </View>
        <View style={styles.titelTekst}>
          <TvzText preset="screenTitle" style={styles.titel}>
            {t('zoekPopup.titel')}
          </TvzText>
          <TvzText preset="secondary">{t('zoekPopup.sub')}</TvzText>
        </View>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('algemeen.sluiten')}
          onPress={() => {
            void haptics.tik();
            // Via een melding kun je hier direct binnenkomen; dan is er geen
            // terugstapel en val je terug op de hulp-pagina.
            if (router.canGoBack()) router.back();
            else router.replace('/regelen/voorzieningen');
          }}
          style={styles.sluiten}
        >
          <X color={colors.inkSoft} size={20} strokeWidth={2.4} />
        </Pressable>
      </View>

      {/* De zoekbalk groot en bovenaan, toetsenbord meteen open: je komt
          hier om je vraag te typen (wens Jelle 18-08). */}
      <WegwijzerLijst kop={kop} prominent />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  titelRij: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    paddingHorizontal: spacing.screen,
    paddingTop: spacing.lg,
    paddingBottom: spacing.sm,
  },
  titelIcoon: {
    width: 42,
    height: 42,
    borderRadius: 21,
    backgroundColor: colors.tintBlue,
    alignItems: 'center',
    justifyContent: 'center',
  },
  titelTekst: {
    flex: 1,
  },
  titel: {
    fontSize: 22,
  },
  sluiten: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center',
    justifyContent: 'center',
  },
  kop: {
    gap: spacing.cardGap,
    marginBottom: spacing.md,
  },
  uitlegRij: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: spacing.md,
    backgroundColor: colors.heroBlue,
    borderRadius: radius.card,
    padding: spacing.md,
  },
  uitlegIcoon: {
    width: 34,
    height: 34,
    borderRadius: 17,
    backgroundColor: colors.white,
    alignItems: 'center',
    justifyContent: 'center',
  },
  uitlegTekst: {
    flex: 1,
  },
  makelaarKaart: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
    paddingVertical: spacing.md,
    borderWidth: 1.5,
    borderColor: colors.tintBlue,
  },
  makelaarIcoon: {
    width: 36,
    height: 36,
    borderRadius: radius.tile,
    backgroundColor: colors.tintBlue,
    alignItems: 'center',
    justifyContent: 'center',
  },
  makelaarTekst: {
    flex: 1,
  },
  makelaarSub: {
    color: colors.inkSoft,
    marginTop: 1,
  },
});

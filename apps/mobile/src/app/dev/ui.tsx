import { LinearGradient } from 'expo-linear-gradient';
import { useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { colors, gradient, radius, spacing, useTextScale } from '@/theme';
import {
  Avatar,
  BottomSheet,
  Button,
  Card,
  Chip,
  Coachmark,
  EmptyState,
  Pill,
  PulseDot,
  SectionHeader,
  StatusPill,
  Toggle,
  TvzBounce,
  TvzText,
} from '@/ui';

/**
 * Dev-only overzicht van alle primitives, om het designsysteem in één blik
 * te controleren tegen docs/design/. Niet gelinkt vanuit de productie-flows.
 */
export default function DevUiScreen() {
  const [chipIndex, setChipIndex] = useState(0);
  const [toggleOn, setToggleOn] = useState(true);
  const [sheetOpen, setSheetOpen] = useState(false);
  const { largeText, setLargeText } = useTextScale();

  return (
    <SafeAreaView style={styles.safe} edges={['top']}>
      <ScrollView contentContainerStyle={styles.container}>
        <TvzText preset="screenTitle">Designsysteem</TvzText>
        <TvzText preset="secondary">
          Alle primitives uit Fase 2, met de tokens uit docs/design/README.md.
        </TvzText>

        <SectionHeader title="Gradient-header" />
        <LinearGradient {...gradient} style={styles.gradientSample}>
          <TvzText preset="cardTitle" style={styles.onDark}>
            Kring van mevrouw Jansen
          </TvzText>
          <TvzText preset="secondary" style={styles.onDarkSoft}>
            8 leden · jij bent beheerder
          </TvzText>
        </LinearGradient>

        <SectionHeader title="Knoppen" />
        <View style={styles.stack}>
          <Button label="Zet in het rooster" variant="cta" size="lg" />
          <Button label="Start videokennismaking" variant="primary" />
          <Button label="Later misschien" variant="outline" />
          <Button label="Uitloggen" variant="danger" />
          <Button label="De app in →" variant="cta" disabled />
        </View>

        <SectionHeader title="Chips & pillen" actionLabel="Actie →" />
        <View style={styles.row}>
          {['Alles', 'Wonen', 'Werk', 'Financiën'].map((label, i) => (
            <Chip
              key={label}
              label={label}
              selected={i === chipIndex}
              onPress={() => setChipIndex(i)}
            />
          ))}
        </View>
        <View style={[styles.row, { marginTop: spacing.md }]}>
          <StatusPill label="Actief" kind="success" />
          <StatusPill label="Uitgenodigd" kind="warn" />
          <StatusPill label="Afgewezen" kind="error" />
          <StatusPill label="Kijkt mee" kind="info" />
          <Pill
            label="Hulpmakelaar"
            color={colors.successText}
            backgroundColor={colors.successBg}
          />
        </View>

        <SectionHeader title="Kaarten" />
        <Card>
          <View style={styles.cardRow}>
            <Avatar name="Anna de Wit" />
            <View style={styles.cardText}>
              <TvzText preset="cardTitle">Anna de Wit</TvzText>
              <TvzText preset="secondary">Buddy · komt vandaag om 14:00</TvzText>
            </View>
            <PulseDot />
          </View>
        </Card>
        <Card dashed style={styles.dashedCard}>
          <TvzText preset="cardTitle" style={styles.center}>
            TVZ-4Q7B
          </TvzText>
          <TvzText preset="secondary" style={styles.center}>
            Koppelcode voor de hulpvrager
          </TvzText>
        </Card>

        <SectionHeader title="Chat" />
        <View style={[styles.bubble, styles.bubbleOwn]}>
          <TvzText>Zou iemand donderdag de boodschappen kunnen doen?</TvzText>
        </View>
        <View style={[styles.bubble, styles.bubbleOther]}>
          <TvzText>Ik kom eraan! 😊</TvzText>
        </View>

        <SectionHeader title="Schakelaars" />
        <Card>
          <View style={styles.toggleRow}>
            <TvzText>Even afwezig</TvzText>
            <Toggle
              value={toggleOn}
              onValueChange={setToggleOn}
              accessibilityLabel="Even afwezig"
            />
          </View>
          <View style={[styles.toggleRow, { marginTop: spacing.md }]}>
            <TvzText>Grotere letters (ouderen-modus)</TvzText>
            <Toggle
              value={largeText}
              onValueChange={setLargeText}
              accessibilityLabel="Grotere letters"
            />
          </View>
        </Card>

        <SectionHeader title="Coachmark" />
        <Coachmark
          title="Plan hier taken in!"
          body="Met de groene knop zet je in drie tikken een taak in het rooster. Je kring ziet hem direct en neemt hem aan."
          step={1}
          totalSteps={4}
          onNext={() => {}}
          onSkip={() => {}}
          arrow="down"
        />

        <SectionHeader title="Lege staat & animatie" />
        <Card>
          <EmptyState title="Nog geen hulpvragen" body="De pillen zoeken elkaar nog even." />
          <View style={styles.bounceRow}>
            <TvzBounce>
              <View style={[styles.logoBar, { backgroundColor: colors.primaryMid }]} />
            </TvzBounce>
            <TvzBounce delay={200}>
              <View style={[styles.logoBar, { backgroundColor: colors.accent }]} />
            </TvzBounce>
          </View>
        </Card>

        <SectionHeader title="Bottom sheet" />
        <Button label="Open bottom sheet" variant="outline" onPress={() => setSheetOpen(true)} />

        <BottomSheet visible={sheetOpen} onClose={() => setSheetOpen(false)} title="Directe hulp">
          <TvzText preset="secondary">
            Nu even hulp nodig, buiten het rooster om? Buddy&apos;s in de buurt krijgen direct een
            melding.
          </TvzText>
          <Button
            label="Zet op de kaart"
            variant="cta"
            size="lg"
            style={{ marginTop: spacing.lg }}
            onPress={() => setSheetOpen(false)}
          />
        </BottomSheet>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: {
    flex: 1,
    backgroundColor: colors.bg,
  },
  container: {
    padding: spacing.screen,
    paddingBottom: 64,
  },
  gradientSample: {
    borderRadius: radius.card,
    padding: spacing.cardPadding,
  },
  onDark: {
    color: colors.white,
  },
  onDarkSoft: {
    color: 'rgba(255,255,255,0.8)',
  },
  stack: {
    gap: spacing.cardGap,
  },
  row: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.chipGap,
    alignItems: 'center',
  },
  cardRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  cardText: {
    flex: 1,
  },
  dashedCard: {
    marginTop: spacing.cardGap,
    alignItems: 'center',
  },
  center: {
    textAlign: 'center',
  },
  bubble: {
    maxWidth: '80%',
    padding: spacing.md,
  },
  bubbleOwn: {
    alignSelf: 'flex-end',
    backgroundColor: colors.chatOwn,
    borderTopLeftRadius: radius.bubble,
    borderTopRightRadius: radius.bubble,
    borderBottomRightRadius: radius.bubbleTail,
    borderBottomLeftRadius: radius.bubble,
  },
  bubbleOther: {
    alignSelf: 'flex-start',
    backgroundColor: colors.chatOther,
    borderTopLeftRadius: radius.bubble,
    borderTopRightRadius: radius.bubble,
    borderBottomRightRadius: radius.bubble,
    borderBottomLeftRadius: radius.bubbleTail,
    marginTop: spacing.sm,
  },
  toggleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  bounceRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 6,
    paddingBottom: spacing.md,
  },
  logoBar: {
    width: 30,
    height: 14,
    borderRadius: radius.pill,
  },
});

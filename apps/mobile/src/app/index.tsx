import { Link } from 'expo-router';
import { StyleSheet, Text, View } from 'react-native';

// Tijdelijk startscherm — wordt in Fase 4 vervangen door de echte welkomflow.
// De kleuren komen uit de handoff (primaryDark/accent); het volledige
// designsysteem (theme.ts + primitives) volgt in Fase 2.
export default function Index() {
  return (
    <View style={styles.container}>
      <View style={styles.logoRow}>
        <View style={[styles.bar, styles.barBlue]} />
        <View style={[styles.bar, styles.barGreen]} />
      </View>
      <View style={styles.stem} />
      <Text style={styles.wordmark}>thuisverzorgd</Text>
      <Text style={styles.tagline}>Hulp dichtbij, geregeld door de buurt</Text>
      <Link href="/dev/ui" style={styles.devLink}>
        <Text style={styles.devLinkText}>Bekijk designsysteem (dev)</Text>
      </Link>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#112F50',
    alignItems: 'center',
    justifyContent: 'center',
  },
  logoRow: {
    flexDirection: 'row',
    gap: 6,
  },
  bar: {
    width: 34,
    height: 16,
    borderRadius: 999,
  },
  barBlue: {
    backgroundColor: '#2A6CB0',
  },
  barGreen: {
    backgroundColor: '#8DC93F',
  },
  stem: {
    width: 16,
    height: 40,
    borderRadius: 999,
    backgroundColor: '#FFFFFF',
    marginTop: 4,
  },
  wordmark: {
    color: '#FFFFFF',
    fontSize: 28,
    fontWeight: '700',
    marginTop: 20,
  },
  tagline: {
    color: '#FFFFFF',
    opacity: 0.85,
    fontSize: 15,
    marginTop: 8,
  },
  devLink: {
    marginTop: 40,
  },
  devLinkText: {
    color: '#8DC93F',
    fontSize: 14,
    textDecorationLine: 'underline',
  },
});

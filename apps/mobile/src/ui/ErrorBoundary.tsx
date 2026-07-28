import { Component, type ReactNode } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { colors, radius, spacing } from '@/theme';

type Props = { children: ReactNode };
type State = { error: Error | null; stack: string | null };

/**
 * Vangnet: een onverwachte fout wordt een leesbaar scherm met de foutmelding
 * in plaats van een dichtklappende app. Bewust zonder theme-componenten,
 * zodat het ook werkt als juist dáár iets misgaat.
 */
export class ErrorBoundary extends Component<Props, State> {
  state: State = { error: null, stack: null };

  static getDerivedStateFromError(error: Error): State {
    return { error, stack: null };
  }

  componentDidCatch(_error: Error, info: { componentStack?: string | null }) {
    // Bovenste componenten uit de stack: genoeg om de boosdoener aan te wijzen.
    const lines = (info.componentStack ?? '')
      .split('\n')
      .map((line) => line.trim())
      .filter(Boolean)
      .slice(0, 6)
      .join('\n');
    this.setState({ stack: lines });
  }

  render() {
    if (!this.state.error) {
      return this.props.children;
    }
    return (
      <View style={styles.container}>
        <Text style={styles.title}>Er ging iets mis</Text>
        <Text style={styles.detail}>{this.state.error.message}</Text>
        {this.state.stack ? <Text style={styles.stack}>{this.state.stack}</Text> : null}
        <Pressable
          accessibilityRole="button"
          onPress={() => this.setState({ error: null, stack: null })}
          style={styles.button}
        >
          <Text style={styles.buttonText}>Probeer opnieuw</Text>
        </Pressable>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.primaryDark,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing.xxl,
  },
  title: {
    color: colors.white,
    fontSize: 22,
    fontWeight: '700',
    marginBottom: spacing.md,
  },
  detail: {
    color: 'rgba(255,255,255,0.8)',
    fontSize: 14,
    textAlign: 'center',
    marginBottom: spacing.md,
  },
  stack: {
    color: 'rgba(255,255,255,0.55)',
    fontSize: 11,
    textAlign: 'center',
    marginBottom: spacing.xl,
  },
  button: {
    backgroundColor: colors.accent,
    borderRadius: radius.pill,
    paddingHorizontal: 28,
    paddingVertical: 14,
    minHeight: 48,
  },
  buttonText: {
    color: colors.primaryDark,
    fontSize: 16,
    fontWeight: '700',
  },
});

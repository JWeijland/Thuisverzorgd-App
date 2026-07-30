import { Pressable, StyleSheet, Text, View, useWindowDimensions } from 'react-native';
import {
  Calendar,
  MapPin,
  MessagesSquare,
  User,
  Users,
  type LucideIcon,
} from 'lucide-react-native';

import { t } from '@/i18n';
import { colors, radius, shadows, tabBar } from '@/theme';
import { fonts } from '@/theme/typography';

const ICONS: Record<string, LucideIcon> = {
  rooster: Calendar,
  buurt: MapPin,
  kring: Users,
  steun: MessagesSquare,
  profiel: User,
};

export const TAB_ORDER = ['rooster', 'buurt', 'kring', 'steun', 'profiel'] as const;

/**
 * Zichtbare tabs per rol. De vrijwilliger heeft geen aparte kring-tab: zijn
 * kring (leden + berichten) zit in de kop van de planning-tab (feedback 30-07).
 */
export function visibleTabs(role: string | null | undefined): string[] {
  // Vrijwilliger én beheerder hebben hun kring in de kop van de planning-tab.
  if (role === 'vrijwilliger' || role === 'beheerder') {
    return ['rooster', 'buurt', 'steun', 'profiel'];
  }
  return [...TAB_ORDER];
}

// Minimale typing van de tab-bar-props die expo-router (react-navigation) aanlevert;
// het pakket @react-navigation/bottom-tabs is bewust geen directe dependency.
type TabBarProps = {
  state: { index: number; routes: { key: string; name: string }[] };
  navigation: {
    emit: (event: { type: 'tabPress'; target: string; canPreventDefault: true }) => {
      defaultPrevented: boolean;
    };
    navigate: (name: string) => void;
  };
  /** Tabnamen die deze rol niet ziet. */
  hidden?: string[];
};

/** Zwevende witte pill-tabbalk: tabs × 64 met korte naam, actief = navy pill. */
export function TvzTabBar({ state, navigation, hidden = [] }: TabBarProps) {
  const routes = state.routes.filter((route) => !hidden.includes(route.name));
  return (
    <View pointerEvents="box-none" style={styles.wrap}>
      <View style={[styles.bar, shadows.floating]}>
        {routes.map((route) => {
          const Icon = ICONS[route.name] ?? User;
          const active = state.routes[state.index]?.name === route.name;
          const label = t(`tabs.${route.name}`);
          return (
            <Pressable
              key={route.key}
              accessibilityRole="tab"
              accessibilityState={{ selected: active }}
              accessibilityLabel={label}
              onPress={() => {
                const event = navigation.emit({
                  type: 'tabPress',
                  target: route.key,
                  canPreventDefault: true,
                });
                if (!active && !event.defaultPrevented) {
                  navigation.navigate(route.name);
                }
              }}
              style={[styles.tab, active && styles.tabActive]}
            >
              <Icon color={active ? colors.white : colors.inkSoft} size={20} strokeWidth={2.2} />
              <Text
                numberOfLines={1}
                style={[styles.label, { color: active ? colors.white : colors.inkSoft }]}
              >
                {label}
              </Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

/**
 * Horizontale middenpositie van tab `index`, voor het rondleiding-pijltje.
 * `tabCount` is het aantal zichtbare tabs (rolafhankelijk).
 */
export function tabCenterX(
  index: number,
  windowWidth: number,
  tabCount: number = TAB_ORDER.length,
): number {
  const barWidth = tabCount * tabBar.tabWidth + tabBar.padding * 2;
  const left = (windowWidth - barWidth) / 2;
  return left + tabBar.padding + index * tabBar.tabWidth + tabBar.tabWidth / 2;
}

export function useTabCenterX(index: number, tabCount?: number): number {
  const { width } = useWindowDimensions();
  return tabCenterX(index, width, tabCount);
}

const styles = StyleSheet.create({
  wrap: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: tabBar.bottomOffset,
    alignItems: 'center',
  },
  bar: {
    flexDirection: 'row',
    backgroundColor: colors.white,
    borderRadius: radius.pill,
    padding: tabBar.padding,
  },
  tab: {
    width: tabBar.tabWidth,
    height: 54,
    borderRadius: radius.pill,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 2,
  },
  tabActive: {
    backgroundColor: colors.primary,
  },
  label: {
    fontFamily: fonts.heading,
    fontSize: 10,
  },
});

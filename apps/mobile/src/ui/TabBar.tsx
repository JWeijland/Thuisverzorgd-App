import { Pressable, StyleSheet, Text, View, useWindowDimensions } from 'react-native';

import { haptics } from '@/lib/haptics';
import {
  BookOpen,
  Calendar,
  CirclePlus,
  Heart,
  MapPin,
  MessagesSquare,
  Store,
  Sun,
  User,
  Users,
  type LucideIcon,
} from 'lucide-react-native';

import { t } from '@/i18n';
import { colors, radius, shadows, tabBar } from '@/theme';
import { fonts } from '@/theme/typography';

export const TAB_ORDER = ['rooster', 'voorzien', 'buurt', 'kring', 'steun', 'profiel'] as const;

type TabName = (typeof TAB_ORDER)[number];

type TabConfig = { name: TabName; labelKey: string; icon: LucideIcon };

/**
 * Tabbalk per rol (ontwerp 4.0): de volgorde volgt de drie lagen
 * (1 Steun · 2 Kring en Buurt · 3 Voorzien) en de labels zeggen wat de tab
 * voor déze rol is. Dezelfde fysieke routes, drie verschillende apps:
 * de beheerder start op Steun, de buddy leeft in zijn Taken en de
 * hulpvrager ziet Vandaag.
 */
const ROL_TABS: Record<string, TabConfig[]> = {
  beheerder: [
    { name: 'steun', labelKey: 'tabs.steun', icon: Heart },
    { name: 'rooster', labelKey: 'tabs.kring', icon: Users },
    { name: 'buurt', labelKey: 'tabs.buurt', icon: MapPin },
    { name: 'voorzien', labelKey: 'tabs.voorzien', icon: Store },
    { name: 'profiel', labelKey: 'tabs.profiel', icon: User },
  ],
  vrijwilliger: [
    { name: 'rooster', labelKey: 'tabs.taken', icon: Calendar },
    { name: 'buurt', labelKey: 'tabs.buurt', icon: MapPin },
    { name: 'steun', labelKey: 'tabs.leren', icon: BookOpen },
    { name: 'profiel', labelKey: 'tabs.profiel', icon: User },
  ],
  hulpvrager: [
    { name: 'rooster', labelKey: 'tabs.vandaag', icon: Sun },
    { name: 'voorzien', labelKey: 'tabs.hulp', icon: CirclePlus },
    { name: 'steun', labelKey: 'tabs.steun', icon: Heart },
    { name: 'kring', labelKey: 'tabs.kring', icon: Users },
  ],
};

/** Zonder (bekende) rol: alle tabs in de oude volgorde, neutrale labels. */
const STANDAARD_TABS: TabConfig[] = [
  { name: 'rooster', labelKey: 'tabs.rooster', icon: Calendar },
  { name: 'voorzien', labelKey: 'tabs.voorzien', icon: Store },
  { name: 'buurt', labelKey: 'tabs.buurt', icon: MapPin },
  { name: 'kring', labelKey: 'tabs.kring', icon: Users },
  { name: 'steun', labelKey: 'tabs.steun', icon: MessagesSquare },
  { name: 'profiel', labelKey: 'tabs.profiel', icon: User },
];

export function tabsVoor(role: string | null | undefined): TabConfig[] {
  return ROL_TABS[role ?? ''] ?? STANDAARD_TABS;
}

/** Zichtbare tabs voor een rol, in de volgorde van de tabbalk. */
export function visibleTabs(role: string | null | undefined): string[] {
  return tabsVoor(role).map((tab) => tab.name);
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
  /** Rol van de ingelogde gebruiker; bepaalt volgorde, labels en iconen. */
  role?: string | null;
};

/** Zwevende witte pill-tabbalk: tabs × 64 met korte naam, actief = navy pill. */
export function TvzTabBar({ state, navigation, role }: TabBarProps) {
  const tabs = tabsVoor(role);
  const activeName = state.routes[state.index]?.name;
  return (
    <View pointerEvents="box-none" style={styles.wrap}>
      <View style={[styles.bar, shadows.floating]}>
        {tabs.map(({ name, labelKey, icon: Icon }) => {
          const route = state.routes.find((r) => r.name === name);
          if (!route) return null;
          const active = activeName === name;
          const label = t(labelKey);
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
                  void haptics.selectie();
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

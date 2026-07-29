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
};

/** Zwevende witte pill-tabbalk: 5 tabs × 64 met korte naam, actief = navy pill. */
export function TvzTabBar({ state, navigation }: TabBarProps) {
  return (
    <View pointerEvents="box-none" style={styles.wrap}>
      <View style={[styles.bar, shadows.floating]}>
        {state.routes.map((route, index) => {
          const Icon = ICONS[route.name] ?? User;
          const active = state.index === index;
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

/** Horizontale middenpositie van tab `index`, voor het rondleiding-pijltje. */
export function tabCenterX(index: number, windowWidth: number): number {
  const barWidth = TAB_ORDER.length * tabBar.tabWidth + tabBar.padding * 2;
  const left = (windowWidth - barWidth) / 2;
  return left + tabBar.padding + index * tabBar.tabWidth + tabBar.tabWidth / 2;
}

export function useTabCenterX(index: number): number {
  const { width } = useWindowDimensions();
  return tabCenterX(index, width);
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

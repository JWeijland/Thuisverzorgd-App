import type { ConfigContext, ExpoConfig } from 'expo/config';

export default ({ config }: ConfigContext): ExpoConfig => ({
  ...config,
  name: 'Thuisverzorgd',
  slug: 'thuisverzorgd',
  owner: 'jelleweijlands-team',
  version: '0.1.0',
  orientation: 'portrait',
  icon: './assets/images/icon.png',
  scheme: 'tvz',
  userInterfaceStyle: 'light',
  ios: {
    bundleIdentifier: 'nl.thuisverzorgd.app',
    supportsTablet: false,
    icon: './assets/expo.icon',
  },
  android: {
    package: 'nl.thuisverzorgd.app',
    adaptiveIcon: {
      backgroundColor: '#112F50',
      foregroundImage: './assets/images/android-icon-foreground.png',
      backgroundImage: './assets/images/android-icon-background.png',
      monochromeImage: './assets/images/android-icon-monochrome.png',
    },
    predictiveBackGestureEnabled: false,
  },
  web: {
    output: 'static',
    favicon: './assets/images/favicon.png',
  },
  plugins: [
    'expo-router',
    [
      'expo-splash-screen',
      {
        backgroundColor: '#112F50',
        image: './assets/images/splash-icon.png',
        imageWidth: 76,
      },
    ],
  ],
  experiments: {
    typedRoutes: true,
    reactCompiler: true,
  },
  extra: {
    eas: {
      projectId: 'fe37e87d-93d5-47bf-8414-2709177f8a0b',
    },
  },
});

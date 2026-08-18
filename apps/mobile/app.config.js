// Bewust JavaScript (geen .ts): de configlader van eas-cli struikelt over TypeScript 6.
module.exports = ({ config }) => ({
  ...config,
  name: 'Thuisverzorgd',
  slug: 'thuisverzorgd',
  owner: 'jelleweijlands-team',
  // 0.2.0: kaartlaag gewisseld naar MapLibre (native wijziging; runtime volgt
  // deze versie, zodat oude installs geen onverenigbare JS-updates krijgen).
  version: '0.2.0',
  orientation: 'portrait',
  icon: './assets/images/icon.png',
  scheme: 'tvz',
  userInterfaceStyle: 'light',
  ios: {
    bundleIdentifier: 'nl.thuisverzorgd.app',
    supportsTablet: false,
    infoPlist: {
      // Alleen standaard HTTPS-encryptie; scheelt een exportvraag per TestFlight-build.
      ITSAppUsesNonExemptEncryption: false,
    },
  },
  android: {
    package: 'nl.thuisverzorgd.app',
    adaptiveIcon: {
      // Linnenwit (huisstijl v4): dezelfde warme achtergrond als het icoon.
      backgroundColor: '#FCF8F6',
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
    '@maplibre/maplibre-react-native',
    [
      'expo-splash-screen',
      {
        backgroundColor: '#FCF8F6',
        image: './assets/images/splash-icon.png',
        imageWidth: 76,
      },
    ],
    [
      'expo-location',
      {
        locationWhenInUsePermission:
          'Thuisverzorgd gebruikt je locatie om hulpkringen en hulpvragen bij jou in de buurt te tonen.',
      },
    ],
    [
      'expo-image-picker',
      {
        photosPermission:
          'Thuisverzorgd gebruikt je fotobibliotheek voor je profielfoto en de eenmalige ID-check.',
        cameraPermission:
          'Thuisverzorgd gebruikt je camera om ter plekke een profielfoto of ID-foto te maken.',
      },
    ],
  ],
  experiments: {
    typedRoutes: true,
    // React Compiler uit: de experimentele compiler evalueerde closure-afhankelijkheden
    // (completing!.id) al tijdens het renderen en crashte productiebuilds.
    reactCompiler: false,
  },
  updates: {
    url: 'https://u.expo.dev/fe37e87d-93d5-47bf-8414-2709177f8a0b',
  },
  runtimeVersion: {
    policy: 'appVersion',
  },
  extra: {
    eas: {
      projectId: 'fe37e87d-93d5-47bf-8414-2709177f8a0b',
    },
  },
});

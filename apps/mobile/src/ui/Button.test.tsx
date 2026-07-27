import { fireEvent, render } from '@testing-library/react-native';

import { Button } from '@/ui/Button';
import { StatusPill } from '@/ui/StatusPill';
import { TvzText } from '@/ui/TvzText';
import { TextScaleProvider } from '@/theme';

describe('Button', () => {
  it('toont het label en reageert op tikken', async () => {
    const onPress = jest.fn();
    const { getByText } = await render(
      <Button label="Zet in het rooster" variant="cta" onPress={onPress} />,
    );
    await fireEvent.press(getByText('Zet in het rooster'));
    expect(onPress).toHaveBeenCalledTimes(1);
  });

  it('reageert niet wanneer disabled', async () => {
    const onPress = jest.fn();
    const { getByText } = await render(<Button label="De app in →" disabled onPress={onPress} />);
    await fireEvent.press(getByText('De app in →'));
    expect(onPress).not.toHaveBeenCalled();
  });
});

describe('StatusPill', () => {
  it.each([
    ['Actief', 'success'],
    ['Uitgenodigd', 'warn'],
    ['Afgewezen', 'error'],
    ['Kijkt mee', 'info'],
  ] as const)('rendert status "%s"', async (label, kind) => {
    const { getByText } = await render(<StatusPill label={label} kind={kind} />);
    expect(getByText(label)).toBeTruthy();
  });
});

describe('TvzText met ouderen-modus', () => {
  it('rendert binnen de TextScaleProvider', async () => {
    const { getByText } = await render(
      <TextScaleProvider>
        <TvzText preset="screenTitle">Goedemorgen, Jelle</TvzText>
      </TextScaleProvider>,
    );
    expect(getByText('Goedemorgen, Jelle')).toBeTruthy();
  });
});

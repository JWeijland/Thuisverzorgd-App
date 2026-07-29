import { useAvatarUrl } from '@/features/avatars/api';
import { Avatar } from '@/ui';

type Props = {
  name: string;
  /** `profiles.avatar_path`; zonder pad (of zolang de URL laadt) de initiaal-cirkel. */
  avatarPath?: string | null;
  size?: number;
  backgroundColor?: string;
};

/** Avatar die zelf de profielfoto uit de privé-bucket ophaalt. */
export function ProfileAvatar({ name, avatarPath, size, backgroundColor }: Props) {
  const url = useAvatarUrl(avatarPath);
  return (
    <Avatar name={name} size={size} uri={url.data ?? undefined} backgroundColor={backgroundColor} />
  );
}

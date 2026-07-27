// Account verwijderen (App Store-eis 5.1.1(v)): verwijdert het auth-account,
// waarna alle data via ON DELETE CASCADE meegaat; ruimt ook de opslag op.
import { createClient } from 'jsr:@supabase/supabase-js@2';

const admin = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

async function removeFolder(bucket: string, folder: string) {
  const { data: files } = await admin.storage.from(bucket).list(folder, { limit: 100 });
  const paths = (files ?? []).map((file) => `${folder}/${file.name}`);
  if (paths.length > 0) {
    await admin.storage.from(bucket).remove(paths);
  }
}

Deno.serve(async (request) => {
  try {
    const token = request.headers.get('Authorization')?.replace('Bearer ', '');
    if (!token) return new Response('geen token', { status: 401 });

    const { data: userData, error } = await admin.auth.getUser(token);
    if (error || !userData.user) return new Response('ongeldig', { status: 401 });
    const uid = userData.user.id;

    await removeFolder('avatars', uid);
    await removeFolder('id-documents', uid);
    const { error: deleteError } = await admin.auth.admin.deleteUser(uid);
    if (deleteError) throw deleteError;

    return new Response('ok', { status: 200 });
  } catch (error) {
    console.error('delete-account', error);
    return new Response('fout', { status: 500 });
  }
});

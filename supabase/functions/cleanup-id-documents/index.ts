// Dagelijkse opruiming: ID-documenten ouder dan 30 dagen worden verwijderd (ADR-0005).
// In de database staat alleen id_verified + timestamp; het document zelf is tijdelijk.
import { createClient } from 'jsr:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const MAX_AGE_MS = 30 * 24 * 60 * 60 * 1000;

Deno.serve(async () => {
  try {
    const bucket = supabase.storage.from('id-documents');
    const { data: folders } = await bucket.list('', { limit: 1000 });
    let removed = 0;

    for (const folder of folders ?? []) {
      // Mappen hebben geen metadata; bestanden op het hoogste niveau wel.
      if (folder.metadata) continue;
      const { data: files } = await bucket.list(folder.name, { limit: 100 });
      const oldPaths = (files ?? [])
        .filter((file) => {
          const created = file.created_at ? new Date(file.created_at).getTime() : 0;
          return created > 0 && Date.now() - created > MAX_AGE_MS;
        })
        .map((file) => `${folder.name}/${file.name}`);
      if (oldPaths.length > 0) {
        await bucket.remove(oldPaths);
        removed += oldPaths.length;
      }
    }

    return new Response(JSON.stringify({ removed }), { status: 200 });
  } catch (error) {
    console.error('cleanup-id-documents', error);
    return new Response('fout', { status: 500 });
  }
});

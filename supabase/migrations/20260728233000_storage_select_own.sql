-- Fix (vervolg): upload-met-upsert doet eerst een bestaat-het-al-check (select).
-- De eigenaar mag zijn eigen ID-map dus wél lezen; anderen nog steeds niet.
create policy "id-documenten eigen map lezen" on storage.objects
  for select
  using (bucket_id = 'id-documents' and (storage.foldername(name))[1] = auth.uid()::text);

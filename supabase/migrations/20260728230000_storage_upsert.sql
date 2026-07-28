-- Fix: opnieuw uploaden van je eigen ID-document (upsert) werd geblokkeerd
-- omdat er alleen een insert-policy bestond. Eigen map mag nu ook
-- overschreven/verwijderd worden; lezen blijft onmogelijk via de client.

create policy "id-documenten overschrijven" on storage.objects
  for update
  using (bucket_id = 'id-documents' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'id-documents' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "id-documenten verwijderen" on storage.objects
  for delete
  using (bucket_id = 'id-documents' and (storage.foldername(name))[1] = auth.uid()::text);

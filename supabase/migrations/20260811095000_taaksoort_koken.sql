-- "Koken of eten" staat als eigen soort taak in de handoff (scherm 06); tot nu
-- toe viel dat onder "anders". Een enum-waarde toevoegen staat bewust in een
-- eigen migratie: je mag hem niet gebruiken in dezelfde transactie waarin je
-- hem aanmaakt.
alter type public.task_type add value if not exists 'koken';

CREATE OR REPLACE PROCEDURE sil.sil_migrate_language_index(
    in pLang VARCHAR(3),
    in pCountry VARCHAR(2),
    in pNameType VARCHAR(2),
    in pName VARCHAR(75)
)
LANGUAGE PLPGSQL
AS $$
DECLARE
  vCommonId varchar(64);
  vPersonId varchar(64);
  vGroupId varchar(64);
BEGIN
  select id from admin.people  where sensitivity_clearance = 'High' into vPersonId;
  SELECT id FROM admin.groups INTO vGroupId WHERE name='Administrators';

  if vPersonId is not null then
    insert into common.languages(created_by, modified_by, owning_person, owning_group)
    values (vPersonId::varchar(32), vPersonId::varchar(32), vPersonId::varchar(32), vGroupId::varchar(32))
    returning id
    into vCommonId;

    insert into sil.language_index(id, lang, country, name_type, name, created_by, modified_by, owning_person, owning_group)
    values (vCommonId::varchar(32), pLang, pCountry, pNameType::sil.language_name_type, pName, vPersonId::varchar(32), vPersonId::varchar(32), vPersonId::varchar(32), vGroupId::varchar(32));

  end if;

END; $$;

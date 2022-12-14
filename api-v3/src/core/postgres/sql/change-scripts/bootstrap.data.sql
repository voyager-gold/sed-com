CREATE OR REPLACE PROCEDURE bootstrap(
  IN p_email VARCHAR(255),
  IN p_password VARCHAR(50),
  inout error_type varchar(32)
)
LANGUAGE PLPGSQL
AS $$
DECLARE
  vPeopleCount int; -- if this is a fresh db or not
  vPersonId varchar(32);
  vOrgId varchar(32);
  vAdminRoleId varchar(32);
  vAdminGroupId varchar(32);
  vNonAdminPersonId varchar(32);
  vPublicPersonId varchar(32);
  vPublicGroupId varchar(32);
  vPublicRoleId varchar(32);
  vTableOfLanguagesId varchar(32);
  vCommonLanguagesId varchar(32);
  vCommonSiteTextStringsId varchar(32);
BEGIN
  select count(id)
  from admin.people
  into vPeopleCount;

  if vPeopleCount = 0 then
    -- people --------------------------------------------------------------------------------

    -- Root user
    insert into admin.people(sensitivity_clearance)
    values ('High')
    returning id
    into vPersonId;

    -- public user
    insert into admin.people(sensitivity_clearance)
    values ('Low')
    returning id
    into vPublicPersonId;

    -- create token for the public 'person'
    insert into admin.tokens(token, admin_people_id) values ('public', vPublicPersonId);

    -- groups -------------------------------------------------------------------------------------

    -- Administrators Group
    insert into admin.groups(name, created_by_admin_people_id, modified_by_admin_people_id, owning_person_admin_people_id)
    values ('Administrators', vPersonId, vPersonId, vPersonId)
    returning id
    into vAdminGroupId;

    -- Public Group
    insert into admin.groups(name, created_by_admin_people_id, modified_by_admin_people_id, owning_person_admin_people_id)
    values ('Public', vPersonId, vPersonId, vPersonId)
    returning id
    into vPublicGroupId;

    -- organization ------------------------------------------------------------------------------------------

    -- Seed Company
    insert into common.organizations(name, sensitivity, created_by_admin_people_id, modified_by_admin_people_id, owning_person_admin_people_id, owning_group_admin_groups_id)
    values ('Seed Company', 'Low', vPersonId, vPersonId, vPersonId, vAdminGroupId)
    returning id
    into vOrgId;

    -- users ----------------------------------------------------------------------------------------------------

    -- Root user
    insert into admin.user_email_accounts(id, email, password, created_by_admin_people_id, modified_by_admin_people_id, owning_person_admin_people_id, owning_group_admin_groups_id)
    values (vPersonId, p_email, p_password, vPersonId, vPersonId, vPersonId, vAdminGroupId);

    -- global roles ----------------------------------------------------------------------------------------------------

    -- Administrator role
    insert into admin.roles(name, created_by_admin_people_id, modified_by_admin_people_id, owning_person_admin_people_id, owning_group_admin_groups_id)
    values ('Administrator', vPersonId, vPersonId, vPersonId, vAdminGroupId)
    returning id
    into vAdminRoleId;

    -- Public role
    insert into admin.roles(name, created_by_admin_people_id, modified_by_admin_people_id, owning_person_admin_people_id, owning_group_admin_groups_id)
    values ('Public', vPersonId, vPersonId, vPersonId, vAdminGroupId)
    returning id
    into vPublicRoleId;

    -- global role memberships ------------------------------------------------------------------------------------------

    -- Give Root user the Administrator role
    insert into admin.role_memberships(admin_role_id, admin_people_id, created_by_admin_people_id, modified_by_admin_people_id, owning_person_admin_people_id, owning_group_admin_groups_id) values
    (vAdminRoleId, vPersonId, vPersonId, vPersonId, vPersonId, vAdminGroupId);

    -- role table grants ------------------------------------------------------------------------------------------

    -- group memberships ----------------------------------------------------------------------------------------------------
    insert into admin.group_memberships(admin_groups_id, admin_people_id, created_by_admin_people_id, modified_by_admin_people_id, owning_person_admin_people_id, owning_group_admin_groups_id)
    values (vAdminGroupId, vPersonId, vPersonId, vPersonId, vPersonId, vAdminGroupId);

  end if;

END; $$;

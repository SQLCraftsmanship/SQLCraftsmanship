
-----------------------------------------------------------------------------------------
-- Ref.
-- https://itectec.com/database/postgresql-drop-role-postgresql/
-----------------------------------------------------------------------------------------

-- To DROP user
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM usrbi;
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM usrbi;
REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public FROM usrbi;

DROP USER usrbi;

REVOKE ALL PRIVILEGES ON DATABASE "DM" FROM usrbi;
REVOKE ALL PRIVILEGES ON SCHEMA schdm FROM usrbi;

REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA schdm FROM usrbi;
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA schdm FROM usrbi;
REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA schdm FROM usrbi;
REVOKE ALL PRIVILEGES ON SCHEMA schdm FROM usrbi;

ALTER DEFAULT PRIVILEGES IN SCHEMA schdm REVOKE ALL ON SEQUENCES FROM usrbi;
ALTER DEFAULT PRIVILEGES IN SCHEMA schdm REVOKE ALL ON TABLES FROM usrbi;
ALTER DEFAULT PRIVILEGES IN SCHEMA schdm REVOKE ALL ON FUNCTIONS FROM usrbi;

REVOKE USAGE ON SCHEMA schdm FROM usrbi;


GRANT EXECUTE ON MATERIALIZED VIEW schdgips."VISTA_LOYS_ROLES" TO usredubin;
GRANT SELECT ON MATERIALIZED VIEW ON SCHEMA schdgips TO ROLE usredubin;

grant select on schdgips."VISTA_RCPC_ROLES" to "usredubin";
grant select on schdgips."VISTA_ENTES_ROLES" to "usredubin";
grant select on schdgips."VISTA_LOYS_CONCEPTOS" to "usredubin";
grant select on schdgips."VISTA_RCPC_CONCEPTOS" to "usredubin";

-----------------------------------------------------------------------------------

SELECT 'GRANT SELECT ON ' || quote_ident(schemaname) || '.' || quote_ident(viewname) || ' TO usredubin;'
FROM pg_views
WHERE schemaname = 'schdgips';

	GRANT SELECT ON schdgips."SIRHU_ORGANISMOS_VIGENTES" TO usredubin;
	GRANT SELECT ON schdgips."CFU_ORGANISMOS_VIGENTES" TO usredubin;
	GRANT SELECT ON schdgips."CFU_ORGANISMOS_VIGENTES" TO usredubin;
	GRANT SELECT ON schdgips."VISTA_DM_ROLES" TO usredubin;
	GRANT SELECT ON schdgips."VISTA_DM_ROLES_TEMP" TO usredubin;
	GRANT SELECT ON schdgips."VISTA_ENTES_ROLES" TO usredubin;
	GRANT SELECT ON schdgips."VISTA_LOYS_CONCEPTOS" TO usredubin;
	GRANT SELECT ON schdgips."VISTA_LOYS_ROLES" TO usredubin;
	GRANT SELECT ON schdgips."VISTA_RCPC_CONCEPTOS" TO usredubin;
	GRANT SELECT ON schdgips."VISTA_RCPC_ROLES" TO usredubin;
	GRANT SELECT ON schdgips."VISTA_BIEP_ROLES" TO aroust;

GRANT SELECT ON ALL TABLES IN SCHEMA schdgips TO aroust;
GRANT SELECT ON ALL TABLES IN SCHEMA schdm TO aroust;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO user;
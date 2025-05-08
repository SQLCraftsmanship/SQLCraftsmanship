
SESSION_USER is the role name of the role that is connected to the database.
CURRENT_USER is the role name of the role that has been explicitly set by a SET ROLE statement.

You can always query the system catalog to get information about the existing roles. Every role has a unique name and also an OID value, 
which represents the role as a numerical value. Many of the role properties have a Boolean value, where 'f' means false (that is, 
NO-option) and 't' means true (that is, with-option).

    SELECT * FROM pg_authid WHERE rolname = 'luca';

There is another possible catalog, named pg_roles, which displays the very same information about pg_authid
    
    SELECT * FROM pg_roles WHERE rolname = 'luca';

Why two similar views of the same data? In order to query pg_authid, you must be a cluster superuser, while every user can query 
pg_roles since there is no hint regarding the role password.

What about group membership? You can query the special pg_auth_members catalog to get information about what roles are members of what 
other roles. As an example, the following query provides a list of groups:

    SELECT 
        r.rolname, g.rolname AS group,
        m.admin_option AS is_admin
    FROM pg_auth_members m
    JOIN pg_roles r ON r.oid = m.member
    JOIN pg_roles g ON g.oid = m.roleid
    ORDER BY r.rolname;


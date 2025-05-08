
USE [master]
GO

with objects_cte as
(
    select
        o.name,
        o.type_desc,
        case
            when o.principal_id is null then s.principal_id
            else o.principal_id
        end as principal_id
    from sys.objects o
    inner join sys.schemas s
    on o.schema_id = s.schema_id
    where o.is_ms_shipped = 0
    and o.type in ('U', 'FN', 'FS', 'FT', 'IF', 'P', 'PC', 'TA', 'TF', 'TR', 'V')
)
select
    cte.name,
    cte.type_desc,
    dp.name
from objects_cte cte
inner join sys.database_principals dp
on cte.principal_id = dp.principal_id
where dp.name = 'CodereSN2';

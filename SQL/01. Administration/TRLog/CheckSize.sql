with
    [BaseData] as (
        select
            [DF].[type_desc]                            as [Type],
            [DF].[name]                                 as [FileName],
            [DF].[size] / 131072.0                      as [TotalSpaceInGB],
            [UP].[size] / 131072.0                      as [UsedSpaceInGB],
            ([DF].[size] - [UP].[size]) / 131072.0      as [FreeSpaceInGB],
            [DF].[max_size]                             as [MaxSize]
        from [sys].[database_files] as [DF]
            cross apply (
                select fileproperty([DF].[name], 'spaceused') as [size]
            ) as [UP]
    )
select
    [BD].[Type]                                         as [Type],
    [BD].[FileName]                                     as [FileName],
    format([BD].[TotalSpaceInGB], N'N2')                as [TotalSpaceInGB],
    format([BD].[UsedSpaceInGB], N'N2')                 as [UsedSpaceInGB],
    format([BD].[FreeSpaceInGB], N'N2')                 as [FreeSpaceInGB],
    case [BD].[MaxSize]
        when 0 then N'Disabled'
        when -1 then N'Unrestricted'
        else format(([BD].[MaxSize] / 131072.0), N'N2')
    end                                                 as [MaxSizeInGB]
from [BaseData] as [BD]
order by [BD].[Type] asc, [BD].[FileName];
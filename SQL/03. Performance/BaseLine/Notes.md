
* Checks

    - All should be created on Stored Procedures or Functions
    - All objects has header

    1. SQL Version
        dbo.sp_SQLVersionInfo

        RESULT = [dbo].[sp_SQLVersionInfo]

    2. OS  Version
        2.1. OS info

        RESULT = [dbo].[sp_OSInfo]

        2.2. Host information (Query 12) (Host Info)

    3. Hardware
    	3.1. Get socket, physical core and logical core count from the SQL Server Error log. (Query 2) (Core Counts) 
             This query might take a few seconds depending on the size of your error log
        3.2. Hardware information from SQL Server 2025  (Query 18) (Hardware Info)
        3.3. Get System Manufacturer and model number from SQL Server Error log (Query 19) (System Manufacturer)
        3.4. Get BIOS date from Windows Registry (Query 20) (BIOS Date)
        3.5. Get processor description from Windows Registry  (Query 21) (Processor Description)
        3.6. Drive information for all fixed drives visible to the operating system (Query 29) (Fixed Drives)
        3.7. Volume info for all LUNS that have database files on the current instance (Query 30) (Volume Info)
        3.8. Drive level latency information (Query 31) (Drive Level Latency)
    
        RESULT = [dbo].[sp_HardwareInfo]

    4. Check Last Restart
        4.1. Check last reboot to know if the info result is usefull or not

        RESULT = [dbo].[sp_GetLastReboot]

    5. Services Info 
        5.1. SQL Server Services information (Query 7) (SQL Server Services Info)

    6. Trance Flags
        6.1. Get Trace Flag Status

    7. Server Properties
        7.1. Get selected server properties (Query 3) (Server Properties)

    8. Instance
        8.1. Get instance-level configuration values for instance  (Query 4) (Configuration Values)

    9. Health
        9.1. sp_Blitz 
                @CheckServerInfo = 1

    10. Memory        
        10.1. Good basic information about OS memory amounts and state  (Query 14) (System Memory)
        10.2. Get information on location, time and size of any memory dumps from SQL Server  (Query 23) (Memory Dump Info)
        10.3. Memory Grants Pending value for current instance  (Query 50) (Memory Grants Pending)
        10.4. Memory Clerk Usage for instance  (Query 51) (Memory Clerk Usage)
        10.5. 50_memory (BO)
        10.X. Check Memory set up and use (from Microsoft) --> No la encontre!!!

    11. CPU
        11.1. Get CPU utilization by database (Query 38) (CPU Usage by Database)
        11.2. Get CPU Utilization History for last 256 minutes (in one minute intervals)  (Query 47) (CPU Utilization History)

    12. IO
        12.1. Get I/O utilization by database (Query 39) (IO Usage By Database)
        12.2. I/O Statistics by file for the current database  (Query 61) (IO Stats By File)
        12.3. Lists the top statements by average input/output usage for the current database (Query 70) (Top IO Statements)

    13. NUMA
        13.1. SQL Server NUMA Node information  (Query 13) (SQL Server NUMA Info)
        13.2. Page Life Expectancy (PLE) value for each NUMA node in current instance (Query 49) (PLE by NUMA Node)

    14. Error Log
        14.1. Read most recent entries from all SQL Server Error Logs (Query 25) (Error Log Entries)
        14.2. Look for I/O requests taking longer than 15 seconds in the six most recent SQL Server Error Logs (Query 33) (IO Warnings)

    15. Backups
        15.1. Last backup information by database (Query 8) (Last Backup By Database)
        15.2. Look at recent Full backups for the current database (Query 89) (Recent Full Backups)
        15.3. 41_backup_throughput BO




    11. Accelerator
        11.1. Get detailed accelerator status information (Query 9) (Accelerator Status)
            QUE ES ESTO?
    12. Agent Jobs
        12.1. Get SQL Server Agent jobs and Category information (Query 10) (SQL Server Agent Jobs)
        12.2. Amount
        12.3. History
        12.4. LongRunningJobs
        12.5. 04_agent_job_maintenance_plans BO
    13. SQL Server Agent Alerts
        13.1. Get SQL Server Agent Alert Information (Query 11) (SQL Server Agent Alerts)
    16. Cluster Info
        16.1. General
            16.1.1. Get information about your cluster nodes and their status  (Query 15) (Cluster Node Properties)
        16.2. AlwaysOn
            16.2.1. Diagnostic (from Microsoft)
            16.2.2. Get information about any AlwaysOn AG cluster this instance is a part of (Query 16) (AlwaysOn AG Cluster)
            16.2.3. Good overview of AG health and status (Query 17) (AG Status)
        16.3. Mirroring
        16.4. LogShipping
    17. Pages
        17.1. Look at Suspect Pages table (Query 24) (Suspect Pages)
        17.2. 05_suspect_pages BO
        17.3. 06_auto_page_repair_mirroring BO
        17.4. 07_auto_page_repair_ag BO
    22. TEMPDB
        22.1. TempDB_and_Tran_Analysis (from Microsoft)
        22.2. Get VLF Counts for all databases on the instance (Query 37) (VLF Counts)
        22.3. Get number of data files in tempdb database (Query 26) (TempDB Data Files)
        22.4. Find unequal tempdb data initial file sizes (Query 27) (Tempdb Data File Sizes)
        22.5. Get tempdb version store space usage by database (Query 41) (Version Store Space Usage)
        22.6. Status of last VLF for current database  (Query 59) (Last VLF Status)
        22.7. 30_io_vfile_stats      BO
        22.8. 31_io_vfile_stats_now  BO
    23. Database 
        23.1. Settings
        23.2. File names and paths for all user and system databases on instance  (Query 28) (Database Filenames and Paths)
        23.3. Recovery model, log reuse wait description, log file size, log usage size  (Query 35) (Database Properties)
        23.4. Get database scoped configuration values for current database (Query 60) (Database-scoped Configurations)
        5.1. Check DB ID
        5.2. Check DB Size
            02_database_sizes Brent ozar
    24. Files
        24.1. Calculates average latency per read, per write, and per total input/output for each database file  (Query 32) (IO Latency by File)
        24.2. Individual File Sizes and space available for current database  (Query 57) (File Sizes and Space)
        . mdf
        .ndf
        .log
            Log space usage for current database  (Query 58) (Log Space Usage)
    25. Resource Governor 
        25.1. Resource Governor Resource Pool information (Query 34) (RG Resource Pools)
    26. Indexes
        26.1. Missing Indexes for all databases by Index Advantage  (Query 36) (Missing Indexes All Databases)
        26.2. Cached SPs Missing Indexes by Execution Count (Query 69) (SP Missing Index)
        26.3. Possible Bad NC Indexes (writes > reads)  (Query 71) (Bad NC Indexes)
        26.4. Missing Indexes for current database by Index Advantage  (Query 72) (Missing Indexes)
        26.5. Find missing index warnings for cached plans in the current database  (Query 73) (Missing Index Warnings)
        26.6. Look at most frequently modified indexes and statistics (Query 78) (Volatile Indexes)
        26.7. Get fragmentation info for all indexes above a certain size in the current database  (Query 79) (Index Fragmentation)
        26.8. Index Read/Write stats (all tables in current DB) ordered by Reads  (Query 80) (Overall Index Usage - Reads)
        26.9. Index Read/Write stats (all tables in current DB) ordered by Writes  (Query 81) (Overall Index Usage - Writes)
    29. Buffer
        29.1. Get total buffer usage by database for current instance  (Query 40) (Total Buffer Usage by Database)
        29.2. Breaks down buffers used by current database by object (table, index) in the buffer cache  (Query 74) (Buffer Usage)
        29.3. Get input buffer information for the current database (Query 86) (Input Buffer)
    30. Waits
        30.1. Isolate top waits for server instance since last restart or wait statistics clear  (Query 42) (Top Waits)
        31.2. 20_waitstats_percent_signal_waits BO
        30.3. 21_waitstats_since_last_clear  BO
        30.4. 23_waitstats_last_30_seconds   BO
    31. connection
        31.1. Get a count of SQL connections by IP address (Query 43) (Connection Counts by IP Address)
    52. Sessions
    32. Blocking
        32.1. Detect blocking (run multiple times)  (Query 45) (Detect Blocking)
    33. Page Contention
        33.1. Show page level contention (Query 46) (Page Contention)
    34. Top Worker Time Queries
        34.1. Get top total worker time queries for entire instance (Query 48) (Top Worker Time Queries)
    35. AdHoc
        35.1. Find single-use, ad-hoc and prepared queries that are bloating the plan cache  (Query 52) (Ad hoc Queries)
    36. Query Store
        36.1. General checks (from Microsoft)
        36.2. Get top total logical reads queries for entire instance (Query 53) (Top Logical Reads Queries)
        36.3. Get top average elapsed time queries for entire instance (Query 54) (Top Avg Elapsed Time Queries)
        36.4. Get most frequently executed queries for this database (Query 62) (Query Execution Counts)
        36.5. Top Cached SPs By Execution Count (Query 63) (SP Execution Counts)
        36.6. Top Cached SPs By Avg Elapsed Time (Query 64) (SP Avg Elapsed Time)
        36.7. Top Cached SPs By Total Worker time. Worker time relates to CPU cost  (Query 65) (SP Worker Time)
        36.8. Top Cached SPs By Total Logical Reads. Logical reads relate to memory pressure  (Query 66) (SP Logical Reads)
        36.9. Top Cached SPs By Total Physical Reads. Physical reads relate to disk read I/O pressure  (Query 67) (SP Physical Reads)
        36.10. Top Cached SPs By Total Logical Writes (Query 68) (SP Logical Writes)
        36.11. Get Query Store Options for this database (Query 85) (Query Store Options)
    37. UDF Stats by DB
        37.1. Look at UDF execution statistics (Query 55) (UDF Stats by DB)
        37.2. Look at UDF execution statistics (Query 83) (UDF Statistics)
        37.3. Determine which scalar UDFs are in-lineable (Query 84) (Inlineable UDFs)
    38. Tables
        38.1. Table Size
        Get Schema names, Table names, object size, row counts, and compression status for clustered index or heap  (Query 75) (Table Sizes)
        38.2. Table amount
        38.3. Get some key table properties (Query 76) (Table Properties)
        38.4. Constraint
            38.4.1. Check Heads
            38.4.2. Check PK
            38.4.3. Check QK
            38.4.4. Check FK
    39. Stats
        39.1. When were Statistics last updated on all indexes?  (Query 77) (Statistics Update)
    40. Locks
        40.1. Get lock waits for current database (Query 82) (Lock Waits)
        40.2. Is Optimized Locking enabled for the current database? (Query 88) (Optimized Locking)
    41. Tuning advisor
        41.1. Get database automatic tuning options (Query 87) (Automatic Tuning Options)
    42. Change Tracking
        42.1. Change Tracking Script for PSSDiag (from Microsoft)
    43. Change Data Capture
        43.1. Check CDC (from Microsoft)
    44. Link Server
        44.1. Linked Server Configuration (from Microsoft)
    45. Misc
        45.1. De todo un poco (from Microsoft)
    46. Replication
        46.1. Check Replication (from Microsoft)
    47. DB Mail
        16.1. Check set up and use (from Microsoft)
    48. Service Brokers
    49. Users and Logins
    50. Triggers
    51. SP per DBs
    52. Log Files
    53. Plans
        82_plans_duplicated BO
    53. SQL_Server_PerfStats_Snapshot
        15.1. 60_perf_counters BO
        15.1. SQL_Server_PerfStats_Snapshot (from Microsoft)
        15.2. SQL_Server_PerfStats (from Microsoft)
        
        Ver en detalle que hacen estos checks?
        9.1. High IO (from Microsoft)
        9.2. High CPU (from Microsoft)

        WHERE counter_name = 'Batch Requests/sec' AND object_name LIKE '%SQL Statistics%';
        WHERE counter_name = 'SQL Compilations/sec'        AND object_name LIKE '%SQL Statistics%';
        WHERE counter_name = 'SQL Re-Compilations/sec'     AND object_name LIKE '%SQL Statistics%';
        WHERE counter_name = 'Lock Waits/sec'        AND instance_name = '_Total'        AND object_name LIKE '%Locks%';
        WHERE counter_name = 'Page Splits/sec'       AND object_name LIKE '%Access Methods%'; 
        WHERE counter_name = 'Checkpoint Pages/sec'  AND object_name LIKE '%Buffer Manager%';       
        WHERE counter_name = 'Buffer cache hit ratio'      AND object_name LIKE '%Buffer Manager%') a  
        WHERE counter_name = 'Buffer cache hit ratio base' AND object_name LIKE '%Buffer Manager%') b    
        WHERE counter_name = 'Page life expectancy '       AND object_name LIKE '%Buffer Manager%') c
        WHERE counter_name = 'Batch Requests/sec' AND object_name LIKE '%SQL Statistics%') d   
        WHERE counter_name = 'SQL Compilations/sec' AND object_name LIKE '%SQL Statistics%') e 
        WHERE counter_name = 'SQL Re-Compilations/sec' AND object_name LIKE '%SQL Statistics%') f
        WHERE counter_name = 'Lock Waits/sec'          AND instance_name = '_Total'        AND object_name LIKE '%Locks%') h
        WHERE counter_name = 'Page Splits/sec' AND object_name LIKE '%Access Methods%') i
        WHERE counter_name = 'Processes blocked' AND object_name LIKE '%General Statistics%') j
        WHERE counter_name = 'Checkpoint Pages/sec' AND object_name LIKE '%Buffer Manager%') k
        WHERE counter_name = 'Total Server Memory (KB)'
        WHERE counter_name = 'Target Server Memory (KB)'
        WHERE object_name= @Instancename+'Buffer Manager' and counter_name = 'Total pages' 
        WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Database pages' 
        WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Free pages'
        WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Reserved pages'
        WHERE object_name=@Instancename+'Buffer Manager' and counter_name = 'Stolen pages'
        WHERE object_name=@Instancename+'Plan Cache' and counter_name = 'Cache Pages'  and instance_name = '_Total'
        WHERE counter_name = 'Connection Memory (KB)'
        WHERE counter_name = 'Lock Memory (KB)'
        WHERE counter_name = 'SQL Cache Memory (KB)'
        WHERE counter_name = 'Optimizer Memory (KB) '
        WHERE counter_name = 'Granted Workspace Memory (KB) '
        WHERE counter_name = 'Cursor memory usage' and instance_name = '_Total'
        WHERE a.counter_name = 'Buffer cache hit ratio'
    54. sp_BlitzCache
        70_sp_BlitzIndex
        blitzLock
    15. SQL Server Services information (Query 7) (SQL Server Services Info)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

EXECUTION ORDER
    1. [dbo].[sp_SQLVersionInfo]
    2. [dbo].[sp_OSInfo]
    3. [dbo].[sp_HardwareInfo]
    4. [dbo].[sp_GetLastReboot]

Para sacar ideas de como ejecutar todo leer el README y SQLLogScoutPs de microsoft. Es un buen input para ver como ejecutar todo el analisis, las alternativas, etc
Como lo haria yo.

    . Scripts
        . Armar un solo script con todas las queries.
        . Armar scripts individuales
    . Backend
        T-SQL muchas cosas se pueden ejecutar con T-SQL
        PowerShell muchas otras cosas las podemos ejecutar con PS cosas que chequean el OS y los files
    
    . FrontEnd
        Python
        HTML report

    . A tener en cuanta
        Como tener en cuenta todas las versiones de SQL

    . Here are links to the latest versions of these diagnostic queries for Azure SQL Managed Instance, Azure SQL Database, SQL Server 2025, SQL Server 2022, SQL Server 2019,
     SQL Server 2017, SQL Server 2016 SP2, SQL Server 2016, SQL Server 2014, SQL Server 2012, SQL Server 2008 R2, SQL Server 2008, and SQL Server 2005.
    
    . Una manera simple de hacer esto podria ser tener una carpeta con nombre Scripts, PowerShell, etc. La app tendria que tomar estos archivos y ejecutarlos.
      Y donde los guardo?
    
    . A las queries de Glenn les crearon un PowerShell en dbatool to export to CSV or Excel
      Quizas pueda tomar esto para modificarlo y sumarle cosas.

    . Crear un diccionario de las cosas a chequear


Architecture

    Technologies
        . T-SQL
        . Python (API/Backend)
        . JSON (intermediate data format)
        . FastAPI (for APIs)
        . Excel/CSV (for visualization) 

    Workflow
        . Script T-SQL
        . PowerShell/Python with pyodbc/pymssql to connect to the SQL
        . Execute the Script
        . Stores output in structured JSON/CSV files by server and date.
        . Python Dash, reads data from API/SQL for dashboarding.


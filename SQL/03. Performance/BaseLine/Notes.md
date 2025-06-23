
* Checks

    - All should be created on Stored Procedures or Functions
    - All objects has header

    <!-- ================= Start Server Checks ================= -->

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
        SUMAR ESTO !!!!!!!!!!!!!
        22.7. 30_io_vfile_stats      BO
        22.8. 31_io_vfile_stats_now  BO

    13. NUMA
        13.1. SQL Server NUMA Node information  (Query 13) (SQL Server NUMA Info)
        13.2. Page Life Expectancy (PLE) value for each NUMA node in current instance (Query 49) (PLE by NUMA Node)

    14. Error Log
        14.1. Read most recent entries from all SQL Server Error Logs (Query 25) (Error Log Entries)
        14.2. Look for I/O requests taking longer than 15 seconds in the six most recent SQL Server Error Logs (Query 33) (IO Warnings)

    <!-- ================= Start Database Checks ================= -->

    15. Backups
        15.1. Last backup information by database (Query 8) (Last Backup By Database)
        15.2. Look at recent Full backups for the current database (Query 89) (Recent Full Backups)
        15.3. 41_backup_throughput BO

    16. TEMPDB
        16.1. Get VLF Counts for all databases on the instance (Query 37) (VLF Counts)
        16.2. Get number of data files in tempdb database (Query 26) (TempDB Data Files)
        16.3. Find unequal tempdb data initial file sizes (Query 27) (Tempdb Data File Sizes)
        16.4. Get tempdb version store space usage by database (Query 41) (Version Store Space Usage)
        16.5. Status of last VLF for current database  (Query 59) (Last VLF Status)
        16.6. TempDB_and_Tran_Analysis (from Microsoft)

    17. Database 
        17.1. Settings
        17.2. File names and paths for all user and system databases on instance  (Query 28) (Database Filenames and Paths)
        17.3. Recovery model, log reuse wait description, log file size, log usage size  (Query 35) (Database Properties)
        17.4. Get database scoped configuration values for current database (Query 60) (Database-scoped Configurations)
        17.1. Check DB ID
        17.2. Check DB Size
            02_database_sizes Brent ozar

    18. Files
        18.1. Calculates average latency per read, per write, and per total input/output for each database file  (Query 32) (IO Latency by File)
        18.2. Individual File Sizes and space available for current database  (Query 57) (File Sizes and Space)
        18.3. Log space usage for current database  (Query 58) (Log Space Usage)

    19. Cluster Info
        19.1. General
            19.1.1. Get information about your cluster nodes and their status  (Query 15) (Cluster Node Properties)
        19.2. AlwaysOn
            19.2.1. Diagnostic (from Microsoft)
            19.2.2. Get information about any AlwaysOn AG cluster this instance is a part of (Query 16) (AlwaysOn AG Cluster)
            19.2.3. Good overview of AG health and status (Query 17) (AG Status)
        19.3. Mirroring
        19.4. LogShipping


    <!-- ================= Start Performance Checks ================= -->

    20. Waits
        20.1. Isolate top waits for server instance since last restart or wait statistics clear  (Query 42) (Top Waits)
        20.2. 20_waitstats_percent_signal_waits BO
        20.3. 21_waitstats_since_last_clear  BO
        20.4. 22_waitstats_latch_wait_detail
        20.5. 23_waitstats_last_30_seconds   BO

        WARNING
        Que onda con los scrpits the BO para ver esta info?

    21. Indexes
        21.1. Missing Indexes for all databases by Index Advantage  (Query 36) (Missing Indexes All Databases)
        21.2. Cached SPs Missing Indexes by Execution Count (Query 69) (SP Missing Index)
        21.3. Possible Bad NC Indexes (writes > reads)  (Query 71) (Bad NC Indexes)
        21.4. Missing Indexes for current database by Index Advantage  (Query 72) (Missing Indexes)
        21.5. Find missing index warnings for cached plans in the current database  (Query 73) (Missing Index Warnings)
        21.6. Look at most frequently modified indexes and statistics (Query 78) (Volatile Indexes)
        21.7. Get fragmentation info for all indexes above a certain size in the current database  (Query 79) (Index Fragmentation)
        21.8. Index Read/Write stats (all tables in current DB) ordered by Reads  (Query 80) (Overall Index Usage - Reads)
        21.9. Index Read/Write stats (all tables in current DB) ordered by Writes  (Query 81) (Overall Index Usage - Writes)

        WARNING
        Que onda con los scrpits the BO para ver esta info?

    22. Locks
        22.1. Get lock waits for current database (Query 82) (Lock Waits)
        
        <!-- THIS IS ONLY TO sql sERVE 2025 -->        
        22.2. Is Optimized Locking enabled for the current database? (Query 88) (Optimized Locking)

    23. Blocking
        23.1. Detect blocking (run multiple times)  (Query 45) (Detect Blocking)

    <!-- ================= Start Plan Checks ================= -->

    24. sp_BlitzCache
        24.1. Plan CPU
            24.1.1. Queries by Total CPU
                sp_BlitzCache @ExpertMode = 1, @SortOrder = 'cpu'
            24.1.2. Queries by Average CPU
                sp_BlitzCache @ExpertMode = 1, @SortOrder = 'avg cpu'
        24.2. Plan Reads
            24.2.1. Queries by Total Reads
                sp_BlitzCache @ExpertMode = 1, @SortOrder = 'reads'
            24.2.2. Queries by Average Reads
                sp_BlitzCache @ExpertMode = 1, @SortOrder = 'avg reads'
        24.3. Plan Duration
            24.3.1. Queries by Total Duration
                sp_BlitzCache @ExpertMode = 1, @SortOrder = 'duration'
            24.3.2. Queries by Average Duration
                sp_BlitzCache @ExpertMode = 1, @SortOrder = 'avg duration'
        24.4. Plan Execution 
            24.4.1. Queries by Total Executions
                sp_BlitzCache @ExpertMode = 1, @SortOrder = 'executions'
            24.4.2. Queries by Executions per Minute
                sp_BlitzCache @ExpertMode = 1, @SortOrder = 'xpm'
        24.5. Plan Writes
            24.5.1. Queries by Total Writes
                sp_BlitzCache @ExpertMode = 1, @SortOrder = 'writes'
            24.5.2. Queries by Average Writes
                sp_BlitzCache @ExpertMode = 1, @SortOrder = 'avg writes'
        24.6. Plan Memory
            24.6.1 Queries by Memory Grant
                sp_BlitzCache @ExpertMode = 1, @SortOrder = 'memory grant'
        24.7. Plan Spill
            24.7.1. Queries by Total TempDB Spills
                sp_BlitzCache @ExpertMode = 1, @SortOrder = 'spills'
            24.7.2. Queries by Average TempDB Spill Size
                sp_BlitzCache @ExpertMode = 1, @SortOrder = 'avg spills'
        24.8. Plan Recent
            24.8.1.Queries by Compilation Date
                sp_BlitzCache @ExpertMode = 1, @SortOrder = 'recent compilations'
        24.9. PlansCPU ByHash
            24.9.1 Queries with Multiple Plans in the Cache, by Total CPU
                sp_BlitzCache @ExpertMode = 1, @SortOrder = 'cpu'
        24.10. Plan Duplicated 
            22.10.1. Queries with Multiple Plans in the Cache, by Total Number of Cached Plans
                82_plans_duplicated BO


    <!-- ============== Start Replication Checks =============
        Aca quiero poner todo lo referente a Mirroring, 
        Logshiping, Always ON, Linked Server. Todo relacionado 
        a replicacion     -->
    
    25. Link Server
        25.1. Linked Server Configuration (from Microsoft)

    26. Replication
        26.1. Check Replication (from Microsoft) TERMINAR!!!!!!

    27. Pages
        27.1. Look at Suspect Pages table (Query 24) (Suspect Pages)
        27.2. 05_suspect_pages BO
        27.3. 06_auto_page_repair_mirroring BO
        27.4. 07_auto_page_repair_ag BO

    <!-- =================   Start Job Checks   ================= -->

    28. Agent Jobs
        28.1. Get SQL Server Agent jobs and Category information (Query 10) (SQL Server Agent Jobs)
        28.2. 04_agent_job_maintenance_plans BO (12.4. LongRunningJobs esta incluido si veo 3er resultado)
        28.3. Amount
        28.4. History Error

    29. SQL Server Agent Alerts
        29.1. Get SQL Server Agent Alert Information (Query 11) (SQL Server Agent Alerts)

    <!-- ============= Start Objects Database Checks ============ -->
    
    30. Object Information
        . Amount of: Tables, Views, SP, FX, TRG, Assemblies, User Type, Sequence, Partition Schemes, Partition function, Users, Schemas

    31. Tables
        31.2. Table amount
        31.1. Get Schema names, Table names, object size, row counts, and compression status for clustered index or heap  (Query 75) (Table Sizes)
        31.4. Get Heaps/Heads tables.
        /* Si bien me muestra nueva info tiene cosas duplicadas y no termina siendo util esta query
        31.3. Get some key table properties (Query 76) (Table Properties) */

    32. UDF Stats by DB
        32.1. Look at UDF execution statistics (Query 55) (UDF Stats by DB)
        32.2. Look at UDF execution statistics (Query 83) (UDF Statistics)
        32.3. Determine which scalar UDFs are in-lineable (Query 84) (Inlineable UDFs)

    33. Triggers
        33.1. Get Info Triggers DB and Server

    <!-- =========== Start Resource Governor Checks ============ -->
    
    34. Resource Governor 
        34.1. Resource Governor Resource Pool information (Query 34) (RG Resource Pools)

    <!-- ============== Start Query Store Checks =============== 
         ==== For now I am not going to add QS information ===== 
    -->
    <!--
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
    -->

    <!-- ================= Start General Checks ================= -->
    45. Misc
        45.1. De todo un poco (from Microsoft)
              Script Name = MiscDiagInfo.sql
              Note = It's a good script but for the moment I am not going to include it.

------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------

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
        . FastAPI (framework web for Python)
        . Excel/CSV (for visualization) 

    Workflow
        . Script T-SQL
        . PowerShell/Python with pyodbc/pymssql to connect to the SQL
        . Execute the Script
        . Stores output in structured JSON/CSV files by server and date.
        . Python Dash, reads data from API/SQL for dashboarding.


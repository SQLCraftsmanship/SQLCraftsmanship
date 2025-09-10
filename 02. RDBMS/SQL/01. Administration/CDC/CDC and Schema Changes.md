
# <h1 align="center" id="heading">**CDC and Schema Changes**</h1>

<style>
[Heading](#heading)
.large-text {
  font-size: 2em;
}
.small-text {
  font-size: 0.9em;
}
r { color: red }
o { color: Orange }
g { color: Green }
lg { color: lightgreen }
b { color: Blue }
lb { color: lightblue }

<p class="large-text">This text will be large.</p>
<p class="small-text">This text will be small.</p>
</style>

- **Request**

  Adding a column in the middle of a table can break the Qlik Replication process. But if we change a column to be **NOT NULL** from **NULL** will that also break the process?

- **Analysis**

    - **General information**
 
      * CDC is tightly bound to the schema of the capture instance (the change table).

      * The capture instance is created when we enable CDC on the table, and it includes metadata such as column names, data types, and nullability.

      * If we alter a tracked column in a way that changes its metadata signature (like data type, length, precision, or nullability), then the capture instance becomes out of sync with the source table.

    - **DHL Case**
     
      * Changing a tracked column from NULL to NOT NULL will change the column definition in the source table
      * CDC will not autocatically update irs capture instance to reflect this.
      * The CDC change table still reflects the old definition (column as nullable).
      * This does not break CDC capture immediately, but it means:

        * The change table an source table definitions are no longer aligned
        * Schema validation DMV will shot a mismatch **(sys.sp_dcd_verify_metadata)**

    - **Risk in Production**
  
      * We must assume that any schema changfe on a tracked column can break downstream processes (like ETL, etc)
      * The SQL Server CDC log reader will still capture changes for that column after the nullability change, but metadata drift exists.

    - **Safe Options**

      We have a couple of safe paths to do this change on PROD:

      * **Option A – Keep CDC instance alive (lower risk, but possible drift)**

        . Ensure no rows currently have NULL in that column.
        . Run the ALTER TABLE ... ALTER COLUMN ... NOT NULL.
        . Run sys.sp_cdc_verify_metadata for the capture instance to check for mismatches.
          If there is a mismatch, consumers may need adjustment.

      * **Option B – Recreate capture instance (clean, higher effort)**

        . Disable CDC for that table (sys.sp_cdc_disable_table)
        . Re-enable CDC with a new capture instance (sys.sp_cdc_enable_table)
        . Consumers that query the CDC change tables will need to switch to the new capture instance

      **In production, the safest long-term solution is to recreate the capture instance, but if downtime is a concern and consumers can tolerate schema drift, we may get away with just altering the column (after ensuring no existing NULL values)**

    - **Step-By-Step playbook**

      I am going to develop a practical, production-safe playbook covering all viable options for changing a CDC tracked column from NULL to NOT NULL in SQL Server 2022.

      1. **Quick summary (pick a path)**

          * **Path A – Fastest (keep current capture instance)**

            . Fix data (no NULLs) → ALTER COLUMN ... NOT NULL → verify.
            . Lowest effort. Leaves capture-instance metadata drift; some tools/processes may complain.

          * **Path B1 – Cleanest (recreate capture instance)**

            . Pause consumers
            . Capture last LSN
            . Disable CDC on table (ALTER COLUMN)
            . Enable CDC (new instance)
            . Resume consumers from the captured LSN
            . Clean metadata, future-proof
            . Requires coordinated cutover

          * **Path B2 – Near-zero downtime (dual capture instances):**

            . CDC allows two capture instances per table
            . Keep old instance for readers (ALTER COLUMN)
            . Create new capture instance
            . Migrate consumers to the new instance
            . Drop old instance later
            . Minimal interruption to readers
            . Requires consumer switch with LSN continuity

      2. **Pre-change checks (run for ANY path)**

        ```sql
        /* Identify capture instance(s) for the table */
        SELECT 
              t.object_id, t.name AS table_name, ci.capture_instance, ci.supports_net_changes
        FROM sys.tables t
        JOIN sys.schemas s 
        ON   s.schema_id = t.schema_id
        JOIN sys.sp_cdc_help_change_data_capture(NULL, NULL) AS ci 
          ON ci.source_object_id = t.object_id
        WHERE s.name = N'dbo' 
          AND t.name = N'TableName';

        /* Confirm the column is captured */
        SELECT 
              capture_instance, column_ordinal, column_name
        FROM  cdc.captured_columns
        WHERE object_id = OBJECT_ID(N'cdc.CaptureInstanceName')
        ORDER BY column_ordinal;

        /* Make sure there are NO NULLs before altering */
        SELECT NULLs = COUNT(*) 
        FROM  dbo.TableNAme WITH (READUNCOMMITTED)
        WHERE ColumnName IS NULL;

        /* If there are NULLs, decide your backfill value and volume (Use a selective sample to estimate size/impact) */
        SELECT TOP (10) * 
        FROM dbo.TableName
        WHERE ColumnName IS NULL;

        /* If NULLs exist, backfill in small batches to avoid big locks/log spikes: */
        /* Example backfill in batches of 10k */
        DECLARE @b INT = 10000;

        WHILE 1 = 1
        BEGIN
        
            WITH cte_BackFill AS (
                SELECT TOP (@b) *
                FROM   dbo.TableName WITH (ROWLOCK, READPAST, UPDLOCK)
                WHERE  ColumnName IS NULL
                ORDER BY (SELECT 1)
            )
        
            UPDATE cte_BackFill SET ColumnName = N'<Value>';

            IF @@ROWCOUNT = 0 BREAK;
        END
        ```

      3. **Path A – Fastest (keep current capture instance)**

        Use when consumers (like ETL) don’t perform strict schema verification on the capture instance.

        . Ensure no NULLs remain (batch backfill above).

        . Schedule a short maintenance window (the ALTER COLUMN needs a SCH-M lock and will scan to verify).

        . Apply the change:

        ```sql
        ALTER TABLE dbo.TableName
        ALTER COLUMN ColumnName <DataType> NOT NULL; 
        /* same type/length/collation as before */
        ```

        . Verify CDC still capturing & note metadata drift:

        ```sql
        /* Verify reader is healthy */
        SELECT TOP (10) * 
        FROM cdc.CaptureInstanceNAme 
        ORDER BY start_lsn DESC;

        /* Show schema mismatch warnings (if any) */
        EXEC sys.sp_cdc_verify_metadata 
        @source_schema          = N'dbo',
        @source_name            = N'TableName',
        @capture_instance       = N'CaptureInstanceName';
        ```

        Communicate that the source table is now NOT NULL but the change table still marks the column as nullable.

        **Rollback plan:** If needed, revert to ALTER COLUMN ... NULL in a window. (We must ensure application logic can handle NULLs again)

      4. **Path B1 — Recreate capture instance (clean alignment)**

         Use when we want no metadata drift and can coordinate a brief consumer pause.

         . Pause consumers (like ETLs, etc)

         . Capture cutover LSN

         ```sql
         DECLARE @CutoverLSN BINARY(10) = sys.fn_cdc_get_max_lsn();
         SELECT @CutoverLSN AS CutoverLSN;
         ```
        
         . Disable CDC for the table (not the database)

         ```SQL
         EXEC sys.sp_cdc_disable_table
         @source_schema = N'dbo',
         @source_name   = N'TableName',
         @capture_instance = N'CaptureInstanceName'; /* if we omit, it disables all instances for the table */
         ```

         . Apply the schema change

         ```sql
         ALTER TABLE dbo.TableName
         ALTER COLUMN ColumnName <DataType> NOT NULL;
         ```

         . Re-enable CDC, creating a new capture instance

         ```sql
         EXEC sys.sp_cdc_enable_table
            @source_schema           = N'dbo',
            @source_name             = N'TableName',
            @role_name               = NULL,    -- or your db role
            @supports_net_changes    = 1,       -- if we need net changes
            @capture_instance        = N'InstanceName', -- new instance name
            @filegroup_name          = NULL,    -- or your CDC FG
            @index_name              = NULL,    -- or name your PK/unique index if no PK
            @captured_column_list    = NULL;    -- default: all non-LOB columns
         ```

         . Validate new instance

         ```sql
         EXEC sys.sp_cdc_verify_metadata N'dbo', N'TableNAme', N'InstanceName';
        
         SELECT TOP (10) * 
         FROM cdc.TableNAme
         ORDER BY start_lsn DESC;
         ```

         . Consumer resume

          Resume from @CutoverLSN (or the next LSN) on the new instance to avoid gaps.

          If the consumer uses the TVFs, pass from_lsn = @CutoverLSN:

          ```sql
          DECLARE @from_lsn binary(10) = @CutoverLSN;
          DECLARE @to_lsn   binary(10) = sys.fn_cdc_get_max_lsn();

          SELECT *
          FROM cdc.fn_cdc_get_all_changes_InstanceName(@from_lsn, @to_lsn, N'all');
          ```

          When confident, drop the old instance (optional):

          ```sql
          EXEC sys.sp_cdc_disable_table 
             @source_schema = N'dbo',
             @source_name   = N'TableNAme',
             @capture_instance = N'CaptureInstanceName';
          ```

          **Rollback plan** If anything fails after step 4, we can ALTER COLUMN ... NULL and re-enable the original capture instance name.

      5. **Path B2 – Near zero downtime (dual capture instances):**

         Use when we want minimal reader interruption. CDC supports two capture instances per table.

         High level idea: Keep the old instance alive for existing consumers while you introduce a new instance that matches the new schema; migrate consumers at your pace, then retire the old instance.

         . Prep and backfill (no NULLs).

          Short maintenance window to apply the schema change:

          ```sql
          ALTER TABLE dbo.TableName
          ALTER COLUMN ColumnName <DataType> NOT NULL;
          ```

          Create a second capture instance (e.g., _v2) that reflects the new nullability:
          
          ```sql
          EXEC sys.sp_cdc_enable_table
            @source_schema        = N'dbo',
            @source_name          = N'TableName',
            @capture_instance     = N'TableName_v2',
            @supports_net_changes = 1;
          ```

          Verify both instances are advancing (they’ll share the same log stream):
          
          ```sql
          SELECT 'old' AS inst, TOP(1) start_lsn 
          FROM   cdc.CaptureInstance_CT 
          ORDER BY start_lsn DESC;

          SELECT 'new' AS inst, TOP(1) start_lsn 
          FROM   cdc.TableName_v2_CT     
          ORDER BY start_lsn DESC;
          ```

          Pick a consumer cutover LSN (e.g., sys.fn_cdc_get_max_lsn() at the moment you switch a consumer).

          For each consumer, finish processing on the old instance up to that LSN, then continue on the new instance starting from the same LSN (or the next). LSNs are global across instances.

          After all consumers move, disable the old instance:

          ```sql
          EXEC sys.sp_cdc_disable_table 
            @source_schema = N'dbo',
            @source_name   = N'TableName',
            @capture_instance = N'CaptureInstanceName';
          ```

          **Rollback plan:** Consumers still pointed to the old instance can continue there while we resolve any issue with the new instance.

      6. **Post change validation checklist**

         ```sql
            /* Validate column is NOT NULL at source */
            SELECT COUNT(*) AS NullsAfter
            FROM dbo.TableName
            WHERE ColumnName IS NULL;

            /* Verify CDC jobs */
            EXEC sys.sp_cdc_help_jobs;

            /* Verify capture instances and metadata */
            EXEC sys.sp_cdc_verify_metadata N'dbo', N'TableName', N'TableName_v2'; -- or current instance

            /* Smoke test that new changes flow */
            DECLARE @from_lsn BINARY(10) = sys.fn_cdc_get_min_lsn(N'TableName_v2');
            DECLARE @to_lsn   BINARY(10) = sys.fn_cdc_get_max_lsn();

            SELECT TOP (100) * 
            FROM  cdc.fn_cdc_get_all_changes_YourTable_v2(@from_lsn, @to_lsn, N'all')
            ORDER BY start_lsn DESC;
         ```

      7. **Operational considerations**

         * Locks & duration
        
            ALTER COLUMN ... NOT NULL takes a SCH-M lock and scans to validate the constraint. The duration depends on table size and IO; schedule it during low activity. Keep transactions short around the DDL.

         * Log growth

            Backfills and CDC both write to the log. Monitor log size, VLFs, and ensure the CDC cleanup job runs (default retention is 3 days).

         * Indexes/constraints

            If the column participates in filtered indexes or constraints that assume NULL semantics, review those before altering.

         * ETL/consumers
 
            If consumers infer schema from the CDC change table, Path A might break them due to nullability mismatch. Prefer B1 or B2 in that case.


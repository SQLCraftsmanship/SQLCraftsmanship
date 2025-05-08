
/********************************************************************************************************************************************************************
    Book    : Lear PostgreSQL
    Chapter : 15 Backup and Restore
********************************************************************************************************************************************************************/

/********************************************************************************************************************************************************************
    Notes
        How to inspect your filesystem and the PGDATA directory

        There are mainly two types of backups that apply to PostgreSQL: the logical backup (also known as a cold backup) and the physical backup (also known as a 
        hot backup). Depending on the type of backup you choose, the restore process will differ accordingly

        But what is the difference between these two backup methods? The difference between the two backup strategies come from the way data is extracted from the 
        cluster.

        LOGICAL BACKUP
        --------------
        A logical backup works as a database client that asks for all the data in a database, table by table, and stores the result in a storage system. It is like 
        an application opening a transaction and performing a SELECT on every table, before saving the result on a disk file.
        Of course, it is much more complex than that, but this example gives you a simple idea of what happens under the hood.

        The advantages of this backup strategy are that it is simple to implement since PostgreSQL provides all the software to perform a full backup, it is consistent, 
        and it can be restored easily. However, this backup method also has a few drawbacks: being performed on a live system by means of a snapshot can slow down 
        other concurrent database accesses

        PHYSICAL BACKUP
        ---------------
        A physical backup, on the other hand, is not invasive of cluster operations: the backup requires a file-level copy of the PGDATA content – mainly the database 
        file (PGDATA/base) and the WALs from the backup's start instance to the backup's end. The end result will be an inconsistent copy of the database that needs 
        particular care to be restored properly. Essentially, the restore will proceed since the database has crashed and will redo all the transactions (extracted 
        from the WALs) in order to achieve a consistent state.

        PERFORM BACKUP AND RESTORING
        ----------------------------
        There are three main applications involved in backup and restore – pg_dump, pg_dumpall, and pg_restore. As you can imagine from their names, pg_dump and 
        pg_dumpall are related to extracting (dumping) the content of a database, thus creating a backup, while pg_restore is their counterpart and allows you to 
        restore an existing backup.

        The pg_dump application is used to dump a single database within a cluster, pg_dumpall provides us with a handy way to dump all the cluster content, including 
        roles and other intra-cluster objects, and pg_restore can handle the output of the former two applications to perform a restoration.

        In order to dump – that is, to create a backup copy of – a database, you need to use the pg_dump command. pg_dump allows three main backup formats to be used:
        A plain text format: Here, the backup is made of SQL statements that are reproducible. A compressed format: Here, the backup is automatically compressed to 
        reduce storage space consumption. A custom format: This is more suitable for a selective restore by means of pg_restore

        By default, pg_dump uses plain text format, which produces SQL statements that can be used to rebuild the database structure and content, and outputs the backup 
        directly to the standard output. This means that if you back up a database without using any particular option, you are going to see a long list of SQL 
        statements:
            
                    $ pg_dump -U postgres forumdb

        There are a few important things to note related to the backup content. The first is that pg_dump places a bunch of SET statements at the very beginning of the 
        backup; such SET statements are not mandatory for the backup, but for restoring from this backup's content. In other words, the first few lines of the backup 
        are not related to the content of the backup, but to how to use such a backup.

        An important line among those SET statements is the following one, which has been introduced in recent versions of PostgreSQL:
                SELECT pg_catalog.set_config('search_path', '', false);
        
        Such lines remove the search_path variable, which is the list of schema names among those to search for an unqualified object. The effect of such a line is that 
        every object that's created from the backup during a restore will not exploit any malicious code that could have tainted your environment and your search_path. 
        The side effect of this, as will be shown later on, is that after restoration, the user will have an empty search path and will not be able to find any not 
        fully qualified objects by their names.
        
        Another important thing about the backup content is that pg_dump defaults to using COPY as a way to insert the data into single tables. COPY is a PostgreSQL 
        command that acts like INSERT but allows for multiple tuples to be specified at once and, most notably, is optimized for bulk loading, resulting in a faster 
        recovery. However, this can make the backup not portable across different database engines, so if your aim is to dump the database content in order to migrate 
        it to another engine, you have to specify pg_dump to use regular INSERT statements by means of the --inserts command-line flag:

                    $ pg_dump -U postgres forumdb
                    ...
                    INSERT INTO public.categories OVERRIDING SYSTEM VALUE VALUES (1,
                    'DATABASE', 'Database related discussions');
                    INSERT INTO public.categories OVERRIDING SYSTEM VALUE VALUES (2, 'UNIX',
                    'Unix and Linux discussions');

        The entire content of the backup is the same, but this time, the tables are populated by standard INSERT statements. As you can imagine, the end result is a 
        more portable but also longer (and therefore much heavier) backup content. However, note how, in the previous example, the INSERT statements did not include 
        the list of columns every field value maps to; it is possible to get a fully portable set of INSERT statements by replacing the --inserts option with 
        --column-inserts:

                    $ pg_dump -U postgres --column-inserts forumdb
                    ...
                    INSERT INTO public.categories (pk, title, description) OVERRIDING SYSTEM
                    VALUE VALUES (1, 'DATABASE', 'Database related discussions');
                    INSERT INTO public.categories (pk, title, description) OVERRIDING SYSTEM
                    VALUE VALUES (2, 'UNIX', 'Unix and Linux discussions');

        Being able to dump the database content is useful, but being able to store such content in a file is much more useful and allows for restoration to occur at a 
        later date. There are two main ways to save the output of pg_dump into a file. One requires that we redirect the output to a file, as shown in the following 
        example:
                    
                    $ pg_dump -U postgres --column-inserts forumdb > backup_forumdb.sql

        The other (suggested) way is to use the pg_dump -f option, which allows us to specify the filename that the content will be placed in. Here, the preceding 
        command line can be rewritten as follows:

                    $ pg_dump -U postgres --column-inserts -f backup_forumdb.sql forumdb

        This has the very same effect as producing the backup_forumdb.sql file, which contains the same SQL content that was shown in the previous examples. 
        pg_dump also allows for verbose output, which will print what the backup is performing while it is performing. The -v command-line flag enables this verbose 
        output:

                    $ pg_dump -U postgres -f backup_forumdb.sql -v forumdb

        This command create the bkp files with INSERTs and also CREATE a script to create database
                
                    $ pg_dump -U postgres --column-inserts --create -f backup_forumdb.sql forumdb $ less backup_forumdb.sql

        To backup only the structure of the database:

                    $ pg_dump -U postgres -s -f database_structure.sql forumdb
        
        To backup only the data

                    $ pg_dump -U postgres -a -f database_content.sql forumdb
        
        You can also decide to limit your backup scope, either by schema or data, to a few tables by means of the -t command-line flag or, on the other hand, to 
        exclude some tables by means of the -T parameter. For example, if we want to back up only the users table and users_pk_seq sequence, we can do the following:
                    
                    $ pg_dump -U postgres -f users.sql -t users -t user_pk_seq forumdb

        The created users.sql file will contain only enough data to recreate the user-related stuff and nothing more. On the other hand, if we want to exclude the users 
        table from the backup, we can do something similar to the following:

                    $ pg_dump -U postgres -f users.sql -T users -T user_pk_seq forumdb

        Of course, you can mix and match any option in a way that makes sense to you and, more importantly, allows you to restore exactly what you need. As an example, 
        if you want to get all the data contained in the posts table and the table structure itself, you can do the following:
                    
                    $ pg_dump -U postgres -f posts.sql -t posts -a forumdb


        Backup formats are specified by the -F command-line argument to pg_dump, which allows for one of the following values:
            c (custom) is the PostgreSQL-specific format within a single file archive.
            d (directory) is a PostgreSQL-specific format that's compressed where every object is split across different files within a directory.
            t (tar) is a .tar uncompressed format that, once extracted, results in the same layout as the one provided by the directory format.

        e.g 
        
            c (custom)
                Backup
                    $ pg_dump -U postgres -Fc --create --inserts -f backup_forumdb.backup forumdb
                    $ pg_dump -U postgres -Fc --create --column-inserts -f backup_forumdb.backup forumdb

                Restore
                    $ pg_restore -U postgres -C -d template1 backup_forumdb.backup

                The -C option indicates that pg_restore will recreate the database before restoring inside it. The -d option tells the program to connects to the 
                template1 database first, issue a CREATE DATABASE, and then connect to the newly created database to continue the restore, similar to what the plain
                backup format did. Clearly, pg_restore requires a mandatory file to operate on; that is, the last argument specified on the command line.
                It is interesting to note that pg_restore can produce a list of SQL statements that are going to be executed without actually executing them. 
                The -f command-line option does this and allows you to store plain SQL in a file or inspect it before proceeding any further with the restoration:

                    $ pg_restore backup_forumdb.backup -f restore.sql
                    $ less restore.sql
                    --
                    -- PostgreSQL database dump
                    --
                    CREATE EXTENSION IF NOT EXISTS pgaudit WITH SCHEMA public;
                    ...

            d (directory) 
                Another output format for pg_dump is the directory one, specified by means of the -Fd command-line flag. In this format, pg_dump creates a set of 
                compressed files in a directory on disk; in this case, the -f command-line argument specifies the name of a directory instead of a single file. 
                As an example, let's do a backup in a backup folder:

                    $ pg_dump -U postgres -Fd -f backup forumdb
                    $ ls -lh backup

                The directory is created, if needed, and every database object is placed in a single compressed file. The toc.dat file represents a Table Of Contents, 
                an index that tells pg_restore where to find any piece of data inside the directory. The following example shows how to destroy and restore the database
                by means of a backup directory:

                    $ pg_restore -C -d template1 -U postgres backup/
                    $ psql -U luca forumdb

            t (tar)
                The very last pg_dump format is the .tar one, which can be obtained by means of the -Ft command-line flag. The result is the creation of a tar(1) 
                uncompressed archive that contains the same directory structure that we created in the previous example, but where every file is not compressed:

                    $ pg_dump -U postgres -Ft -f backup_forumdb.tar forumdb
                    $ tar tvf backup_forumdb.tar


        Performing a selective restore. We can do this just see page 485.

        Dumping a whole cluster. We can do this just see page 487.

        Parallel backups. We can do this just see page 487.
    
        
        BACKUP AUTOMATION
        -----------------
        By combining pg_dump and pg_dumpall, it is quite easy to create automated backups, for example, to run every night or every day when the database system is not 
        heavily used.
        Depending on the operating system you are using, it is possible to schedule such backups and have them be executed and rotated automatically.
        If you're using Unix, for example, it is possible to schedule pg_dump via cron(1), as follows:
            
            $ crontab -e

        crontab is used to schedule commands to be executed periodically. Generally, crontab uses a daemon, crond, which runs constantly in the background and checks 
        once a minute to see if any of the scheduled jobs need to be executed.

        After doing this, you would add the following line:

            30 23 * * * pg_dump -Fc -f /backup/forumdb,backup -U postgres forumdb

        This takes a full backup in custom format every day at 23:30. However, the preceding approach has a few drawbacks, such as managing already existing backups, 
        dealing with newly added databases that require another line to be added to the crontab, and so on.
        
        Thanks to the flexibility of PostgreSQL and its catalog, it is simple enough to develop a wrapper script that can handle backing up all the databases with ease. 
        As a starting point, the following script performs a full backup of every database except for template0:

            #!/bin/sh

            BACKUP_ROOT=/backup
            
            for database in $( psql -U postgres -A -t -c "SELECT datname FROM pg_database WHERE datname <> 'template0'" template1 )
            do
                backup_dir=$BACKUP_ROOT/$database/$(date +'%Y-%m-%d')
            
                if [ -d $backup_dir ]; then
                    echo "Skipping backup $database, already done today!"
                    continue
                fi

                mkdir -p $backup_dir
            
                pg_dump -U postgres -Fd -f $backup_dir $database
                echo "Backup $database into $backup_dir done!"
            done

        The idea is quite simple: the system queries the PostgreSQL catalog, pg_database, for every database that the cluster is serving, and for every database, it 
        searches for a dedicated directory named after the database that contains a directory named after the current date. If the directory exists, the backup has 
        already been done, so there is nothing to do but continue to the next database. Otherwise, the backup can be performed. Therefore, the system will back up the 
        forumdb database to the /backup/forumd/2020-05-03 directory one day, /backup/forumb/2020-05-04 the next day, and so on. 
        Due to this, it is simple to add the preceding script to your crontab and forget about adding new lines for new databases, as well as removing lines that 
        correspond to deleted databases:

            30 23 * * * my_backup_script.sh
        
        Of course, the preceding script does not represent a complex backup system, but rather a starting point if you need a quick and flexible solution to perform an 
        automated logical backup with tools your PostgreSQL cluster and operating system are offering. As already stated, many operating systems have already taken 
        backing up a PostgreSQL cluster into account and offer already crafted scripts to help you solve this problem. A very good example of this kind of script is the 
        502.pgsql script, which is shipped with the FreeBSD package of PostgreSQL.

********************************************************************************************************************************************************************/


# *********************************************************************************************************************
# Date  : 2022.06.29
# Owner : Jefatura de Gabinete de Ministros
# Aim   : Create PostgresSQL bakcup for all databases
# Exec  : crontab command
# *********************************************************************************************************************

#!/bin/sh

# Set path to Backup
BACKUP_ROOT=/home/etlssh/backup/

# Check how many DBs we have
for database in $( psql -U etlssh -A -t -c "SELECT datname FROM pg_database WHERE datname <> 'template0'" template1 )
do
    # ***************************************************************************
    # Get Path
    # ***************************************************************************
    backup_dir=$BACKUP_ROOT/$database/$(date +'%Y-%m-%d')

    # Check if BKP has been done today.
    if [ -d $backup_dir ]; then
        echo "Skipping backup $database, already done today!"
        continue
    fi

    # ***************************************************************************
    # # Create folder
    # ***************************************************************************
    mkdir -p $backup_dir


    # ***************************************************************************
    # Create backups
    # ***************************************************************************

    # First Backup
    # User      : etlssh [-U]
    # INSERT    : include standard INSERT statements [--column-inserts]
    # DROP      : include DROP DATABASE command [-c]
    # CREATE    : include CREATE DATABASE command [-C] 
    # ROLES     : not include ROLEs [-O]
    # Privile.  : not include GRANT / REVOKE [-x]
    pg_dump -U etlssh --column-inserts -c -C -O -x -f $backup_dir $database

    # Second Backup
    # Same First Backup but including Roles and Privileges
    pg_dump -U etlssh --column-inserts -c -C -f $backup_dir $database

    # Show message
    echo "Backup $database into $backup_dir done!"
done

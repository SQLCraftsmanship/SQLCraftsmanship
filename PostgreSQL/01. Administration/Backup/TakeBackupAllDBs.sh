#!/bin/sh

BACKUP_ROOT=/backup

for database in $( psql -U etlssh -A -t -c "SELECT datname FROM pg_database WHERE datname <> 'template0'" template1 )
do
    backup_dir=$BACKUP_ROOT/$database/$(date +'%Y-%m-%d')

    if [ -d $backup_dir ]; then
        echo "Skipping backup $database, already done today!"
        continue
    fi

    mkdir -p $backup_dir

    pg_dump -U etlssh -Fd -f $backup_dir $database
    echo "Backup $database into $backup_dir done!"
done

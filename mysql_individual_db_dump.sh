#!/bin/bash

USER="root"
PASSWORD="#######"
#OUTPUT="/Users/rabino/DBs"

#rm "$OUTPUTDIR/*gz" > /dev/null 2>&1

#databases=`mysql -u $USER -p$PASSWORD -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`

databases=`mysql -u $USER -p$PASSWORD -e "SHOW DATABASES;" | awk '{ print $1 }' | grep -v Database`

printf "########DATABASES LIST ##########\n\n"
echo "$databases"
printf "\nEnter db to be migrated:"
read userdb
for db in $userdb; do
    if [[ "$db" != "information_schema" ]] && [[ "$db" != "performance_schema" ]] && [[ "$db" != "mysql" ]] && [[ "$db" != _* ]] ; then
        echo "Dumping database: $db"
        mysqldump -u $USER -p$PASSWORD --databases $db > $db.`date +%Y%m%d`.sql
       # gzip $OUTPUT/`date +%Y%m%d`.$db.sql
    fi
done

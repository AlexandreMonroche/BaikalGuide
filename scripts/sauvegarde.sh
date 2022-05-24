#! /bin/bash
#
# Ce script sauvegarde la base de données baïkal
#

# Récupération de la date

DATE="baikal-$(date +"%Y-%m-%d")"

# Dossier où sauvegarder les backups

BACKUP_DIR="/backup"

# Commandes MySQL

MYSQL=/usr/bin/mysql
MYSQLDUMP=/usr/bin/mysqldump

# Bases de données MySQL à ignorer

SKIPDATABASES="Database|information_schema|performance_schema|mysql"

# Service web
WEBSERVICE="apache2.service"

# Nombre de jours à garder les dossiers (seront effacés après X jours)

RETENTION=14

# ---- NE RIEN MODIFIER SOUS CETTE LIGNE ------------------------------------------
#
# Arrêt du serveur web
systemctl stop $WEBSERVICE

# Create a new directory into backup directory location for this date

mkdir -p $BACKUP_DIR/$DATE

# Retrieve a list of all databases

databases=`$MYSQL -e "SHOW DATABASES;" | grep -Ev "($SKIPDATABASES)"`

# Dumb the databases in seperate names and gzip the .sql file

for db in $databases; do
echo $db
$MYSQLDUMP --force --opt --skip-lock-tables --events --databases $db | gzip > "$BACKUP_DIR/$DATE/$db.sql.gz"
done

# Démarrage du serveur web
systemctl start $WEBSERVICE

# Remove files older than X days

find $BACKUP_DIR/* -mtime +$RETENTION -delete

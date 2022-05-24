# Gérez votre calendrier et vos contacts avec Baïkal

> [sabre.io/baikal](https://sabre.io/baikal/)

## Sommaire

- [Introduction](#introduction)
- [Crédits](#crédits)
- [Prérequis](#prérequis)
- [Installation](#installation)
    - [Base de données](#installer-un-système-de-gestion-de-base-de-données)
    - [Serveur web](#installer-un-serveur-web)
    - [HTTPS](#https)
    - [PHP et Modules PHP](#installer-php-et-les-modules-php)
    - [Baïkal](#télécharger-baïkal)
- [Configuration](#configuration)
    - [Base de données](#configuration-de-mariadb)
    - [Serveur web](#configuration-dapache)
    - [Baïkal](#configurer-baïkal)
- [Utilisation](#utilisation)
    - [iOS](#connecter-un-client-ios)
- [Sauvegarde de la base de données](#sauvegarde-de-la-base-de-données)
    - [Sauvegarde automatique](#automatiquement)
    - [Sauvegarde manuelle](#manuellement)
    - [Restauration](#restauration)
- [Mise à jour de Baïkal](#mise-à-jour-de-baïkal)
- [Sécurité](#améliorer-la-sécurité-du-serveur)
- [Questions et contributions](#questions-et-contributions)

---

## Introduction

Ce guide permet l'installation et la configuration de votre propre serveur de calendrier ([CalDAV](https://fr.wikipedia.org/wiki/CalDAV)) et de contacts ([CardDAV](https://fr.wikipedia.org/wiki/CardDAV)) avec [Baïkal](https://sabre.io/baikal/).

Baïkal permet d'accéder de manière transparente à vos contacts et calendriers depuis n'importe quel appareil. Il est compatible avec iOS, Mac OS X, DAVx<sup>5</sup> sur Android, Mozilla Thunderbird et toute autre application compatible CalDAV et CardDAV.

Protégez votre vie privée en hébergeant vous-même vos calendriers et vos contacts.

## Crédits 

Ce guide a été écrit à partir des sources suivantes :
- [sabre.io/baikal](http://sabre.io/baikal/), merci à [Jérôme Schneider](https://github.com/jeromeschneider) et [fruux](https://fruux.com/)
- [Guide en allemand pour une installation sur Raspberry Pi](https://github.com/JsBergbau/BaikalAnleitung), merci à [@JsBergbau](https://github.com/JsBergbau)
- [Kinamo pour la sauvegarde de la base de données](https://www.kinamo.fr/fr/support/faq/mysql-backup-automatique-base-de-donnees)
- [ChrisTitus pour l'amélioration en sécurité du serveur](https://christitus.com/secure-web-server/)
- Mon expérience

## Prérequis

Pour suivre ce guide vous aurez besoin
- D'un serveur basé sur [Debian](https://www.debian.org/) avec accès root
- D'un nom de domaine avec l'enregistrement DNS A configuré vers l'IP de votre serveur.

> Dans la suite du guide, il est considéré que le nom de domaine est `domaine.fr` et le sous-domaine avec l'enregistrement est `cal.domaine.fr`

---

## Installation

Devenir root
```bash
sudo -i
```
Mise à jour du cache d'[APT](https://fr.wikipedia.org/wiki/Advanced_Packaging_Tool) et du système
```bash
apt update && apt upgrade -y
```

### Installer un système de gestion de base de données
Installation de [MariaDB](https://mariadb.org/)
```bash
apt install mariadb-server -y
```

### Installer un serveur web
Installation d'[Apache2](https://httpd.apache.org/)
```bash
apt install apache2 -y
```

#### Vérification
Rendons nous sur `http://cal.domaine.fr/`, vous devriez voir la page par défault d'apache.

![Apache2 default](images/Baïkal/apache2.jpg "Apache2 default")

### HTTPS
Pour activer [HTTPS](https://fr.wikipedia.org/wiki/HyperText_Transfer_Protocol_Secure) sur votre site Web, vous devez obtenir un certificat (un type de fichier) auprès d'une autorité de certification (CA). Nous utiliserons [Let's Encrypt](https://letsencrypt.org/getting-started/) comme autorité de certification. Afin d'obtenir un certificat pour votre domaine auprès de Let's Encrypt, vous devez démontrer que vous contrôlez le domaine.

[Certbot](https://certbot.eff.org/) permet une gestion de certificats Let's Encrypt, automatisant la génération d'un certificat tout en prouvant la possession du serveur web.

#### Installation de Certbot
```bash
apt install certbot -y
```

#### Génération d'un certificat
```bash
certbot certonly --standalone
```

#### Test de renouvellement automatique
```bash
certbot renew --dry-run
```

#### Vérification
Rendons nous sur `https://cal.domaine.fr/`, vous devriez voir une icone de cadenas dans la barre URL.

![HTTPS](images/Baïkal/https.png "HTTPS")

> Aide : [Certbot](https://certbot.eff.org/pages/help) ou [Let's Encrypt](https://community.letsencrypt.org/)

### Installer [PHP](https://www.php.net/) et les modules PHP
```bash
apt install php php-mysql php-dom -y
```

### Télécharger Baïkal
Nous installerons le serveur dans le dossier `/srv`

> Source : [The Linux Documentation Project](https://tldp.org/LDP/Linux-Filesystem-Hierarchy/html/srv.html)

```bash
cd /srv
```

Aller à [github.com/sabre-io/Baikal/releases/latest](https://github.com/sabre-io/Baikal/releases/latest) et télécharger la dernière version de l'archive ZIP.

![Latest version](images/Baïkal/latest_version.png "Latest version")

#### Téléchargement en ligne de commande pour la version 0.9.2
```bash
wget https://github.com/sabre-io/Baikal/releases/download/0.9.2/baikal-0.9.2.zip
```

### Installer [unzip](https://packages.debian.org/bullseye/unzip)
```bash
apt install unzip -y
```

### Extraction de l'archive
```bash
unzip baikal-0.9.2.zip
rm baikal-0.9.2.zip
```

### Modification récursive du propriétaire
```bash
chown -R www-data:www-data /srv/baikal
```
> Point d'attention sécurité

---

## Configuration

### Configuration de MariaDB
Lancer le script de configuration initiale
```bash
mysql_secure_installation
```
> Point d'attention sécurité

> ATTENTION : Choisissez un [bon mot de passe](https://www.cybermalveillance.gouv.fr/medias/2019/11/Fiche-pratique_mots-de-passe.pdf)

>  Aide : [mysql_secure_installation](https://mariadb.com/kb/en/mysql_secure_installation/)

Connection au serveur mysql
```bash
mysql -u root -p
```

Créer une base de donnée `baikal` et un utilisateur `baikal`
```sql
CREATE DATABASE baikal;

CREATE USER 'baikal'@'localhost' IDENTIFIED BY 'password';

GRANT ALL PRIVILEGES ON baikal.* TO 'baikal'@'localhost';

FLUSH PRIVILEGES;
```

> ATTENTION : Choisissez un [bon mot de passe](https://www.cybermalveillance.gouv.fr/medias/2019/11/Fiche-pratique_mots-de-passe.pdf)

> *CTRL+D* pour quitter

### Configuration d'Apache
#### Création d'un fichier de configuration dédié au site Baïkal
```bash
nano /etc/apache2/sites-available/baikal.conf
```
Exemple de configuration :
```conf
<VirtualHost *:80>

    ServerName cal.domaine.fr
    Redirect permanent / https://cal.domaine.fr/
    
</VirtualHost>

<VirtualHost *:443>

    DocumentRoot /srv/baikal/html
    ServerName cal.domaine.fr

    RewriteEngine on
    # Generally already set by global Apache configuration
    # RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
    RewriteRule /.well-known/carddav /dav.php [R=308,L]
    RewriteRule /.well-known/caldav  /dav.php [R=308,L]

    <Directory "/srv/baikal/html">
        Options None
        # If you install cloning git repository, you may need the following
        # Options +FollowSymlinks
        AllowOverride None
        # Configuration for apache-2.4:
        Require all granted
        # Configuration for apache-2.2:
        # Order allow,deny
        # Allow from all
    </Directory>

    <IfModule mod_expires.c>
        ExpiresActive Off
    </IfModule>

    SSLEngine on
    SSLCertificateFile    /etc/letsencrypt/live/cal.domaine.fr/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/cal.domaine.fr/privkey.pem

</VirtualHost>
```

Vous trouverez ce fichier de configuration ici => [conf/baikal.conf](conf/baikal.conf)

Il ne vous reste plus qu'a remplacer (*CTRL+H*) les 4 occurences de `cal.domaine.fr` par votre sous-domaine.

#### Activer les modules nécessaires
```bash
a2enmod alias
a2enmod expires
a2enmod rewrite
a2enmod ssl
```

#### Désactiver les sites par défaut et activer le site baikal
```bash
a2dissite *
a2ensite baikal.conf
```

#### Redémarrer le serveur web
```bash
systemctl restart apache2
```

> Si vous n'avez pas correctement installé de certificat SSL, une erreur peut survenir, référez vous à [cette partie](#https) du guide.

## Configurer Baïkal

Il est maintenant temps de se connecter à votre domaine, ici `https://cal.domaine.fr/`, avec un navigateur web pour réaliser la configuration initiale.

![Configuration initiale](images/Baïkal/initialisation.png "Configuration initiale (depuis le guide allemand)")

Saisie d'un mot de passe d'administration

> ATTENTION : Choisissez un [bon mot de passe](https://www.cybermalveillance.gouv.fr/medias/2019/11/Fiche-pratique_mots-de-passe.pdf)

---

Connection à la base de donnée avec l'utilisateur baikal

![Connection base de donnée](images/Baïkal/bdd.png "Connection base de donnée (depuis le guide allemand)")

> On utilise ici l'identifiant et le mot de passe de l'utilisateur **mysql** `baikal` saisis dans [cette partie](#configuration-de-mariadb).

### Tout est prêt !
## Utilisation

On peut maintenant se connecter avec le compte `admin` sur la page d'administration `https://cal.domaine.fr/admin` ou en cliquant sur le bouton `Login`

![Connection admin](images/Baïkal/login.png "Connection admin (depuis le guide allemand)")

> On utilise ici l'identifiant et le mot de passe d'administration saisis dans [cette partie](#configurer-baïkal).

Panneau de contôle

![Panneau de contrôle](images/Baïkal/dashboard.png "Panneau de contrôle (depuis le guide allemand)")

Accès à la liste des utilisateurs

![Liste des utilisateurs](images/Baïkal/users.png "Liste des utilisateurs (depuis le guide allemand)")

Création d'un utilisateur

![Création d'un utilisateur](images/Baïkal/user.png "Création d'un utilisateur (depuis le guide allemand)")

> ATTENTION : Choisissez un [bon mot de passe](https://www.cybermalveillance.gouv.fr/medias/2019/11/Fiche-pratique_mots-de-passe.pdf)

> Point de vigilance sécurité, attention à la [méthode de hashage utilisée par Baïkal](https://github.com/sabre-io/Baikal/issues/514)

Liste des utilisateurs

![Liste des utilisateurs](images/Baïkal/users2.png "Liste des utilisateurs (depuis le guide allemand)")

Paramètres des carnets d'adresses (*Nom affiché du carnet et description*)

![Carnet d'adresses](images/Baïkal/address_books.png "Carnet d'adresses (depuis le guide allemand)")

Paramètres des calendriers (*Nom affiché du calendrier, couleur, description et options*)

![Calendrier](images/Baïkal/calendars.png "Calendrier (depuis le guide allemand)")


### C'est finit !

### Connecter un client iOS

![Etape 1](images/iOS/1.jpg "Etape 1")

![Etape 2](images/iOS/2.jpg "Etape 2")

![Etape 3](images/iOS/3.jpg "Etape 3")

![Etape 4](images/iOS/4.jpg "Etape 4")

![Etape 5](images/iOS/5.jpg "Etape 5")

![Etape 6](images/iOS/6.jpg "Etape 6")

> On utilise ici l'identifiant et le mot de passe d'un utilisateur créé dans [cette partie](#utilisation).

## Sauvegarde de la base de données

### Automatiquement
Un script de sauvegarde automatisée se trouve ici : [scripts/sauvegarde.sh](scripts/sauvegarde.sh)

Pour installer le script, il suffit de le placer à cet emplacement `/usr/local/sbin/`
```bash
nano /usr/local/sbin/sql_backup_baikal.sh
```

> CTRL+SHIFT+V pour coller, CTRL+O et Entrée pour sauvegarder le fichier et CTRL+X pour quitter nano

D'en modifier les droits
```bash
chmod 750 /usr/local/sbin/sql_backup_baikal.sh
```

> Point de vigilance sécurité

Puis
```bash
crontab -e
```
Et saisir sur une ligne
```bash
0 1 * * * root /usr/local/sbin/sql_backup_baikal.sh
```

Cela permet d'exécuter le script et de sauvegarder la base de données tous les jours à 01:00 am.

Pour tester le script :
```bash
/usr/local/sbin/sql_backup_baikal.sh
```

Vérifiez la présence de la sauvegarde dans le dossier `/backup`

### Manuellement

Passage en root
```bash
sudo -i
```
Arrêt du serveur web
```bash
systemctl stop apache2.service
```
Sauvegarde de la base `baikal` dans le dossier courant
```bash
mysqldump baikal | gzip > baikal.sql.gz
```

> Compression avec [gzip](https://fr.wikipedia.org/wiki/Gzip)

Démarrage du serveur web
```bash
systemctl start apache2.service
```

## Restauration

Passage en root
```bash
sudo -i
```
Décompression du fichier de backup
```bash
gunzip baikal.sql.gz
```
> Supposé dans le dossier courant

Création de la base de données `baikal`, puis restauration des données dans la base
```bash
mysql -e "CREATE DATABASE baikal";
mysql baikal < baikal.sql
```

## Mise à jour de Baïkal

Se référer à [sabre.io/baikal/upgrade](https://sabre.io/baikal/upgrade/)

> ATTENTION : Faire une [sauvegarde de la base de données](#sauvegarde-de-la-base-de-données)

Passage en root
```bash
sudo -i
```
Arrêt du serveur web
```bash
systemctl stop apache2.service
```
Déplacement dans le dossier `/srv`
```bash
cd /srv
```
Déplacement (sauvegarde) du dossier `baikal` initial
```bash
mkdir -p /backup
mv baikal /backup/baikal.bak
```
Téléchargement de la nouvelle version
```bash
wget https://github.com/sabre-io/Baikal/releases/download/0.9.2/baikal-0.9.2.zip
```
Décompression de l'archive
```bash
unzip baikal-0.9.2.zip
```
Modification des droits
```bash
chown -R www-data:www-data baikal/
```
Suppression des dossiers `config` et `Specific` de la nouvelle version
```bash
rm -rf baikal/config baikal/Specific
```
Restauration des dossiers `config` et `Specific` à partir de la sauvegarde
```bash
cp -r /backup/baikal.bak/config baikal/
cp -r /backup/baikal.bak/Specific baikal/
```
Redémarrage du serveur web
```bash
systemctl start apache2.service
```

Il ne reste plus qu'à retourner sur la page d'administration `https://cal.domaine.fr/admin`

![Mise à jour](images/Baïkal/upgrade.png "Mise à jour (depuis le guide allemand)")

Comme nous avons déjà fait une sauvegarde, il suffit de cliquer sur `Start Upgrade`. 

![Fin de la mise à jour](images/Baïkal/upgrade2.png "Fin de la mise à jour (depuis le guide allemand)")

On supprime l'archive
```bash
rm -r /srv/baikal-0.9.2.zip
```

Après avoir vérifié que la synchronisation est toujours en cours et que les entrées sont toujours là, on peut supprimer la sauvegarde du dossier

```bash
rm -r /backup/baikal.bak/
```

La mise à jour est terminé !

## Améliorer la sécurité du serveur

La sécurité informatique est de votre responsabilité, les quelques notes ci-dessous vous donnent des outils pour améliorer la sécurité de votre serveur, il vous appartient cependant de vous renseigner si vous souhaitez aller plus loin.

Installation de [ufw](https://launchpad.net/ufw/) et [fail2ban](http://www.fail2ban.org/wiki/index.php/Main_Page)
```bash
apt install ufw fail2ban -y
```

Politique UFW
```bash
ufw allow 80/tcp
ufw allow 443/tcp
ufw default deny incoming
ufw default allow outgoing
ufw enable
```

> Attention à SSH, ne coupez pas la branche sur laquelle vous êtes 🍃

> Exemple pour le port 22 : `ufw limit 22/tcp`

Activer fail2ban
```bash
systemctl enable fail2ban
systemctl start fail2ban
```

Edition de `/etc/sysctl.conf`

![Edition de /etc/sysctl.conf](images/Baïkal/sysctl.conf.png "Edition de /etc/sysctl.conf (depuis christitus.com/secure-web-server)")


Prévenir l'usurpation d'adresse IP
```bash
cat <<EOF > /etc/host.conf
order bind,hosts
multi on
EOF
```

Afficher la liste des ports en écoute
```bash
netstat -tunlp
```

## Questions et contributions
N'hésitez pas à poser vos questions en soumettant une [issue](https://github.com/AlexandreMonroche/BaikalGuide/issues) ou une [pull request](https://github.com/AlexandreMonroche/BaikalGuide/pulls) !

Toute contribution est également la bienvenue.

**Enjoy !**

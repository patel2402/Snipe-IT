#!/bin/bash
DB_USER="snipeituser"
DB_PASS="root"
DB_NAME="snipeitdb" 

sudo apt update -y && sudo apt upgrade -y
sudo apt install apache2 -y
sudo apt install mariadb-server mariadb-client -y
sudo systemctl start apache2 
sudo systemctl start mariadb 
sudo systemctl enable apache2
sudo systemctl enable mariadb

#ALLOW PORTS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload
sudo a2enmod rewrite
sudo systemctl restart apache2

#INSTALL PHP
sudo apt install php php-cli php-fpm php-json php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath -y
sudo apt install php php-bcmath php-bz2 php-intl php-gd php-mbstring php-mysql php-zip php-opcache php-pdo php-calendar php-ctype php-exif php-ffi php-fileinfo php-ftp php-iconv php-intl php-json php-mysqli php-phar php-posix php-readline php-shmop php-sockets php-sysvmsg php-sysvsem php-sysvshm php-tokenizer php-curl php-ldap -y
sudo curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

#CREATE DATABASE FOR SNIP-IT
sudo mysql -u root -e "CREATE DATABASE snipeitdb;"
sudo mysql -u root -e "CREATE USER snipeituser@localhost IDENTIFIED BY 'root';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON snipeitdb.* TO 'snipeituser'@'localhost';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"

cd /var/www/
sudo git clone https://github.com/snipe/snipe-it
cd /var/www/snipe-it

sudo cp .env.example .env
sudo sed -i "s|^\\(DB_DATABASE=\\).*|\\1$DB_NAME|" "/var/www/snipe-it/.env"
sudo sed -i "s|^\\(DB_USERNAME=\\).*|\\1$DB_USER|" "/var/www/snipe-it/.env"
sudo sed -i "s|^\\(DB_PASSWORD=\\).*|\\1$DB_PASS|" "/var/www/snipe-it/.env"
sudo sed -i "s|^\\(APP_URL=\\).*|\\1|" "/var/www/snipe-it/.env"

sudo chown -R www-data:www-data /var/www/snipe-it
sudo chmod -R 755 /var/www/snipe-it

# COMPOSER_ALLOW_SUPERUSER=1 sudo composer update --no-plugins --no-scripts
COMPOSER_ALLOW_SUPERUSER=1 yes | sudo composer install --no-dev --prefer-source --no-plugins --no-scripts

yes | sudo php artisan key:generate

sudo a2dissite 000-default.conf
sudo cat << EOF | sudo tee /etc/apache2/sites-available/snipe-it.conf
<VirtualHost *:80>
  ServerName snipe-it.syncbricks.com
  DocumentRoot /var/www/snipe-it/public
  <Directory /var/www/snipe-it/public>
    Options Indexes FollowSymLinks MultiViews
    AllowOverride All
    Order allow,deny
    allow from all
  </Directory>
</VirtualHost>
EOF

sudo a2ensite snipe-it.conf

sudo chown -R www-data:www-data ./storage
sudo chmod -R 755 ./storage

sudo systemctl restart apache2
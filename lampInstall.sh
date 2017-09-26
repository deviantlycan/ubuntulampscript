#!/usr/bin/env bash

# Output and hold the start time for total time calculation.
START_TIME=`date +%s`
echo "Install Script starting..."
echo "Start time: $START_TIME"

# Set appropriate version information
CHROME_DRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE`
SELENIUM_STANDALONE_VERSION=3.4.0
SELENIUM_SUBDIR=$(echo "$SELENIUM_STANDALONE_VERSION" | cut -d"." -f-2)

printf "\n\n======\n Cleaning up any existing downloaded files \n======\n\n"
# Clean up any existing downloads
rm ~/google-chrome-stable_current_amd64.deb
rm ~/selenium-server-standalone-*.jar
rm ~/chromedriver_linux64.zip
sudo rm /usr/local/bin/chromedriver
sudo rm /usr/local/bin/selenium-server-standalone.jar

printf "\n\n======\n Running standard system updates \n======\n\n"
# Do the standard system updates
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get autoremove -y

printf "\n\n======\n Installing Metacity \n======\n\n"
# Install metacity since it is more lightweight.
sudo apt-get install gnome-session-flashback -y

printf "\n\n======\n Installing Chrome \n======\n\n"
# Install chrome
wget -N https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -P ~/
sudo dpkg -i --force-depends ~/google-chrome-stable_current_amd64.deb
sudo apt-get -f install -y
sudo dpkg -i --force-depends ~/google-chrome-stable_current_amd64.deb
rm -f ~/google-chrome-stable_current_amd64.deb

printf "\n\n======\n Installing Apache 2 \n======\n\n"
# Install Apache 2
sudo apt-get install apache2 -y
sleep 3
echo "restarting apache2"
sudo systemctl restart apache2

printf "\n\n======\n Installing MySQL and tools \n======\n\n"
# Install MySQL and tools
export DEBIAN_FRONTEND=noninteractive
# Set root password for mysql
debconf-set-selections <<< 'mysql-server mysql-server/root_password password rootpass'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password rootpass'
sudo apt-get install mysql-server mysql-client -y
sudo apt-get install mysql-workbench -y

printf "\n\n======\n Installing PHP and Tools \n======\n\n"
# Install PHP 7 and tools
sudo apt-get install php7.0-mysql php7.0-curl php7.0-json php7.0-cgi php7.0 libapache2-mod-php7.0 php-mbstring php7.0-mbstring php-gettext php-soap php-imap php-xdebug php-ldap -y
php -v
echo "<?php phpinfo(); ?>" | sudo tee -a /var/www/html/testphp.php
sudo curl -s https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
composer
wget -N https://phar.phpunit.de/phpunit-6.3.phar -P ~/
chmod +x phpunit-6.3.phar
sudo mv phpunit-6.3.phar /usr/local/bin/phpunit
phpunit --version

printf "\n\n======\n Installing phpMyAdmin \n======\n\n"
# Install phpMyAdmin for 
export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< 'phpmyadmin phpmyadmin/debconfig-install boolean true'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/admin-user string root'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/admin-pass password rootpass'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/app-pass password rootpass'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/app-password-confirm password rootpass'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/reconfigure-websever multiselect none'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/database-type select mysql'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/dbconfig-install boolean true'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/setup-password password rootpass'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2'

sudo apt-get install phpmyadmin -y
echo "Include /etc/phpmyadmin/apache.conf" | sudo tee -a /etc/apache2/apache2.conf
sudo systemctl restart apache2

printf "\n\n======\n Installing Memcached \n======\n\n"
# Install Memcache
sudo apt-get install memcached php-memcache php-memcached -y
sudo printf "extension=php_memcache\nextension=php_memcached" | sudo tee -a /etc/php/7.0/apache2/php.ini
sudo systemctl restart memcached.service
sudo systemctl restart apache2

printf "\n\n======\n Installing Selenium \n======\n\n"
# Install Selenium and chrome driver
sudo apt-get install default-jre -y
sudo apt-get install default-jdk -y
wget -N http://chromedriver.storage.googleapis.com/$CHROME_DRIVER_VERSION/chromedriver_linux64.zip -P ~/
unzip ~/chromedriver_linux64.zip
rm ~/chromedriver_linux64.zip
sudo mv -f ~/chromedriver /usr/local/bin/chromedriver
sudo chown root:root /usr/local/bin/chromedriver
sudo chmod 0755 /usr/local/bin/chromedriver
wget -N http://selenium-release.storage.googleapis.com/$SELENIUM_SUBDIR/selenium-server-standalone-$SELENIUM_STANDALONE_VERSION.jar -P ~/
sudo mv -f ~/selenium-server-standalone-$SELENIUM_STANDALONE_VERSION.jar /usr/local/bin/selenium-server-standalone.jar
sudo chown root:root /usr/local/bin/selenium-server-standalone.jar
sudo chmod 0755 /usr/local/bin/selenium-server-standalone.jar
sudo apt-get install xvfb -y
printf '#!/bin/sh\n' > ~/runSelinium.sh
printf "xvfb-run java -Dwebdriver.chrome.driver=/usr/local/bin/chromedriver -jar /usr/local/bin/selenium-server-standalone.jar\n" >> ~/runSelinium.sh

printf "\n\n======\n Making Optional configuration changes \n======\n\n"
# Optional configuration changes
# Disable strict mode in mysql
sudo printf "[mysqld]\nsql_mode=IGNORE_SPACE,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION" | sudo tee -a /etc/mysql/conf.d/disable_strict_mode.cnf
sudo systemctl restart mysql

printf "\n\n======\n Adding useful aliases \n======\n\n"
# Add some useful aliases
echo "alias cls=clear" >> ~/.bashrc


printf "\n\n======\n Done \n======\n\n"
# calculate and output the total run time.
END_TIME=`date +%s`
TOTAL_RUN_TIME=$((END_TIME-START_TIME))
echo "End time: $END_TIME"
echo "Total Run Time: $TOTAL_RUN_TIME"

echo "IMPORTANT!"
echo "  The MySQL root password is set to \"rootpass\" and needs to be reset with the command"
echo "  mysqladmin -u root password newpasswordhere"

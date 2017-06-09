kick-off

memo:
https://scotch.io/tutorials/build-a-mobile-app-with-angular-2-and-ionic-2
LoadModule rewrite_module modules/mod_rewrite.so

https://www.digitalocean.com/community/tutorials/how-to-set-up-mod_rewrite-for-apache-on-ubuntu-14-04

sudo a2enmod rewrite
sudo service apache2 restart

nohup ionic serve --nobrowser --nolivereload $> ionic.log &
screen -d -m -L ionic serve --nolivereload --nobrowser

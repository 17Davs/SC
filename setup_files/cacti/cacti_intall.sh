#!/bin/bash

# Atualizar pacotes e repositórios
echo "Atualizando pacotes e repositórios..."
sudo apt update && sudo apt upgrade -y

# Instalar as extensões PHP necessárias
echo "Instalando extensões PHP necessárias..."
echo "Instalando extensões PHP necessárias..."
sudo apt install -y php7.4-snmp php7.4-xml php7.4-mbstring php7.4-mysqli php7.4-pdo php7.4-pdo-mysql \
    php7.4-sockets php7.4-ldap php7.4-gd php7.4-gmp php7.4-intl

# Configurar o timezone no PHP
echo "Configurando o timezone no PHP..."
PHP_INI_APACHE="/etc/php/7.4/apache2/php.ini"
PHP_INI_CLI="/etc/php/7.4/cli/php.ini"

for PHP_INI in $PHP_INI_APACHE $PHP_INI_CLI; do
    sudo sed -i "s|^;date.timezone =.*|date.timezone = Europe/Lisbon|g" $PHP_INI
    sudo sed -i "s|^max_execution_time =.*|max_execution_time = 300|g" $PHP_INI
done

# Reiniciar serviços PHP e Apache
echo "Reiniciando serviços PHP e Apache..."
sudo systemctl restart php7.4-fpm
sudo systemctl restart apache2

# Verificar instalação das extensões PHP
echo "Verificando módulos PHP instalados..."
php -m | grep -E "snmp|xml|mbstring|mysqli|pdo|pdo_mysql|sockets|ldap"

# Concluir instalação
echo "Configurações do servidor local concluídas! Configure o banco de dados remotamente para finalizar."

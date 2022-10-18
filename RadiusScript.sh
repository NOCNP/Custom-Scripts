#!/bin/bash

echo "Distribution: Ubuntu"
echo "Radius Server"
echo "Installation and configure"
echo "with Sql DataBase"


###########################################################
############# OS Package Install & Configure ##############
###########################################################


# Changing Distribution Package from jammy -> kinetic
sudo sed -i 's/jammy/kinetic/g' /etc/apt/sources.list

# Updating System Packages.
sudo apt update

# Install Apache2, FreeRadius Modules.
sudo apt install apache2 freeradius freeradius-utils freeradius-mysql freeradius-config -y

# Install MySql Server & Client.
sudo apt install mysql-server mysql-client -y

# install PHP and it's module.
sudo apt install php php-cli php-mbstring php-mysql -y

# Install PhpMyAdmin.
#sudo apt install phpMyAdmin -y

# Install & Configure Composer.
curl -Ss https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer

# Now, Update & Upgrade OS.
sudo apt update && sudo apt upgrade -y
sudo apt full-upgrade -y

###########################################################
############# Radius Server & SQL  Configure ##############
###########################################################

sed -i '/mods-enabled\/sql/s/^#//' /etc/freeradius/3.0/radiusd.conf

sed -i '/dialect =/s/sqlite/mysql/' /etc/freeradius/3.0/mods-available/sql

sed -i '/rlm_sql_null/s/^/#/' /etc/freeradius/3.0/mods-available/sql

sed -i '/driver = "rlm_sql_${dialect}"/s/^#//' /etc/freeradius/3.0/mods-available/sql

sed -i -e '70,82s/^/#/' -e '86,96s/^/#/' -e '104,113s/^/#/' -e '139,157s/^/#/' /etc/freeradius/3.0/mods-available/sql

sed -i -e '/server = "localhost"/s/^#//' -e '/port = 3306/s/^#//' -e '/login/s/^#//' -e '/radpass/s/^#//' /etc/freeradius/3.0/mods-available/sql

sed -i '/read_clients/s/^#//' /etc/freeradius/3.0/mods-available/sql

sed -i -e '/dialect =/s/sqlite/mysql/' -e '/rlm_sql_null/s/^/#/' -e '/driver = "rlm_sql_${dialect}"/s/^#//' -e '70,82s/^/#/' -e '86,96s/^/#/' -e '104,113s/^/#/' -e '139,157s/^/#/' -e '/server = "localhost"/s/^#//' -e '/port = 3306/s/^#//' -e '/login/s/^#//' -e '/radpass/s/^#//' -e '/read_clients/s/^#//' /etc/freeradius/3.0/mods-available/sql

Sed -i '$ a \\nsqlcounter accessperiod {\n\tsql_module_instance = sql\n\t# dialect = ${modules.sql.dialect}\n\tdialect = mysql\n\n\tcounter_name = Max-Access-Period-Time\n\tcheck_name = Mmietech-Period\n\tkey = User-Name\n\treset = never\n\n\t$INCLUDE ${modconfdir}/sql/counter/${dialect}/${.:instance}.conf\n}\n\nsqlcounter quotalimit {\n\tsql_module_instance = sql\n\t# dialect = ${modules.sql.dialect}\n\tdialect = mysql\n\n\tcounter_name = Max-Volume\n\tcheck_name = Max-Data\n\treply_name = Mikrotik-Total-Limit\n\tkey = User-Name\n\treset = never\n\n\t$INCLUDE ${modconfdir}/sql/counter/${dialect}/${.:instance}.conf\n}' /etc/freeradius/3.0/mods-available/sqlcounter


cat << EOF > accessperiod.conf
query = "\\
        SELECT UNIX_TIMESTAMP() - UNIX_TIMESTAMP(AcctStartTime) \\
        FROM radacct \\
        WHERE UserName='%{${key}}' \\
        ORDER BY AcctStartTime LIMIT 1"
EOF


cat << EOF > quotalimit.conf
query = "\\
        SELECT (SUM(acctinputoctets) + SUM(acctoutputoctets)) \\
        FROM radacct \\
        WHERE UserName='%{${key}}'"
EOF


sed -i '/sql/s/-sql/sql/' /etc/freeradius/3.0/sites-available/default
sed -i '/sql/s/^#//' /etc/freeradius/3.0/sites-available/default



sed -i '487 i # MmieTech Custom Module. \n#        noresetcounter\n#       totalquota\n#        accessperiod\n#        quotalimit' /etc/freeradius/3.0/sites-available/default
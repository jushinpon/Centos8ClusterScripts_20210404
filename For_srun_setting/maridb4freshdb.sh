#!/bin/bash
# set FRESH=1 if you want a clean DB
systemctl stop mariadb
dnf remove -y mariadb mariadb-server
rm -rf /var/lib/mysql
rm -f /etc/my.cnf.d/*
dnf install -y mariadb mariadb-server
systemctl enable --now mariadb


mysql_secure_installation 2>/dev/null <<EOF
n
n
y
y
y
y
EOF

mysql -e "create database if not exists slurm_acct_db;"
mysql -e "create user if not exists 'slurm'@'localhost' identified by 'slurmdbd';"
mysql -e "grant all privileges on slurm_acct_db.* to 'slurm'@'localhost';"
mysql -e "flush privileges;"

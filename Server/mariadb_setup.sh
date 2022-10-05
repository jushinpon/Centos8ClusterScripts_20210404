#systemctl start mariadb

mysql_secure_installation 2>/dev/null <<EOF

n
n
y
y
y
y
EOF
mysql -e "create database slurm_acct_db;"
mysql -e "create user 'slurm'@'localhost' identified by 'slurmdbd';"
mysql -e "grant all privileges on slurm_acct_db.* to 'slurm'@'localhost';"
#systemctl restart mariadb
#systemctl enable mariadb
#!/bin/bash
# ==============================================
# MariaDB initialization for Slurm accounting
# ==============================================
#[root@master Server]# find /usr -name "libmysqlclient.so*" 2>/dev/null
#/usr/lib64/libmysqlclient.so

##ln -s /usr/lib64/mysql/libmysqlclient.so /usr/lib64/libmysqlclient.so.24
#rm -f /var/run/slurmdbd.pid
#
FRESH=1
DB_NAME="slurm_acct_db"
DB_USER="slurm"
DB_PASS="slurmdbd"
SOCKET_PATH="/var/lib/mysql/mysql.sock"

echo ">>> Starting MariaDB..."
systemctl enable --now mariadb
sleep 3

# Test connection
mysql -S "$SOCKET_PATH" -u root -e "select now();" >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "ERROR: Cannot connect to MariaDB."
  exit 1
fi

if [ "$FRESH" -eq 1 ]; then
  echo ">>> Dropping old DB and user..."
  mysql -S "$SOCKET_PATH" -u root -e "DROP DATABASE IF EXISTS $DB_NAME;"
  mysql -S "$SOCKET_PATH" -u root -e "DROP USER IF EXISTS '$DB_USER'@'localhost';"
fi

echo ">>> Creating Slurm accounting DB..."
mysql -S "$SOCKET_PATH" -u root <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

echo ">>> Done. Slurm accounting DB is ready."

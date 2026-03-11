#!/bin/sh
set -eu

DB_NAME="${MYSQL_DATABASE:-ai-agent}"
SOURCE_SQL="/opt/init/init.sql"
TMP_SQL="$(mktemp)"

# Reuse the shared init.sql while honoring MYSQL_DATABASE from .env.
sed \
  -e "s/CREATE DATABASE IF NOT EXISTS \`ai-agent\`/CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`/g" \
  -e "s/USE \`ai-agent\`;/USE \`${DB_NAME}\`;/g" \
  "${SOURCE_SQL}" > "${TMP_SQL}"

mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" < "${TMP_SQL}"
rm -f "${TMP_SQL}"

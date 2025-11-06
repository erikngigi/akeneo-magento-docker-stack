#!/usr/bin/env bash

# Resolve the real path of this script (handles symlinks)
MAGENTO_SCRIPT_DIR="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"

# source the file with the magento details
source "$MAGENTO_SCRIPT_DIR/magento.env"

# Helper shell script for printing
source "$MAGENTO_SCRIPT_DIR/colors.sh"

# Define a reusable function for the Docker container magento
magento_exec() {
	docker exec -it magento-php-fpm "$@"
}

# Setup composer details for Magento repository
magento_exec bash -c "composer config --global http-basic.repo.magento.com $ADOBE_MAGENTO_USERNAME $ADOBE_MAGENTO_PASSWORD"
print_green "Magento composer details added succesfully."

# Download the Magento community edition files
magento_exec bash -c "sudo chown -R $MAGENTO_USER:$MAGENTO_USER $MAGENTO_INST_DIR"
magento_exec bash -c "composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition=$MAGENTO_VERSION $MAGENTO_INST_DIR"
print_green "Magento version $MAGENTO_VERSION downloaded succesfully."

# Set the file permissions and make Magento binary executable
magento_exec bash -c "
    cd $MAGENTO_INST_DIR &&
    find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +;
    find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+ws {} +;
    chmod +x bin/magento;
"
print_green "Update permissions of Magento directory"

# Setup magento
print_blue "Installing Magento version $MAGENTO_VERSION"
magento_exec bash -c "
cd $MAGENTO_INST_DIR &&
bin/magento setup:install \
--base-url=$BASE_URL \
--use-secure=1 \
--base-url-secure=$BASE_URL_SECURE \
--use-secure-admin=1 \
--db-host=$DB_HOST \
--db-name=$DB_NAME \
--db-user=$DB_USER \
--db-password=$DB_PASSWORD \
--admin-firstname=$ADMIN_FIRSTNAME \
--admin-lastname=$ADMIN_LASTNAME \
--admin-email=$ADMIN_EMAIL \
--admin-user=$ADMIN_USER \
--admin-password=$ADMIN_PASSWORD \
--language=$LANGUAGE \
--currency=$CURRENCY \
--timezone=$TIMEZONE \
--use-rewrites=1 \
--elasticsearch-host=$ELASTICSEARCH_HOST \
--elasticsearch-port=$ELASTICSEARCH_PORT \
--session-save=$REDIS_HOST \
--session-save-redis-host=$REDIS_HOST \
--session-save-redis-db=0 \
--session-save-redis-password=${REDIS_PASSWORD} \
--cache-backend=$REDIS_HOST \
--cache-backend-redis-server=$REDIS_HOST \
--cache-backend-redis-db=2 \
--cache-backend-redis-password=${REDIS_PASSWORD} \
--page-cache=redis \
--page-cache-redis-server=$REDIS_HOST \
--page-cache-redis-db=4 \
--page-cache-redis-password=${REDIS_PASSWORD}
"

# Reindex files
print_green "Reindexing Magento files"
magento_exec bash -c "cd $MAGENTO_INST_DIR && php bin/magento setup:static-content:deploy -f"
magento_exec bash -c "cd $MAGENTO_INST_DIR && php bin/magento indexer:reindex"

# Disable Two factor authentication
print_green "Disabling Two factor authenication"
magento_exec bash -c "
cd $MAGENTO_INST_DIR &&
php bin/magento module:disable Magento_AdminAdobeImsTwoFactorAuth;
php bin/magento module:disable Magento_TwoFactorAuth;
"
# Recompile files
print_green "Recompile Magento files"
magento_exec bash -c "cd $MAGENTO_INST_DIR && php bin/magento setup:di:compile"
magento_exec bash -c "cd $MAGENTO_INST_DIR && php bin/magento cache:clean"

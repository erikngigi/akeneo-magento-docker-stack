#!/usr/bin/env bash

# Resolve the real path of this script (handles symlinks)
MAGENTO_SCRIPT_DIR="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"

# source the file with the magento details
source "$MAGENTO_SCRIPT_DIR/magento.env"

# Helper shell script for printing
source "$MAGENTO_SCRIPT_DIR/colors.sh"

# Define a reusable function for the Docker container magento
magento_exec() {
	docker exec -it "$1" "$@"
}

# Setup composer details for Magento repository
magento_exec bash -c "composer config --global http-basic.repo.magento.com $ADOBE_MAGENTO_USERNAME $ADOBE_MAGENTO_PASSWORD"
print_green "Magento composer details added succesfully."

# Download the Magento community edition files
magento_exec bash -c "composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition=$MAGENTO_VERSION $MAGENTO_INST_DIR"
print_green "Magento version $MAGENTO_VERSION downloaded succesfully."

# Set the file permissions and make Magento binary executable
magento_exec bash -c "
    find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +;
    find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+ws {} +;
    chmod +x bin/magento;
"
print_green "Update permissions of Magento directory"

# Setup magento
print_blue "Installing Magento version $MAGENTO_VERSION"
magento_exec bash -c "
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
--search-engine=$SEARCH_ENGINE \
--elasticsearch-host=$ELASTICSEARCH_HOST \
--elasticsearch-port=$ELASTICSEARCH_PORT \
"

print_green "Adding Magento composer authorization details"
magento_exec bash -c "
mkdir -p $COMPOSER_TARGET_FOLDER;
cp $COMPOSER_SOURCE_FILE $COMPOSER_TARGET_FOLDER;
"

# Disable Two factor authentication
print_green "Disabling Two factor authenication"
magento_exec bash -c "
php bin/magento module:disable Magento_AdminAdobeImsTwoFactorAuth;
php bin/magento module:disable Magento_TwoFactorAuth;
php bin/magento cache:flush;
"

# Remove old files
# print_green "Removing old magento system files"
# magento_exec bash -c "rm -rf var/cache/* var/page_cache/* var/generation/*"


# Reindex files
print_green "Reindexing Magento files"
magento_exec bash -c "bin/magento indexer:reindex"

# Switch to developer mode
print_green "Deploying Magento in developer mode."
magento_exec bash -c "php bin/magento deploy:mode:set developer;"

# Clear previously generated classes and proxies
magento_exec bash -c "rm -rf generated/code/* generated/metadata/*;"

# Deploy sample data modules
print_green "Deploying Magento sample data."
magento_exec bash -c "php bin/magento sampledata:deploy;"

# Upgrades the Magento application, DB data, and schema
print_green "Upgrade magento files"
magento_exec bash -c "php bin/magento setup:upgrade;"

# Recompile files
print_green "Recompile Magento files"
magento_exec bash -c "php bin/magento setup:di:compile"

# Deploy static view files
print_green "Deploy static files for Magento."
magento_exec bash -c "php bin/magento setup:static-content:deploy -f"

# Clean and flush cache
print_green "Clear cache"
magento_exec bash -c "
php bin/magento cache:clean;
php bin/magento cache:flush;
"

# Set permissions to the files
print_green "Update directory and file permissions."
magento_exec bash -c "
find . -type f -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \;
"

# Change Admin URL
print_green "Changing the Magento 2 Admin URL"
magento_exec bash -c "
yes | php bin/magento setup:config:set --backend-frontname='admin';
php bin/magento info:adminuri;
"

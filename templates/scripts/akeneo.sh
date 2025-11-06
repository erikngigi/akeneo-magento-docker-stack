#!/usr/bin/env bash

# Resolve the real path of this script (handles symlinks)
AKENEO_SCRIPT_DIR="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"

# Environmental file containing Akeneo details
source "$AKENEO_SCRIPT_DIR/akeneo.env"

# Helper shell script for printing
source "$AKENEO_SCRIPT_DIR/colors.sh"

# Define a reusable function for the Docker container
akeneo_exec() {
	docker exec -it "$1" "$@"
}

# Helper to execute commands inside the Akeneo installation directory
akeneo_exec_in_akeneo_dir() {
	docker exec -it "$1" bash -c "cd $AKENEO_INST_DIR && ${*:2}"
}

# Download Akeneo installation files using composer
print_green "Akeneo files were succesfully downloaded."
akeneo_exec bash -c "sudo chown -R $AKENEO_USER:$AKENEO_USER $AKENEO_INST_DIR"
akeneo_exec bash -c "composer create-project akeneo/pim-community-standard $AKENEO_INST_DIR '7.0.*@stable'"

# copy .env to .env.local
print_green "Akeneo environmental file was created."
akeneo_exec_in_akeneo_dir bash -c "cp .env .env.local"

# create an executable akeneo console application
akeneo_exec_in_akeneo_dir bash -c "chmod u+x bin/console"

# append details to .env.local file
print_green "Appending details to the Akeneo .env.local file"
akeneo_exec_in_akeneo_dir bash -c "
    sed -i 's/^APP_DATABASE_HOST=.*/APP_DATABASE_HOST=$MYSQL_AKENEO_DATABASE_HOST/' .env.local;
    sed -i 's/^APP_DATABASE_NAME=.*/APP_DATABASE_NAME=$MYSQL_AKENEO_DATABASE/' .env.local;
    sed -i 's/^APP_DATABASE_USER=.*/APP_DATABASE_USER=$MYSQL_AKENEO_USER/' .env.local;
    sed -i 's/^APP_DATABASE_PASSWORD=.*/APP_DATABASE_PASSWORD=$MYSQL_AKENEO_PASSWORD/' .env.local;
    sed -i 's/^APP_INDEX_HOSTS=.*/APP_INDEX_HOSTS=$APP_INDEX_HOSTS/' .env.local;
"

# Update browserlist
print_green "Updating Browserlist for Akeneo"
akeneo_exec_in_akeneo_dir bash -c "yes | npx update-browserslist-db@latest"

# Install akeneo
print_blue "Installing Akeneo"
akeneo_exec_in_akeneo_dir bash -c "NO_DOCKER=true make dev"

print_green "Creating User $AKENEO_USERNAME"
akeneo_exec_in_akeneo_dir bash -c "bin/console pim:user:create $AKENEO_USERNAME $AKENEO_PASSWORD $AKENEO_USER_EMAIL $AKENEO_FIRST_NAME $AKENEO_LAST_NAME $AKENEO_LOCALE --admin -n --env=dev"

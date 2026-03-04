#!/bin/bash

set -euo pipefail

FLYWAY_VERSION="${FLYWAY_VERSION:-7.15.0}"
FLYWAY_DIR="/flyway/flyway-${FLYWAY_VERSION}"
MIGRATOR_USERNAME="${PGUSER:-postgres}"

if [[ ! -d "${FLYWAY_DIR}" ]]; then
    echo "Failed to locate Flyway install at ${FLYWAY_DIR}"
    exit 1
fi

cd "${FLYWAY_DIR}"

del_completed_scripts () {
    echo "Attempt to exclude previously executed scripts..."
    local dbName=$(basename "${1}")
    local item=""
    local retCode=0
    local SUCCESS_SCRIPTS=""

    SUCCESS_SCRIPTS=`psql -t -A -h "${DB_HOST}" -c "SELECT script FROM schema_version WHERE success=TRUE" ${dbName} -t` || retCode=$?

    if [[ $retCode -eq "1" ]]; then
        echo "Failed to locate schema version info. Proceed to process all migration scripts..."
    else
        for item in ${1}/*; do
            item=$(basename "${item}")
            if [[ -f "${1}/${item}" ]] && [[ "${SUCCESS_SCRIPTS[*]}" =~ "${item}" ]]; then
                echo "Skip ${item} as it has been sccessfully run previously..."
                rm -Rf ${1}/${item}
            fi
        done
    fi
}

for d in /flyway/sql/*; do
    if [[ -d "$d" ]]; then
        echo "Creating database $(basename "$d") (this will fail if it already exists; that's ok)"
        psql -h "${DB_HOST}" -c "CREATE DATABASE $(basename "$d") WITH OWNER = ${MIGRATOR_USERNAME} CONNECTION LIMIT = -1;" postgres
        
        echo "Migrating database $(basename "$d")..."

        del_completed_scripts "${d}"
        
        if [ -z "$(ls -A ${d})" ]; then
            echo "All scripts have been successfully run previously."
            echo "No need to take migration actions."
        else
            echo "Processing migration scripts in ${d}..."
            ./flyway migrate -ignoreMissingMigrations=true -baselineOnMigrate=true -url=jdbc:postgresql://"${DB_HOST}"/$(basename "$d") -locations=filesystem:$d -user=${MIGRATOR_USERNAME} -password=${PGPASSWORD} -placeholders.clientUserName="${CLIENT_USERNAME}" -placeholders.clientPassword="${CLIENT_PASSWORD}" -n
        fi
    fi
done

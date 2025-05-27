#!/bin/bash
set -eu

# set all variables
export PGHOST PGPORT PGUSER PGPASSWORD
[ -n "$PGHOST" ] || echo "ENTRY - PGHOST and possibly other PG variables are not set!"
: ${ODOO_BASEPATH:=/opt/odoo}
ODOO_BIN="$ODOO_BASEPATH/odoo-bin"
: ${ODOO_BASE_ADDONS:=/opt/odoo-addons}
: ${ODOO_EXTRA_ADDONS:=/mnt/extra-addons}
EXTRA_ADDONS_PATHS=$(odoo-getaddons.py ${ODOO_EXTRA_ADDONS} ${ODOO_BASE_ADDONS} ${ODOO_BASEPATH})

if [ ! -f "${ODOO_RC}" ]
then
    echo "ENTRY - Generate $ODOO_RC"
    cat > $ODOO_RC <<EOF
[options]
addons_path = ${EXTRA_ADDONS_PATHS}
admin_passwd = ${ADMIN_PASSWORD:-admin}
EOF
fi

if [ -n "$EXTRA_ADDONS_PATHS" ]
then
    echo "ENTRY - Addons paths: $EXTRA_ADDONS_PATHS"
fi
if [ -n "$EXTRA_ADDONS_PATHS" ] && [ "${PIP_AUTO_INSTALL:-0}" -eq "1" ]
then
    for ADDON_PATH in "$ODOO_BASE_ADDONS" "$ODOO_EXTRA_ADDONS"
    do
        [ -d "$ADDON_PATH" ] || continue
        echo "ENTRY - Auto install requirements.txt from $ADDON_PATH"
        find "$ADDON_PATH" -name 'requirements.txt' -exec pip3 install --break-system-packages --user -r {} \;
    done
fi

# if we have an odoo command, just prepend odoo
case "${1:-}" in
    scaffold | shell | -*)
        set -- odoo "$@"
        ;;
esac

# dispatch the command
case "${1:-}" in
    -- | odoo | odoo-* | "")
        INIT_DATABASE=0
        case "${1:-}" in
        -- | odoo | odoo-bin | "")
            shift
            INIT_DATABASE=1
            ;;
        odoo-test)
            shift
            ODOO_BIN=$(which odoo-test)
            : ${BASE_MODULES:=base}
            echo "ENTRY - Enable testing"
            UPGRADE_ENABLE=0
            ;;
        *)
            ODOO_BIN=$(which "$1")
            shift
            ;;
        esac

        if [[ "${1:-}" == "scaffold" ]]
        then
            exec "$ODOO_BIN" "$@"
            exit $?
        fi

        echo "ENTRY - Wait for postgres"
        PGDATABASE=postgres wait-for-psql.py

        if [ "${UPGRADE_ENABLE:-0}" == "1" ]
        then
            ODOO_DB_LIST=$(psql -X -A -d postgres -t -c "SELECT STRING_AGG(datname, ' ') FROM pg_database WHERE datdba=(SELECT usesysid FROM pg_user WHERE usename=current_user) AND NOT datistemplate and datallowconn AND datname <> 'postgres'")
            for db in ${ODOO_DB_LIST}
            do
                echo "ENTRY - Update database: ${db}"
                click-odoo-update --ignore-core-addons -d "$db" -c "$ODOO_RC" --log-level=error
                echo "ENTRY - Update database finished"
            done
        fi

        if [ "${INIT_DATABASE:-0}" == "1" ]
        then
            export PGDATABASE=${PGDATABASE:=odoo}
            if [ -n "${INSTALL_MODULES:-}" ] && echo "ENTRY - Check DB exists" && ! PGTIMEOUT=2 wait-for-psql.py
            then
                echo "ENTRY - Initialize database $PGDATABASE: ${INSTALL_MODULES}"
                odoo-update "$INSTALL_MODULES" "--install" "--load-language=${INSTALL_LANGUAGES:-}"
            fi
        fi

        if [ "${DEBUGPY_ENABLE:-0}" == "1" ]
        then
            echo "ENTRY - Enable debugpy"
            set -- python3 -m debugpy --listen "0.0.0.0:41234" "$ODOO_BIN" "$@" --workers 0 --limit-time-real 100000
        else
            set -- "$ODOO_BIN" "$@"
        fi
        echo "$@"
        echo "ENTRY - Start odoo..."
        exec "$@"
        ;;
    *)
        exec "$@"
esac

exit 1

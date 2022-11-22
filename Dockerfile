from ubuntu:20.04 as base
shell ["/bin/bash", "-xo", "pipefail", "-c"]
# https://www.odoo.com/documentation/master/administration/install.html

# Generate locale C.UTF-8 for postgres and general locale data
env LANG C.UTF-8

# Install dependencies (non-interactive flag for tzdata)
# - python and build essentials
# - Odoo's dependencies
# - postgres-client
# - rtlcss (right-to-left text, skipped)
# - wkhtmltox and fonts dependencies
# - system tools
run apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        python3 python3-pip build-essential \
        python3-dev libxml2-dev libxslt1-dev libldap2-dev libsasl2-dev \
        libtiff5-dev libjpeg8-dev libopenjp2-7-dev zlib1g-dev libfreetype6-dev \
        liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev libpq-dev \
        postgresql-client \
        fontconfig libx11-6 libxext6 libxrender1 \
        xfonts-75dpi xfonts-base \
        ca-certificates curl git openssh-client \
    && rm -rf /var/lib/apt/lists/*
run curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.focal_amd64.deb \
    && echo 'ae4e85641f004a2097621787bf4381e962fb91e1 wkhtmltox.deb' | sha1sum -c - \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Install/Clone Odoo
# If using HTTPS clone:
arg ODOO_SOURCE=https://github.com/odoo
# If using SSH clone:
# arg ODOO_SOURCE=git@github.com:odoo
# run mkdir -p -m 0600 ~/.ssh && ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
# run --mount=type=ssh git clone ...
arg ODOO_VERSION=16.0
arg ODOO_DATA_DIR=/var/lib/odoo
env ODOO_VERSION=${ODOO_VERSION}
env ODOO_BASEPATH=/opt/odoo
run git clone --quiet --depth 1 "--branch=$ODOO_VERSION" $ODOO_SOURCE/odoo.git \
    ${ODOO_BASEPATH} && rm -rf ${ODOO_BASEPATH}/.git
run pip install --prefix=/usr/local --no-cache-dir --upgrade -r ${ODOO_BASEPATH}/requirements.txt

# Create user and mounts
# /var/lib/odoo for filestore and HOME
# /mnt/extra-addons for users addons
env ODOO_RC /etc/odoo/odoo.conf
env ODOO_BASE_ADDONS=/opt/odoo-addons
env ODOO_EXTRA_ADDONS=/mnt/extra-addons
env PYTHON_DIST_PACKAGES=/usr/lib/python3/dist-packages
run mkdir -p /etc/odoo \
    && mkdir -p "${ODOO_BASE_ADDONS}" "${ODOO_EXTRA_ADDONS}" "${ODOO_DATA_DIR}" \
	&& useradd --system --no-create-home --home-dir "${ODOO_DATA_DIR}" --shell /bin/bash odoo \
    && chown -R odoo:odoo /etc/odoo "${ODOO_BASE_ADDONS}" "${ODOO_EXTRA_ADDONS}" "${ODOO_DATA_DIR}" \
    && chmod 775 /etc/odoo "${ODOO_DATA_DIR}" \
    && echo "$ODOO_BASEPATH" > "$PYTHON_DIST_PACKAGES/odoo.pth" \
    && ln -s "${ODOO_BASEPATH}/odoo-bin" /usr/bin/odoo
volume ["${ODOO_DATA_DIR}"]

# Expose Odoo services
expose 8069 8071 8072

# Copy entrypoint script and Odoo configuration file
run pip install --prefix=/usr/local --no-cache-dir click-odoo click-odoo-contrib debugpy
env PGHOST=db
env PGPORT=5432
env PGUSER=odoo
env PGPASSWORD=odoo
copy resources/wait-for-psql.py resources/odoo-* /usr/local/bin/
copy resources/entrypoint.sh /
entrypoint ["/entrypoint.sh"]

###############################
# ODOO
from base as odoo
user odoo
cmd ["odoo-bin"]
healthcheck cmd curl --fail http://127.0.0.1:8069/web_editor/static/src/xml/ace.xml || exit 1
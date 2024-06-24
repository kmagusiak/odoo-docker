# https://www.odoo.com/documentation/master/administration/install.html
# Multi-stage build:
# 1. Define system targets (different OS versions)
# 2. Install odoo-community with dependencies
# 3. Final targets: odoo, odoodev, enterprise, etc.

###########################################################
# SYSTEM
# always set UTF-8 locale qnd redirect python output to stdout

arg SYSTEM_BASE=ubuntu:24.04
from ${SYSTEM_BASE} as system
shell ["/bin/bash", "-xo", "pipefail", "-c"]
env LANG C.UTF-8
env PYTHONUNBUFFERED=1

# Install dependencies (non-interactive flag for tzdata)
# - python and build essentials
# - Odoo's dependencies
# - postgres-client
# - rtlcss (right-to-left text, skipped)
# - wkhtmltox and fonts dependencies (unzip for wkhtmltox)
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
        unzip \
    && rm -rf /var/lib/apt/lists/*

# wkhtmltopdf https://github.com/wkhtmltopdf/packaging/issues/114 for Jammy (Ubuntu 22.04)
run curl -o wkhtmltox.zip -sSL https://github.com/wkhtmltopdf/packaging/files/8632951/wkhtmltox_0.12.5-1.jammy_amd64.zip \
    && unzip wkhtmltox.zip && rm wkhtmltox.zip && mv wkhtmlto*.deb wkhtmltox.deb \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb
# alternative installation version (for debian; libssl1.1 is missing - libssl3 is installed)
#run curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.buster_amd64.deb \
#    && echo 'ea8277df4297afc507c61122f3c349af142f31e5 wkhtmltox.deb' | sha1sum -c - \
#    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
#    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

###########################################################
# INSTALL ODOO

from system as base
# Install/Clone Odoo
arg ODOO_SOURCE=https://github.com/odoo
# arg ODOO_SOURCE=git@github.com:odoo
arg ODOO_VERSION=master
arg ODOO_DATA_DIR=/var/lib/odoo
env ODOO_VERSION=${ODOO_VERSION}
env ODOO_BASEPATH=/opt/odoo
run mkdir -p -m 0600 ~/.ssh && ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
run --mount=type=ssh git clone --quiet --depth 1 "--branch=$ODOO_VERSION" $ODOO_SOURCE/odoo.git \
    ${ODOO_BASEPATH} && rm -rf ${ODOO_BASEPATH}/.git
# Add additional python libraries
# - optional Odoo libraries (for most commonly used modules)
# - versions compatibility
# - click tools
# - debug tools
run pip install --prefix=/usr --no-cache-dir --upgrade \
    -r ${ODOO_BASEPATH}/requirements.txt \
    geoip2 pdfminer.six phonenumbers python-magic python-slugify \
    click-odoo click-odoo-contrib \
    debugpy py-spy

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
    && echo "${ODOO_BASEPATH}" > "$PYTHON_DIST_PACKAGES/odoo.pth" \
    && ln -s "${ODOO_BASEPATH}/odoo-bin" /usr/bin/odoo-bin
volume ["${ODOO_DATA_DIR}"]

# Copy entrypoint script and set entry points
copy resources/wait-for-psql.py resources/odoo-* /usr/local/bin/
copy resources/entrypoint.sh /
entrypoint ["/entrypoint.sh"]
expose 8069 8071 8072
env PGHOST=db
env PGPORT=5432
env PGUSER=odoo
env PGPASSWORD=odoo

###########################################################
# FINAL TARGETS

###############################
# ODOO
from base as odoo
user odoo
cmd ["odoo-bin"]

###############################
# DEVELOPMENT
from odoo as odoodev
user root

run apt-get update \
	&& apt-get install -y --no-install-recommends \
	    bash-completion gettext git htop less openssh-client vim
# chrome for testing
run curl https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb --output /tmp/google-chrome.deb \
	&& apt-get install -y --no-install-recommends /tmp/google-chrome.deb \
	&& rm /tmp/google-chrome.deb
# additional development tools
run pip install --prefix=/usr --no-cache-dir \
    debugpy \
    ipython jupyterlab \
    black flake8 isort pylint-odoo pytest-odoo websocket-client

user odoo

###############################
# ENTERPRISE
from odoo as enterprise
user root

# Clone Odoo themes
run --mount=type=ssh git clone --quiet --depth 1 "--branch=$ODOO_VERSION" $ODOO_SOURCE/design-themes.git \
    ${ODOO_BASE_ADDONS}/odoo-themes && rm -rf ${ODOO_BASE_ADDONS}/odoo-themes/.git

# Clone Odoo enterprise sources
run --mount=type=ssh git clone --quiet --depth 1 "--branch=$ODOO_VERSION" $ODOO_SOURCE/enterprise.git \
    ${ODOO_BASE_ADDONS}/enterprise && rm -rf ${ODOO_BASE_ADDONS}/enterprise/.git

user odoo

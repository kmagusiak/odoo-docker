# Odoo docker image

Build a docker image with Odoo for local development and test purposes.

See [odoo-vscode](https://github.com/kmagusiak/odoo-vscode)
for a working dev environment.

# Using the image

## Building your own image

You can fork this repository and adapt the files as you wish.
In the [extending](./extending/README.md) directory, you will find examples.

A github action builds a docker image that can be used for development
and testing.
https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry

## Running and tests

Additionally to the `odoo` command which is set up to start the
instance with the generated configuration, there are other commands available.

- `odoo-update` installs or updates a list of modules
- `odoo-test` (re)creates a new database and runs odoo tests
- `odoo-getaddons.py` lists addon paths or addons with `-m`

You can use [click-odoo-contrib] to backup, restore, copy databases and
related jobs.
It provides also `click-odoo-initdb` or `click-odoo-update` to update
installed modules and other useful tools.

	# run the container
	docker-compose up

	# inside the container
	odoo shell  # get to the shell
	odoo-update sale --install --load-languages=en_GB
	# test using
	odoo-test -t -a template_module -d test_db_1

	# using docker-compose
	docker-compose -f docker-compose.yaml -f docker-compose.test.yaml run --rm odoo

Odoo binds user sessions to the URL in `web.base.url`.
So, if you *run containers on different ports*, you should probably use
`127.0.0.1:port` instead of `localhost`.

## Connecting to the database

Either get into the container directly with `docker-compose exec db bash`.
The default postgresql environment variables are set: PGHOST, PGUSER, etc.

## Backup and restore database

If you restore from an SQL file (odoo.sh), you can use directly
the postgres tools to restore the database.
After restoring the database, you might want to run the *reset* command
to set the password and check system properties.
The password is set to "admin" for all users.

	# env
	source .env
	DB_TEMPLATE=dump

	# load the dump
	dropdb --if-exists "$DB_TEMPLATE" && createdb "$DB_TEMPLATE"
	psql "$DB_TEMPLATE" < dump.sql

	# create your copy
	dropdb --if-exists "$DB_NAME" && createdb "$DB_NAME" -T "$DB_TEMPLATE"
	psql "$DB_NAME" < /usr/local/bin/odoo-reset-db.sql
	click-odoo-update --ignore-core-addons

# Image contents

## Paths

- ODOO_BASEPATH (`/opt/odoo`) where you find Odoo source code
- ODOO_BASE_ADDONS where you find addons bundled in the image
  like *enterprise*, *themes*, etc.
- ODOO_EXTRA_ADDONS where you find your addons

## The Dockerfile

Starting from an Ubuntu image, we install the required tools and clone
the official Odoo repository.
We install `click-odoo-contrib` and `debugpy`;
replace the entrypoint and add a *health check* to the image.

You can set up environment variables in `.env` file.
These are loaded into the odoo container and a configuration file is generated
every time the container starts at `/etc/odoo/odoo.conf`.

Odoo addons path is discovered from the paths where addons can be built.
Some other variables control the startup:
- DB_NAME: the default database is `odoo`.
- WITHOUT_DEMO: don't install demo data (default: true)
- PIP_AUTO_INSTALL: discover *requirements.txt* files in addons folders and
  install them when starting the container (default: true)
- UPGRADE_ENABLE: when starting, run `click-odoo-update` (default: false)
  - INSTALL_MODULES: modules to install when creating the database (default: none)
  - LOAD_LANGUAGES: languages to load during installation
- DEBUGPY_ENABLE: run odoo with `debugpy`

# Credits

Based on:

* [dockerdoo]
* [Odoo] ([odoo-docker])
* [OCA] ([maintainer-quality-tools](https://github.com/OCA/maintainer-quality-tools))
* [click-odoo-contrib]


[click-odoo-contrib]: https://github.com/acsone/click-odoo-contrib
[dockerdoo]: https://github.com/iterativo-git/dockerdoo
[OCA]: https://github.com/OCA
[Odoo]: https://github.com/odoo
[odoo-docker]: https://github.com/odoo/docker

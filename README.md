# Odoo docker image

Build a docker image with Odoo for local development and test purposes.

See [odoo-vscode](https://github.com/kmagusiak/odoo-vscode)
for a working dev environment.

# Using the image

## Building your image

A github action builds a docker image that can be used for development
and testing.
https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry

You can clone this repository and adapt the files as you wish.
In the [extending](./extending/README.md) directory, you will find examples.

## Backup and restore database

You can use [click-odoo-contrib] to backup, restore, copy databases and
related jobs.
It is installed on the odoo container, so you could just mount a
`/mnt/backup` folder and use it for files.

You can also use `click-odoo-initdb` or `click-odoo-update` to update
installed modules.

## Running and tests

	# run the container
	docker-compose up

	# inside the devcontainer
	odoo --test-enable --stop-after-init -i template_module -d test_db_1
	# alternatively
	odoo-test -t -a template_module -d test_db_1

	# using docker-compose
	docker-compose -f docker-compose.yaml -f docker-compose.test.yaml run --rm odoo

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

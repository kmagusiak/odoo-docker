# Odoo docker image

Build a docker image with Odoo for local development and test purposes.
See [odoo-vscode](https://github.com/kmagusiak/odoo-vscode)
for a working dev environment *(not only for vscode)*.

[![Package](https://img.shields.io/badge/package-ghcr.io-blue)](https://github.com/kmagusiak/odoo-docker/pkgs/container/odoo-docker)


# Using the image

## Building your own image

You can fork this repository and adapt the files as you wish.
In the [extending](./extending/README.md) directory, you will find examples
to build an image with enterprise or other private repositories included.

## Running and tests

Additionally to the `odoo-bin` command which is set up to start the
instance with the generated configuration, there are other commands available.

- `odoo-update` installs or updates a list of modules
- `odoo-test` (re)creates a new database and runs Odoo tests
- `odoo-getaddons.py` lists addon paths or addons with `-m`
- [click-odoo-contrib] tools

```bash
# run the container
docker-compose up

# inside the container
odoo-bin shell  # get to the shell
odoo-update sale --install --load-languages=en_GB
odoo-test -t -a template_module -d test_db_1

# test using docker-compose
docker-compose -f docker-compose.yaml -f docker-compose.test.yaml run --rm odoo
```

Odoo binds user sessions to the URL in `web.base.url`.
If you *run containers on different ports*, you may need to use
`127.0.0.1:port` or host aliases instead of `localhost`.

## Connecting to the database

Either get into the container directly with `docker-compose exec db bash` or
use `psql` from the Odoo container.

The default postgresql environment variables are set: PGHOST, PGUSER, etc.
You can use directly the postgres tools to restore the database.

# Image contents

## Paths

- `ODOO_BASEPATH` (`/opt/odoo`) where you find Odoo source code
- `ODOO_BASE_ADDONS` (`/opt/odoo-addons`) where you find addons bundled
  in the image like *enterprise*, *themes*, etc.
- `ODOO_EXTRA_ADDONS` where you can mount additional addons

## The Dockerfile

Starting from an Ubuntu image, we install the required tools and install like
on-remise source install using pip ([odoo install guide]).
We install various tools such as `click-odoo-contrib` and `debugpy`;
other development tools are pre-installed for testing.

You can set up environment variables in `.env` file.
When the container starts, it generates the configuration `/etc/odoo/odoo.conf`
file based on the environment variables.

Odoo addons path is discovered from the paths where addons can be built.
Some other variables control the startup:
- `PGDATABASE`: the default database is `odoo`.
- `ODOO_WITH_DEMO`: install demo data (default: true)
- `PIP_AUTO_INSTALL`: discover *requirements.txt* files in addons folders and
  install them when starting the container (default: true)
- `UPGRADE_ENABLE`: when starting, run `click-odoo-update` (default: false)
  - `INSTALL_MODULES`: modules to install when creating the database (default: none)
  - `LOAD_LANGUAGES`: languages to load during installation
- `DEBUGPY_ENABLE`: run odoo with `debugpy` for remote debugging

# Credits

Based on:

* [dockerdoo]
* [Odoo] ([odoo-docker] - oriented for deployments)


[click-odoo-contrib]: https://github.com/acsone/click-odoo-contrib
[dockerdoo]: https://github.com/iterativo-git/dockerdoo
[OCA]: https://github.com/OCA
[Odoo]: https://github.com/odoo
[odoo-docker]: https://github.com/odoo/docker
[odoo install guide]: https://www.odoo.com/documentation/master/administration/on_premise/source.html

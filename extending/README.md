# How to use this repository

You can use the Dockerfiles present in this repository as well as the build
script for the github action.

## Access to private repositories (SSH)
You will need access to private repositories in github, this can be done either
by using *private access tokens* and passing them in the URL or by using
SSH keys.
We use the SSH keys as they don't appear in the executed commands.

	eval $(ssh-agent)  # if the agent is not running yet
	ssh-add  # add your private key in the agent
	# build
	docker-compose build --ssh default

For github actions, generate a private key and add it to the secrets of the project.

## Alternative *Dockerfile.odoo-based* (unmaintained)
We are starting from the [official Odoo docker image](https://github.com/odoo/docker).
We move Odoo sources to `/opt/odoo` (ODOO_BASEPATH) so that you can easily
mount your own sources.

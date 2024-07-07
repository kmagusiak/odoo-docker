# How to use this repository

You can use the Dockerfiles present in this repository as well as the build
script for the github action.
The files show how to build private repositories, since *enterprise* is not
publicly available.

The recommended way of building your images is to:
- Fork this repository
- Append Docker *targets* in the main `Dockerfile`
- Replace or adapt the github build workflow

## Health-check
You can add a *health check* if you need it for production.

```
healthcheck cmd curl --fail http://127.0.0.1:8069/web_editor/static/src/xml/ace.xml || exit 1
```

## Access to private repositories (SSH)
You will need access to private repositories in github, this can be done either
by using *private access tokens* and passing them in the URL or by using
SSH keys.
We use the SSH keys as they don't appear in the executed commands.

```bash
eval $(ssh-agent)  # if the agent is not running yet
ssh-add  # add your private key in the agent
# build
docker-compose build --ssh default
```

For github actions, generate a private key and add it to the secrets of the
project.

## Github action to build image
A github action builds a docker image that can be used for development
and testing.
https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry

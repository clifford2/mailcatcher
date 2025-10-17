# MailCatcher Container Build

This image can easily be built by either `podman` or `docker`.

## Bump Versions

After any change, please increment the `RELEASE_VERSION` in the `.env` file,
and run (optional - also a dependency for `make git-push`):

```sh
make fixtags
```

## Build

Build the image with podman:

```sh
make build
```

Alternately, build with docker:

```sh
make CONTAINER_ENGINE=docker build
```

## Publish

Publish new source (fix tags, commit, tag, push) with these commands:

```sh
make git-push
```

No need to publish the container image to GHCR / Docker Hub
(`make docker-push`) - this is done by GitHub Actions.

## Run & Test

Start container, send test message, and open web interface:

```sh
make run
```

See [`README.md`](README.md) for more details.

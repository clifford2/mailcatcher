# MailCatcher Container Build

This image can easily be built by either `podman` or `docker`.

## Bump Versions

After any change, please increment the `RELEASE_VERSION` in the `.env` file, and run:

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

Publish new source with these commands:

```sh
make git-push
```

Publish the container image to Docker Hub with:

```sh
make docker-push
```

## Run & Test

See `README.md`.

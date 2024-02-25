# MailCatcher Container Build

This image can easily be built by either `docker` or `podman`.

## Bump Versions

After any change, please increment the `RELEASE_VERSION` in the `.env` file, and run the following commands:

```sh
source .env
sed -i -e "s|^ARG MAILCATCHER_VERSION=..*$|ARG MAILCATCHER_VERSION="${MAILCATCHER_VERSION}"|" Dockerfile
sed -i -e "s|^podman run \(..*\) ${IMAGE_NAME}:..*$|podman run \1 ${IMAGE_NAME}:${MAILCATCHER_VERSION}-${RELEASE_VERSION}|" DEVELOP.md
sed -i -e "s|^podman run \(..*\) ${IMAGE_NAME}:..*$|podman run \1 ${IMAGE_NAME}:${MAILCATCHER_VERSION}-${RELEASE_VERSION}|" README.md
sed -i -e "s|image: ${IMAGE_NAME}:..*$|image: ${IMAGE_NAME}:${MAILCATCHER_VERSION}-${RELEASE_VERSION}|" docker-compose.yml
```

## Build

Before building, please update `RELEASE_VERSION` in the `.env` file if necessary.

Steps to build the image (replace `podman` with `docker` if preferred):

```sh
source .env
podman build --pull -t ${IMAGE_NAME}:${IMAGE_TAG} .
```

## Package

Before packaging, please update `RELEASE_VERSION` in the `.env` file.

Then run these commands:

``sh
source .env
git add .
git commit
git tag "${MAILCATCHER_VERSION}-${RELEASE_VERSION}"
git push
``


## Run

Run with (replace `podman` with `docker` if preferred):

```
podman run -d --rm -p 2525:2525 -p 8080:8080 --name mailcatcher docker.io/cliffordw/mailcatcher:0.9.0-release.3
```

## Test

Tools for testing email sending:

- `socat - TCP4:0.0.0.0:2525`
- `netcat 0.0.0.0 2525`
- `telnet 0.0.0.0 25`

Example commands to test sending:

```sh
MSG="HELO mailcatcher.example.com\nMAIL FROM: mailcatcher@example.com\nRCPT TO: clifford@example.org\nDATA\nSubject: CLI Test Message\nContent-Type: text/plain\n\nHello Buddy\n\nWhat's up?\n\nRegards,\nMailCatcher\n.\nquit\n"
echo -e "$MSG" | socat - TCP4:0.0.0.0:2525
podman exec mailcatcher sh -c "echo -e \"$MSG\" | nc 0.0.0.0 2525
```

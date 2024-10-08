# MailCatcher

## About

[MailCatcher](https://mailcatcher.me/) runs a super simple SMTP server which
catches any message sent to it to display in a web interface.
Great for development and testing!

This image is only ~80MB. It is based on
[Dietrich Rordorf](https://hub.docker.com/r/rordi/docker-mailcatcher/)'s
version, and customized mostly to modify the start command, and run as a
non-root user.

## Usage

To use this, run the container with:

```sh
podman run -d --rm -p 2525:2525 -p 8080:8080 --name mailcatcher docker.io/cliffordw/mailcatcher:0.10.0-release.1
```

Then configure your application to deliver mail to SMTP port 2525.

```sh
podman exec -it mailcatcher hello
```

View the caught emails in the web interface at <http://localhost:8080/>.

## Resources

- MailCatcher source code: <https://github.com/sj26/mailcatcher>
- Container image available at: <https://hub.docker.com/r/cliffordw/mailcatcher>
- Docker build based on <https://github.com/rordi/docker-mailcatcher>

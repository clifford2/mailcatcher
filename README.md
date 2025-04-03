# MailCatcher

## About

[MailCatcher](https://mailcatcher.me/) runs a super simple SMTP server
which catches any message sent to it to display in a web interface.
Great for development and testing!

This code packages MailCatcher as a container image.
This image is only ~75 MB. It is based on
[Dietrich Rordorf](https://github.com/rordi/docker-mailcatcher)'s
Dockerfile, and customized to:

- Modify the start command
- Run as a non-root user
- Pin software versions to create immutable images

## Usage

### Start the container

To use this, run the container with `podman` (or replace `podman` with `docker` if preferred):

```sh
podman run -d --rm -p 2525:2525 -p 8080:8080 --name mailcatcher ghcr.io/clifford2/mailcatcher:0.10.0-8
```

### Sending email

Configure your application to deliver mail to SMTP port 2525.

You can send a test email with our `hello` test script (uses netcat):

```sh
podman exec -it mailcatcher hello
```
Additional tools for testing email sending include:

- `socat - TCP4:0.0.0.0:2525`
- `netcat 0.0.0.0 2525`
- `telnet 0.0.0.0 2525`

Example commands for socat / netcat:

```sh
MSG="HELO mailcatcher.example.com\nMAIL FROM: mailcatcher@example.com\nRCPT TO: clifford@example.org\nDATA\nSubject: CLI Test Message\nContent-Type: text/plain\n\nHello Buddy\n\nWhat's up?\n\nRegards,\nMailCatcher\n.\nquit\n"
echo -e "$MSG" | socat - TCP4:0.0.0.0:2525
podman exec mailcatcher sh -c "echo -e \"$MSG\" | nc 0.0.0.0 2525
```

### Web Interface

View the caught emails in the web interface at <http://localhost:8080/>.

## Resources

- MailCatcher source code: <https://github.com/sj26/mailcatcher>
- Container image available at:
	- [`ghcr.io/clifford2/mailcatcher`](https://github.com/clifford2/mailcatcher/pkgs/container/mailcatcher)
	- [`docker.io/cliffordw/mailcatcher`](https://hub.docker.com/r/cliffordw/mailcatcher)
- Docker build based on <https://github.com/rordi/docker-mailcatcher>
- `.msmtprc`: Sample config file for [msmtp](https://marlam.de/msmtp/)
- `ssmtp.conf`: Sample config file for `ssmtp`

## License & Disclaimer

This code is shared under the MIT License.

The original Dockerfile is © 2016 Dietrich Rordorf <dr@ediqo.com>.

Modifications, and all other files are © Clifford Weinmann <https://www.cliffordweinmann.com/>.

This code is provided *AS IS*, without warranty of any kind.
See [`LICENSES/MIT.txt`](LICENSES/MIT.txt) for the full license text and disclaimer.

## Security

This code is updated as often as possible, but support is provided on a best effort basis only.

Please report any problems or vulnerabilities by opening a [GitHub issue here](https://github.com/clifford2/mailcatcher/issues).

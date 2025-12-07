# MailCatcher

## About

[MailCatcher](https://mailcatcher.me/) runs a super simple SMTP server
which catches any message sent to it to display in a web interface.
Great for development and testing!

This code packages MailCatcher as a container image.
This image is based on
[Dietrich Rordorf](https://github.com/rordi/docker-mailcatcher)'s
Dockerfile, and customized to:

- Modify the start command
- Run as a non-root user
- Pin software versions to create immutable images
- Add netcat & ssmtp for testing

## Usage

### Start the container

To use this, exposing the SMTP and HTTP services on unprivileved ports,
run the container with `podman` (ideally as a non-root user):

```sh
podman run --detach --rm \
  --publish 2525:2525 \
  --publish 8080:8080 \
  --name mailcatcher \
  ghcr.io/clifford2/mailcatcher:0.10.0-11.20251207
```

To run it with Docker, simply replace `podman` with `docker` in the above command (and other examples below).

Some tools may be easier to test if the SMTP service is running on port **587** ([RFC 6409](https://datatracker.ietf.org/doc/html/rfc6409) or **25**. To do that, simply change the hostPort (first number) in the above `--pushlish` arguments. Let's run the web server on port 80 too ;-). Here's an example:

```sh
podman run --detach --rm \
  --publish 587:2525 \
  --publish 80:8080 \
  --name mailcatcher \
  ghcr.io/clifford2/mailcatcher:0.10.0-11.20251207
```

### Sending email

Here are some examples of how to send email to MailCatcher. These examples assume you're running the server on port 2525. Please change the port number (in the commands below, or in your config files), if you're using a different port.

You can send a test email with our `hello` test script (uses netcat):

```sh
podman exec -it mailcatcher hello
```

Additional tools for testing email sending (assuming we're using SMTP port 2525) include:

- `socat - TCP4:0.0.0.0:2525`
- `netcat 0.0.0.0 2525`
- `telnet 0.0.0.0 2525`

Example commands for socat / netcat:

```sh
MSG="HELO mailcatcher.example.com\nMAIL FROM: mailcatcher@example.com\nRCPT TO: clifford@example.org\nDATA\nSubject: CLI Test Message\nContent-Type: text/plain\n\nHello Buddy\n\nWhat's up?\n\nRegards,\nMailCatcher\n.\nquit\n"
echo -e "$MSG" | socat - TCP4:0.0.0.0:2525
podman exec mailcatcher sh -c "echo -e \"$MSG\" | nc 0.0.0.0 2525
```

Example using `ssmtp` & our sample config file:

```sh
MSG="Subject: CLI Test Message\nContent-Type: text/plain\n\nHi Bob,\n\nWa Gwaan?\n\nRegards,\nMailCatcher"
echo -e "$MSG" | ssmtp -C ssmtp.conf bob@marley.invalid
# or
echo -e "$MSG" | podman exec -i mailcatcher ssmtp bob@marley.invalid
```

Of course you can also configure your favourite email application to use MailCatcher as outgoing mail server / relay.

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

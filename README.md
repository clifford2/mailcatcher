[MailCatcher](https://mailcatcher.me/) runs a super simple SMTP server which
catches any message sent to it to display in a web interface.
Great for development and testing!

This image is only ~32MB. It is based on
[Dietrich Rordorf](https://hub.docker.com/r/rordi/docker-mailcatcher/)'s
version, and customized mostly to modify the start command, and run as a
non-root user.

To use this, pull the image from Docker Hub, and run with:

	docker run -d --rm -p 2525:2525 -p 8080:8080 cliffordw/mailcatcher

Then configure your application to deliver mail to SMTP port 2525, and
view the caught emails in the web interface at <http://localhost:8080/>.

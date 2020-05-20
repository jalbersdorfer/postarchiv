# How to host a Python Flask App in lighttpd using uWSGI

The following describes how to run a python3 Flask App in lighttpd Webserver using the uWSGI Application Gateway Server.

Do the following in something like `tmux`, where you can start further virtual Terminals

## Create the Python Flask App

```bash
$ mkdir -p /home/pi/flask/
$ touch /home/pi/flask/flaskApp.py
$ vim /home/pi/flask/flaskApp.py
```

paste the following into it:

```python
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello_world():
        return 'Hello, World!'

if __name__ == '__main__':
    app.run()
```

Save and Quit using `ESC :wq`

## Create virtualenv

```bash
$ python3 -m venv /home/pi/.virtualenvs/flask
$
```

## Activate the virtualenv

```bash
$ source /home/pi/.virtualenvs/flask/bin/activate
(flask) $
```

## Install Flask (into the flask venv)

```bash
(flask) $ pip install flask
```

## Start a separate Terminal to continue

in tmux ... `[Ctrl]+[B] [Shift]+[2]`

## Run the uWSGI Server

```bash
$ sudo uwsgi \
  -s /run/www-data/flaskApp.sock \
  --plugin python3 \
  --wsgi-file /home/pi/flask/flaskApp.py \
  --uid 33 --gid 33 \
  --manage-script-name \
  --mount /=flaskApp:app \
  --virtualenv /home/pi/.virtualenvs/flask
```

- `--mount /=flaskApp:app`: `flaskApp` = name of the file, `app` = name of the Flask App Instance

## lighttpd

`/etc/lighttpd/conf-enabled/10-uwsgi.conf`

```conf
server.modules += ("mod_scgi")

$HTTP["url"] =~ "^/uwsgi/" {
    scgi.protocol = "uwsgi"
    scgi.debug = 65535
    scgi.server   = (
        "/uwsgi/flaskApp" => ((
            "socket"            => "/run/www-data/flaskApp.sock",
            "check-local"       => "disable",
            "strip-request-url" => "uwsgi/flaskApp"
        )),
        "/uwsgi/bar" => ((
            "host"              => "127.0.0.1",
            "port"              => "8080",
            "check-local"       => "disable",
            "strip-request-url" => "uwsgi/foo"
        ))
    )
}
```

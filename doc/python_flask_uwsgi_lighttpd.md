# How to host a Python Flask App in lighttpd using uWSGI

The following describes how to run a python3 Flask App in lighttpd Webserver using the uWSGI Application Gateway Server.

## Create the Python Flask App

```bash
$ mkdir -p /home/pi/f

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



```python
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello_world():
        return 'Hello, World!'

if __name__ == '__main__':
    app.run()
```

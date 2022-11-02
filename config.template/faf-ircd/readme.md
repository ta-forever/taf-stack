Overwrite the following test files in production:

```
ssl/server.cert.pem
ssl/server.key.pem
```

following command may help:
  $ openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout key.pem -out cert.pem

or see github/faforever/faf-stack for samples.


And adjust the following files as needed (especially passwords and cloak-keys):

```
services.conf
unrealircd.conf
```

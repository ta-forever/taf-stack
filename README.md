# TAF Stack

This repository aims to provide a ready-to-go Docker Compose file to set up a complete TAF stack (or parts of it) with
a single command.

## Structure

The TAF stack uses two directories:

* `config` contains the configuration files for all TAF services
* `data` contains data required or produced by the services

Both directories are excluded by `.gitignore`. In fact, all files and directories are excluded if not explicitly un-ignored within `.gitignore`.

### Configuration

Each service has its own directory within `config`. They usually contain an environment file and/or other configuration
files needed for the service to operate properly. Environment files are loaded by Docker Compose and additional
files/directories may be mounted as volumes (both as specified in `docker-compose.yml`).

The `config` directory does not exist and has to be copied from `config.templates`. After that, it has to be kept in sync
with updates to `config.templates` manually (like when a parameter has been added, renamed or removed).

### Data

Some services need to persist files in volumes, or read files of other services. All volumes are created inside 
the `data` directory.

## Naming

To keep things intuitive and avoid conflicts, all services, network aliases, user names, folder names and environment files follow a
consistent naming.

## Usage

### Prerequisites

* [Docker](https://github.com/docker/docker/releases) 19.03.5-ce or newer (or [Docker Toolbox](https://github.com/docker/toolbox/releases))
* [Docker Compose](https://github.com/docker/compose/releases) v1.24.1 or newer

(It might work with older versions but is not tested on these.)

### Copy configuration template files

    cp -R config.template config
    cp .env.template .env

### Recreate security keys (for production systems)

In folder `config/faf-java-api/pki` replace `secret.key` and `public.key` with new keys generated with `ssh-keygen -m pem`. The secret key needs to be in rsa format and the public key in ssh-rsa format (see config.template for examples).

Hint: Some linux distros generate 3072 bit RSA keys by default (e.g. Arch). 3072 bit is not supported. Please use 2048 bit or 4096 bit key length.  

In folder `config/faf-ircd/ssl`
    $ openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout server.key.pem -out server.cert.pem

In folder `config/faf-python-server/
    $ openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout faf-server.pem


### Create required data directories and initial content

    $ mkdir -p data/content/avatars data/content/featured_mod_dropins data/content/galactic_war/scenarios data/content/game_logs data/content/gpgnet4ta data/content/maps data/content/replays
    $ cp -r content.template/* data/content/

    check docker-compose.yaml:faf-content to enable the ports 80 if running test server locally

### Set various configs

See a list of all the configs that still need to be set:

    scripts/config-template-passwd.sh

{{domain_name}}: taforever.com or taforever.localhost
{{host_ip}}: public ip or 127.0.0.1 or even blank??
{{dashboard_htpasswd}}:
    use htpasswd to generate a hashed password for dashboard.taforever.com
{{db_password}}:
    assign a plaintext password for various db user accounts
{{irc_cloak_key_0}}:
{{irc_cloak_key_1}}
{{irc_cloak_key_2}}
    assign a plaintext password for the IRC cloak key
{{irc_opers_user_password}}:
    assign a plaintext password for the IRC opers user/administrator
{{irc_services_password}}:
    assign a plaintext password for anope services to connect to unrealircd
{{mautic_client_secret}}:
    after configuring mautic set this to the assigned password
    not actually needed, just skip configuring mautic.
    maybe set the password to some dummy value if {{}} causes problems.
{{mindmax_dot_com_licence_key}}:
    go to mindmax.com and get a licence key for geoip2 (the new format, not the legacy format)
{{oauth_client_secret}}:
    assign a uuid to serve as a password. set the same value for faf-website name/id in db table faf.oauth_clients
{{password_from_postal_web_configuration}}:
    after configuring postal set this to the assigned password
{{turn_secret}}:
    assign a plaintext password for the coturn server

Set a password like this:

    scripts/config-template-passwd.sh db_password banana

### Initialize core database

    scripts/init-db.sh
    
This will launch the faf-db and generate the current database scheme.

### Update database schema

    docker-compose run --rm faf-db-migrations migrate

### Start all at once

    docker-compose up -d

### Start a single service

If you start a single service, services it depends on will be started automatically. For instance:

    docker-compose up -d faf-python-server

### Start from local repository

To start a service from your local repository, find its `image` or `build` in the `docker-compose.yml` and change it to:

    build: <path>

Where `<path>` is the path to your local project, for instance `../faf-python-server`.

# Service specific configurations

## firewall

alex@taforever3:~/taf-stack$ sudo ufw status numbered
[sudo] password for alex:
Status: active

     To                         Action      From
     --                         ------      ----
[ 1] 22                         ALLOW IN    Anywhere        ssh
[ 2] 443/tcp                    ALLOW IN    Anywhere        https (various services, eg website, api, dashboard, etc)
[ 3] 80                         ALLOW IN    Anywhere        http (various services, eg website, api, dashboard, etc)
[ 4] 15000                      ALLOW IN    Anywhere        replay server
[ 5] 15001                      ALLOW IN    Anywhere        demo compiler
[ 6] 6697                       ALLOW IN    Anywhere        irc
[ 7] 8001                       ALLOW IN    Anywhere        website retrieval of player/game count from server
[ 8] 3478/udp                   ALLOW IN    Anywhere        coturn server
[ 9] 22 (v6)                    ALLOW IN    Anywhere (v6)
[10] 443/tcp (v6)               ALLOW IN    Anywhere (v6)
[11] 80 (v6)                    ALLOW IN    Anywhere (v6)
[12] 15000 (v6)                 ALLOW IN    Anywhere (v6)
[13] 15001 (v6)                 ALLOW IN    Anywhere (v6)
[14] 6697 (v6)                  ALLOW IN    Anywhere (v6)
[15] 8001 (v6)                  ALLOW IN    Anywhere (v6)
[16] 3478/udp (v6)              ALLOW IN    Anywhere (v6)

## RabbitMQ

     $ docker exec -it faf-rabbitmq /bin/bash
     $ rabbitmqctl add_user faf-postal banana
     $ rabbitmqctl add_vhost /faf-postal
     $ rabbitmqctl set_permissions -p /faf-postal faf-postal ".*" ".*" ".*"

## Postal

### Create initial user

Once Postal is running, create a user by executing the following command:
```
docker exec -it faf-postal /opt/postal/bin/postal make-user
```

### Set up a mail server for Mautic

1. Access Postal's web interface and log in with the user created above
1. Click `Create the first organization` and follow the instructions
1. Create a new mail server
    1. Click `Build your first mail server` and enter the following
    1. Name: TAF Mautic
    1. Short name: faf-mautic
    1. Mode: Choose what's appropriate
1. Set up the email domain
    1. Go to `Domain` and select `Add your first domain`
    1. Enter the domain name and continue
    1. Follow the instructions to set up the DNS correctly
    1. Click `Check my records are correct` and make sure everything is green
1. Set up an SMTP user for faf-mautic
    1. Go to `Credentials` and select `Add your first credential`
    1. Type: `SMTP`, Name: `TAF Mautic User`, Key: `faf-mautic`, Hold: `Process all messages`
    1. Click `Create credential`
1. Check the credentials for Mautic
    1. Go to `Overview` and select `Read about sending e-mail`
    1. Note `Username` and `Password`

## Mautic

Make sure you set up Postal first.

### Initial Setup

1. Access Mautic's web interface and follow the instructions until `Email Configuration` 
1. Enter the email configuration
    1. Email handling: `Send immediately`, Mailer transport: `Other SMTP Server`. Enter Server: `faf-postal`, Port: `25`, Encryption: `None`, Authentication mode: `Plain`
    1. Enter `Username` and `Password` as seen in Postal (check the Postal setup instructions above) 
1. Log in with the admin username and password (as created before)
1. Find and open the the `Settings` menu (top right corner)
    1. Configure API access
        1. Go to `Configuration`, then `API Settings`
        1. Set API enabled: `Yes`. If mautic/mautic#5743 is still unresolved, set Enable HTTP basic auth: `Yes`
        1. Click `Apply`
        1. If mautic/mautic#5743 is resolved, in the Settings menu, go to `API Credentials` and set up credentials for `faf-java-api`
        1. If mautic/mautic#5743 is still unresolved, go to `Users` in the settings menu and add a user for `faf-java-api`. Preferably, create a role with proper permissions first.
        1. Delete Mautic's cache, otherwise the API won't work. Delete `data/faf-mautic/html/app/cache`
    1. Configure E-Mail
        1. Go to `Configuration`, then `Email Settings`
        1. Click `Test connection` and expect `Success!`
        1. Click `Send test email` and expect to receive an email in the inbox of your user's email account
        1. Preferably, configure an inbox and configure Bounces, Unsubscribe Requests and Contact Replies
        1. Under `Message Settings`, set Disable trackable urls: `Yes`
        1. Under `Unsubscribe Settings`, set all `Show ...` options to `Yes`
        1. Click `Apply`
    1. Configure Custom Fields
        1. Go to `Custom Fields`
        1. Uncheck all except (Alias): country, preferred_locale
        1. Click `New` and enter Label: `TAF User ID`, Alias: `faf_user_id`, Object: `Contact`, Group: `Core`, Data Type: `Text`, Required: `Yes`, Available for segments: `No`, Is Unique Identifier: `Yes`. Click `Save & Close`
        1. Click `New` and enter Label: `TAF Username`, Alias: `faf_username`, Object: `Contact`, Group: `Core`, Data Type: `Text`, Required: `Yes`, Available for segments: `No`, Is Unique Identifier: `Yes`. Click `Save & Close`
        1. Open the field `Email` and set Required: `Yes`
        
## Grafana

### Initial Setup

1. Log into Grafana using `admin/admin`
1. Add a Prometheus datasource named `Prometheus` at `http://faf-prometheus:9090`
1. Go to global organization settings and change the name from `Main org.` to `Forged Alliance Forever`. This is 
required to enable anonymous access, too.
 

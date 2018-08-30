# Octobox Installation and Configuration Guide

The Octobox team hosts a shared instance of Octobox at [octobox.io](https://octobox.io/), but perhaps you're looking to host
your own or get yourself set up to contribute to Octobox. Fantastic! There are a number of install options available to you.

Before you begin, remember that [web notifications must be enabled](README.md#requirements)
in your GitHub settings for Octobox to work.

### Installation

* [Database Selection](#database-selection)
* [Deployment to Heroku](#deployment-to-heroku)
* [Deployment to OpenShift Online](#deployment-to-openshift-online)
* [Encryption Key](#encryption-key)
* [Local installation](#local-installation)
* [Using Docker](#using-docker)
* [Using reverse proxy](#using-reverse-proxy)

### Configuration

* [Allowing periodic notification refreshes](#allowing-periodic-notification-refreshes)
* [Scheduling server-side notification syncs](#scheduling-server-side-notification-syncs)
* [Running Octobox for GitHub Enterprise](#running-octobox-for-github-enterprise)
* [Using Personal Access Tokens](#using-personal-access-tokens)
* [Limiting Access](#limiting-access)
* [Customizing the Scopes on GitHub](#customizing-the-scopes-on-github)
* [Customizing Source Link for Modified Code](#customizing-source-link-for-modified-code)
* [Adding a custom initializer](#adding-a-custom-initializer)
* [Downloading subjects](#downloading-subjects)
* [API Documentation](#api-documentation)
* [Google Analytics](#google-analytics)
* [Running Octobox as a GitHub App](#api-documentation)

# Installation
## Database Selection

Octobox supports a few database adapters. The full list can be found [here](https://github.com/octobox/octobox/blob/85bfbed9111a36e94aa74d4026633dc6ff844bf6/lib/database_config.rb#L2).

#### How to specify an adapter

- The default is `postgres`
- you can specify an environment variable `DATABASE=<adapter>`
- Protip: you can make a `.env` file that include the `DATABASE=<adapter>` if you don't want to specify it all the time.

Note, databases other than PostgreSQL don't have full text support (or recently have it). For this reason, search may be degraded as we can no longer use the `pg_search` gem.

## Deployment to Heroku

You can host your own instance of Octobox using Heroku.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/octobox/octobox)

Heroku will ask you to provide an OAuth client ID and secret, which you can get by
[registering a new OAuth application on GitHub](https://github.com/settings/applications/new)]. When creating the OAuth application:

* Make sure you enable the `notifications` scope on it (you will also need the `read:org` scope if you enable restricted access).
* You can provide Homepage and Authorization URLs by using the Heroku app name you choose. By default, a Heroku app is available at its Heroku domain, which has the form `[name of app].herokuapp.com`.
  The callback url would then be `[name of app].herokuapp.com/auth/github/callback`.

For more help with setting up an OAuth application on GitHub, see below.

After deploying the app to heroku, enable the `runtime-dyno-metadata` feature to enable the changelog feature:

    heroku labs:enable runtime-dyno-metadata

## Deployment to OpenShift Online

Octobox can be easily installed to [OpenShift Online](https://www.openshift.com/pricing/index.html), too.
As OpenShift Online provides a free "Starter" tier its also a very inexpensive way to try out an personalized Octobox installation in the cloud.

Please refer to the separate [OpenShift installation](../openshift/OPENSHIFT_INSTALLATION.md) document for detailed installation instructions.

## Encryption Key

Octobox uses [`encrypted_attr`](https://github.com/attr-encrypted/attr_encrypted) to store access tokens and personal access tokens on the user object.

Therefore to install and launch Octobox, you must provide a 32 byte encryption key as the env var `OCTOBOX_ATTRIBUTE_ENCRYPTION_KEY`

Protip: To generate a key, you can use `bin/rails secret | cut -c1-32`

## Local installation

First things first, you'll need to install Ruby 2.5.1. I recommend using the excellent [rbenv](https://github.com/rbenv/rbenv),
and [ruby-build](https://github.com/rbenv/ruby-build):

```bash
brew install rbenv ruby-build
rbenv install 2.5.1
rbenv global 2.5.1
```

Next, you'll need to make sure that you have PostgreSQL installed. This can be
done easily on OSX using [Homebrew](http://mxcl.github.io/homebrew/) or by using [http://postgresapp.com](http://postgresapp.com). Please see these [further instructions for installing Postgres via Homebrew](http://www.mikeball.us/blog/setting-up-postgres-with-homebrew/).

```bash
brew install postgres
```

On Debian-based Linux distributions you can use apt-get to install Postgres:

```bash
sudo apt-get install postgresql postgresql-contrib libpq-dev
```

Now, let's install the gems from the `Gemfile` ("Gems" are synonymous with libraries in other
languages):

```bash
gem install bundler && rbenv rehash
bundle install
```

Once all the gems are installed, we'll need to create the databases and
tables. Rails makes this easy through the use of "Rake" tasks:

```bash
bundle exec rake db:create db:migrate
```

Now go and register a new [GitHub OAuth Application](https://github.com/settings/applications/new), your development configuration should look something like this:

<img width="561" alt="screen shot 2016-12-18 at 21 54 35" src="https://cloud.githubusercontent.com/assets/564113/21299762/a7bfaace-c56c-11e6-834c-ff893f79cec3.png">

If you're deploying this to production, just replace `http://localhost:3000` with your applications URL.

Once you've created your application you can then then add the following to your `.env`:

```
GITHUB_CLIENT_ID=yourclientidhere
GITHUB_CLIENT_SECRET=yourclientsecrethere
```

Finally you can boot the rails app:

```bash
rails s
```

## Using Docker

### Using Docker Compose

You can use Docker to run Octobox in development.

First, [install Docker](https://docs.docker.com/engine/installation/). If you've got run macOS or Windows, Docker for Mac/Windows makes this really easy.

> If you have Windows Home Edition, you'll need to download and run [Docker Toolbox](https://www.docker.com/products/docker-toolbox).

Second, download the `docker-compose.yml` file from [here](https://raw.githubusercontent.com/octobox/octobox/master/docker-compose.yml)

Then, run:

```bash
GITHUB_CLIENT_ID=yourclientid GITHUB_CLIENT_SECRET=yourclientsecret docker-compose up --build
```

Octobox will be running on [http://localhost:3000](http://localhost:3000).

**Note**: You can add `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` to a `.env` file instead of supplying them directly on the command-line.


**Note**: If you want to help with the development of this project you should clone the code, and then run:

```bash
GITHUB_CLIENT_ID=yourclientid GITHUB_CLIENT_SECRET=yourclientsecret docker-compose -f docker-compose-dev.yml up --build
```


### Production environment

First, Create a network interface

```bash
docker network create octobox-network
```

Second, download and run postgres instance

```bash
docker run -d --network octobox-network --name=database.service.octobox.internal -e POSTGRES_PASSWORD=development -v pg_data:/var/lib/postgresql/data postgres:9.6-alpine
```

**Note**: you should name your database instance `database.service.octobox.internal` so that `octobox` container can connect to it.

Then, run the following command to download the latest docker image and start octobox in the background.

```bash
docker run -d --network octobox-network --name=octobox -e OCTOBOX_ATTRIBUTE_ENCRYPTION_KEY=my_key RAILS_ENV=development -e GITHUB_CLIENT_ID=yourclientid -e GITHUB_CLIENT_SECRET=yourclientsecret -e OCTOBOX_DATABASE_PASSWORD=development -e OCTOBOX_DATABASE_NAME=postgres -e OCTOBOX_DATABASE_USERNAME=postgres -e OCTOBOX_DATABASE_HOST=database.service.octobox.internal  -p 3000:3000 octoboxio/octobox:latest
```

Octobox will be running on [http://localhost:3000](http://localhost:3000).

### Upgrading docker image:

1. Pull the latest image using the command `docker pull octoboxio/octobox:latest` or `docker-compose pull` if you are using docker-compose.
2. Restart your running container using the command `docker restart octobox` or `docker-compose restart` if you are using docker-compose.

## Using reverse proxy

If you want to use a public domain name to access your local Octobox deployment, you will need to set up a reverse proxy
(e.g. Apache, Nginx). Information about the domain name needs to be properly passed to Octobox, in order not to
interfere with the OAuth flow.

### Example Nginx configuration

```bash
server {
  listen 443 ssl http2 ;
  server_name octobox.example.com;
  ssl on;
  ssl_certificate_key /etc/ssl/letsencrypt/live/octobox.example.com/privkey.pem;
  ssl_certificate /etc/ssl/letsencrypt/live/octobox.example.com/fullchain.pem;
  location / {
    # Set up proper headers for OAuth flow
    proxy_set_header Host $proxy_host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_pass http://localhost:3000;
  }
}
```

# Configuration

## Allowing periodic notification refreshes

You may allow users to set an auto-refresh interval that will cause a periodic sync and page reload when they are viewing notifications.  To enable this simply set the environment variable `MINIMUM_REFRESH_INTERVAL` to any integer above 0.  `MINIMUM_REFRESH_INTERVAL` is the lowest number of minutes between auto-syncs that the server will allow.

When enabled, user settings pages will have an 'Notification Refresh Interval' option.  This can be set to any value above `MINIMUM_REFRESH_INTERVAL`.

## Scheduling server-side notification syncs

**Note**: This is *not* enabled on the hosted version (octobox.io).

### Option 1

Now that you've set all to go you can configure the app to sync the notifications automatically, there is a rake task that will do this for every user

```
rake tasks:sync_notifications
```

You will need to configure this to run automatically

### Option 2

You can set the `OCTOBOX_SIDEKIQ_SCHEDULE_ENABLED` environment variable, which will enable `sidekiq-scheduler`.

The schedule, [located here](./config/sidekiq_schedule.yml), defines what is to be run and can be overridden using the `OCTOBOX_SIDEKIQ_SCHEDULE_PATH` variable in case you want to customize the schedule at all.

We gitignore the path `config/sidekiq_custom_schedule.yml` for the convenience of adding a custom schedule that doesn't get committed to your fork.

#### Heroku

Create a Heroku Scheduler

```
heroku addons:create scheduler:standard
```

Visit the Heroku Scheduler resource and add a new job to run `rake tasks:sync_notifications` daily

#### Cronjob

Run `crontab -e`

Add the following

```
@daily cd octobox_path && /usr/local/bin/rake RAILS_ENV=production tasks:sync_notifications
```

To find the full path for your rake executable, run `which rake`


## Running Octobox for [GitHub Enterprise](https://enterprise.github.com/home)
In order to setup Octobox for your GitHub Enterprise instance all you need you do is add your enterprise domain to the `.env` file / deployed environment.

Example:

```
GITHUB_DOMAIN=https://github.foobar.com
```

And that's it :sparkles:

## Using Personal Access Tokens
Octobox can optionally allow you to set a personal access token to use when querying for notifications.  This must be enabled
at the server level.  In order to enable it, add the environment variable `PERSONAL_ACCESS_TOKENS_ENABLED` to the `.env` file / deployed environment.

Example:

```bash
PERSONAL_ACCESS_TOKENS_ENABLED=1
```

Once that is set, users can set a personal access token on the Settings page (found on the user drop-down menu).

## Limiting Access
You can restrict access to your Octobox instance, and only allow members or a GitHub organization or team.  To limit access set the environment variable
`RESTRICTED_ACCESS_ENABLED=1` then set either `GITHUB_ORGANIZATION_ID=<org_id_number>` `GITHUB_TEAM_ID=<team_id_number>`.

You can get an organization's id with this curl command:
`curl https://api.github.com/orgs/<org_name>`

To get a team's id:
`curl https://api.github.com/orgs/<org_name>/teams`.
You must be authenticated with access to the org. This will show you a list of the org's teams. Find your team on the list and copy its id

Make sure you add the `read:org` scope if you have customized the scope at all.

## Customizing the Scopes on GitHub

You can customize the scopes required for Octobox to work by modifying the `GITHUB_SCOPE` environment variable.
By default `notifications` is enabled, unless you also [limit access](#limiting-access), in which case the default is `notifications, read:org`. These are required for the application to function correctly.

## Customizing Source Link for Modified Code

If you have modified the Octobox code in any way, in order to comply with the AGPLv3 license, you must link to the modified source.  You
can do this by setting the `SOURCE_REPO` environment variable to the url of a GitHub repo with the modified source.  For instance, if
you run this from a fork in the 'NotOctobox' org, you would set `SOURCE_REPO=https://github.com/NotOctobox/octobox`.

## Adding a custom initializer

If you have some need to run custom Ruby code or wish to configure Octobox directly on application load, you may add a file named
`custom.rb` in `config/initializers`. This file is gitignored. Example:

```ruby
# config/initializers/custom.rb

Octobox.config do |c|
  c.personal_access_tokens_enabled = true
end
```

## Downloading subjects

Experimental feature for downloading extra information about the subject of each notification, namely:

- Author for Issues, Pull Requests, Commit Comments and Releases
- State (open/closed/merged) for Issues, Pull Requests
- Labels

To enable this feature set the following environment variable:

    FETCH_SUBJECT=true

If you want this feature to work for private repositories, you'll need to [Customize the Scopes on GitHub](#customizing-the-scopes-on-github) adding `repo` scope to allow Octobox to get subject information for private issues and pull requests.

## API Documentation

API Documentation will be generated from the application's controllers using `bin/rake api_docs:generate`. Once generated it will be automatically listed in the Header dropdown.

This is included by default in the container build using `Dockerfile`. To include in your build, simply run the command listed above before deploy.


## Google Analytics

To enable Google analytics tracking set the following environment variable:

    GA_ANALYTICS_ID=UA-XXXXXX-XX

## Running Octobox as a GitHub App

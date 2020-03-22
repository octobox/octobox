# Octobox Installation and Configuration Guide

The Octobox team hosts a shared instance of Octobox at [octobox.io](https://octobox.io/), but perhaps you're looking to host
your own or get yourself set up to contribute to Octobox. Fantastic! There are a number of install options available to you.

Before you begin, remember that [web notifications must be enabled](README.md#requirements)
in your GitHub settings for Octobox to work.

### Installation

* [Deployment to Heroku](#deployment-to-heroku)
* [Deployment to OpenShift Online](#deployment-to-openshift-online)
* [Encryption Key](#encryption-key)
* [Local installation](#local-installation)
* [Using Docker](#using-docker-and-docker-compose)
* [Using reverse proxy](#using-a-reverse-proxy)

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
* [Running Octobox as a GitHub App](#running-octobox-as-a-github-app)
* [Open links in the same tab](#open-links-in-the-same-tab)
* [Live updates](#live-updates)

# Installation
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

First things first, you'll need to fork and clone Octobox repository to
your local machine.

Secondly, you'll need to install Ruby 2.7.0. I recommend using the excellent [rbenv](https://github.com/rbenv/rbenv),
and [ruby-build](https://github.com/rbenv/ruby-build):

```bash
brew install rbenv ruby-build
rbenv install 2.7.0
rbenv global 2.7.0
```

Next, you'll need to make sure that you have PostgreSQL installed. This can be
done easily on OSX using [Homebrew](http://mxcl.github.io/homebrew/) or by using [http://postgresapp.com](http://postgresapp.com). Please see these [further instructions for installing Postgres via Homebrew](http://www.mikeball.us/blog/setting-up-postgres-with-homebrew/).

```bash
brew install postgres
```

On Debian-based Linux distributions you can use apt-get to install Postgres:

```bash
sudo apt-get install postgresql postgresql-contrib libpq-dev rbenv
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

Once you've created your application you can then then create a new `.env` file and then add the following to your file:

```
GITHUB_CLIENT_ID=yourclientidhere
GITHUB_CLIENT_SECRET=yourclientsecrethere
```

Finally you can boot the rails app:

```bash
rails s
```

## Using Docker and Docker Compose

You can use Docker to run Octobox in development or production!

First, [install Docker](https://docs.docker.com/engine/installation/). If you've got run macOS or Windows, Docker for Mac/Windows makes this really easy.

> If you have Windows Home Edition, you'll need to download and run [Docker Toolbox](https://www.docker.com/products/docker-toolbox).

### Trying out Octobox

If you're just giving Octobox a try, you can simply download the
`docker-compose.yml` file from
[here](https://raw.githubusercontent.com/octobox/octobox/master/docker-compose.yml), then run:

```bash
$ GITHUB_CLIENT_ID=yourclientid GITHUB_CLIENT_SECRET=yourclientsecret docker-compose up --build
```

This will pull the latest image from Docker Hub and set everything up! Octobox will be running in a development configuration on [http://localhost:3000](http://localhost:3000).

**Note**: You can add environment variables such as `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` to a `.env` file instead of supplying them directly on the command-line.

### Configuring a development environment

If you've cloned the Octobox repository and are looking to contribute to the
project, you'll want to build your own image with your local source code. To do
that, you can override the `docker-compose.yml` configuration by adding a
`docker-compose.override.yml` with the following:

```yaml
version: '3'
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
```

Using `docker-compose up` automatically merges the override file in to the base configuration.

### Configuring a production environment

The `docker-compose.yml` file provided is for a _development_ configuration;
there are are a number of things you'll want to configure differently for
production use, like setting the Rails application for production and setting
up a reverse proxy such as Apache or Nginx to serve static assets. You can use the
`docker-compose.yml` file as an example to write your own or simply override
the existing configuration with `docker-compose.override.yml`. Both the
override file and `docker-compose.production.yml` are gitignored.

For more about override files and merging configurations, see [https://docs.docker.com/compose/extends/](https://docs.docker.com/compose/extends/)

### Upgrading docker image:

1. Pull the latest image using the command `docker pull octoboxio/octobox:latest` or `docker-compose pull` if you are using docker-compose.
2. Restart your running container using the command `docker restart octobox` or `docker-compose restart` if you are using docker-compose.

## Using a reverse proxy

If you want to use a public domain name to access your local Octobox
deployment, you will need to set up a reverse proxy (e.g. Apache, Nginx).
Information about the domain name needs to be properly passed to Octobox, in
order not to interfere with the OAuth flow.

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

If you are using [Live updates](#live-updates) then you need to configure the websocket connection as well

```bash
location /cable {
    proxy_pass http://localhost:3000/cable;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "Upgrade";
    add_header 'Access-Control-Allow-Origin' "$http_origin";
    add_header 'Access-Control-Allow-Credentials' 'true';
}
```

Note that this is only an example; there are numerous ways to configure Nginx
depending on your circumstances. For example, in a production environment
you'll also want to configure Nginx to serve static assets and pass all other
requests to the application server.

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

## Background Jobs

Octobox uses Sidekiq for background jobs. However, they are not enabled by default.

To make use of background jobs, set the `OCTOBOX_BACKGROUND_JOBS_ENABLED` variable.

If this is not set, all jobs will be run inline.

## Using Personal Access Tokens
Octobox can optionally allow you to set a personal access token to use when querying for notifications.  This must be enabled
at the server level.  In order to enable it, add the environment variable `PERSONAL_ACCESS_TOKENS_ENABLED` to the `.env` file / deployed environment.

Example:

```bash
PERSONAL_ACCESS_TOKENS_ENABLED=1
```

Once that is set, users can set a personal access token on the Settings page (found on the user drop-down menu).

## Limiting Access
You can restrict access to your Octobox instance, and only allow members of a GitHub organization or team.  To limit access set the environment variable
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

## Adding a link to a "native" desktop app link

Some applications allow you to create "native" applications for the desktop. This includes software such as [Nativefier](https://www.npmjs.com/package/nativefier).

If your installation uses this, set the environment variable `OCTOBOX_NATIVE_LINK` to add a link to the dropdown menu.

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
- Labels and Assignees for Issues, Pull Requests

To enable this feature set the following environment variable:

    FETCH_SUBJECT=true

If you want this feature to work for private repositories, you'll need to [Customize the Scopes on GitHub](#customizing-the-scopes-on-github) adding `repo` scope to allow Octobox to get subject information for private issues and pull requests.

As of 4th January 2019, Octobox can sync subjects from open source repositories without requiring `repo` scope. To limit the downloading of old open source subjects, add the current date to the `PUBLIC_SUBJECT_ROLLOUT` environment variable to minimize syncing of old notifications on large installations:

    PUBLIC_SUBJECT_ROLLOUT=2019-01-04 12:30:00 UTC

## API Documentation

API Documentation will be generated from the application's controllers using `bin/rake api_docs:generate`. Once generated it will be automatically listed in the Header dropdown.

This is included by default in the container build using `Dockerfile`. To include in your build, simply run the command listed above before deploy.


## Google Analytics

To enable Google analytics tracking set the following environment variable:

    GA_ANALYTICS_ID=UA-XXXXXX-XX

## Running Octobox as a GitHub App

Octobox can be configured to run as a [GitHub App](https://developer.github.com/apps/), which allows it to access private repository issue and pull request data without requiring `repo` scope.

Due to a restriction in the GitHub App API, you'll need to create both an [Oauth App](https://github.com/settings/applications/new) and a [GitHub App](https://github.com/settings/apps/new), first follow the setup instructions for [Local installation](#local-installation).

Then create a new GitHub App, <https://github.com/settings/apps/new>, with the following settings:

- Homepage URL: the domain you plan to run the app on (or http://localhost:3000)
- User authorization callback URL: The domain plus `/auth/githubapp/callback`, i.e. http://myoctoboxdomain.com/auth/githubapp/callback
- Setup URL: The domain plus `/auth/githubapp`, i.e. http://myoctoboxdomain.com/auth/githubapp
- Redirect on update: ✔
- Webhook URL: The domain plus `/hooks/github`, i.e. http://myoctoboxdomain.com/hooks/github
- Webhook secret: generate a password and paste it in here and save for later
- Permissions:
  - Organization members: Read-only (only needed if your organization has private members)
  - Repository metadata: Read-only
  - Issues: write
  - Pull Requests: Read-only
  - Commit statuses: Read-only
- Subscribe to events: check all available options
- Where can this GitHub App be installed: Any account if you want to be able to install it on multiple orgs

Then add the following ENV variables to `.env` (or `heroku config:add` if you're hosting heroku)

- `GITHUB_APP_CLIENT_ID` - From the GitHub App "OAuth credentials" section labelled `Client ID`
- `GITHUB_APP_CLIENT_SECRET` - From the GitHub App "OAuth credentials" section labelled `Client secret`
- `GITHUB_APP_ID` - From the GitHub App "About" section labelled `ID`
- `GITHUB_APP_SLUG`-  - From the GitHub App "About" section labelled `Public link`, the last section of the url, i.e https://github.com/apps/my-octobox -> `my-octobox`
- `GITHUB_APP_JWT`- - In the GitHub App "Private keys" section, generate a private key, which will cause a `.pem` file to be downloaded to your computer. This environment variable must contain the contents of the `.pem` file with newlines preserved.
- `GITHUB_WEBHOOK_SECRET` - The Webhook secret if you generated one earlier

Then start the rails app and visit <https://github.com/apps/my-octobox/installations/new> to install it on the orgs/repos you wish, it should log you into Octobox on completion of the install.

n.b. you will be required to log into the oauth app (to allow access to the notifications scope), followed by the github app (to allow access to installed app data).

To process events received from the webhook, ensure you have a sidekiq worker running as well as the rails server: `$ bundle exec sidekiq -C config/sidekiq.yml`

If you wish to run the GitHub app locally and still receive webhook events, use a service like <https://ngrok.com> to create a public url (`https://my-octobx.ngrok.com`) and use instead of http://localhost:3000 for all oauth and GitHub app config urls.

## Open links in the same tab

If you use Octobox inside of [Wavebox](https://wavebox.io/), [Franz](https://meetfranz.com/) or [Station](https://getstation.com/), you may find the default behaviour of opening notification links in new tabs annoying.

You can set the `OPEN_IN_SAME_TAB` environment variable, which will force all notification links to open in the same tab rather than new ones.

## Live updates

Octobox has an experimental feature where it can live-update notifications when they change using websockets. Only notifications you are currently viewing will be updated, no rows will be added or removed dynamically.

To enable this set the environment variable `PUSH_NOTIFICATIONS` to `true` and ensure you have redis configured for your instance. Also, set `WEBSOCKET_ALLOWED_ORIGINS` to Octobox base URL, e.g. `http://localhost` (it can take multiple values, e.g. `http://localhost,https://localhost`).

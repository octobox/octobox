# Octobox Installation and Configuration Guide

The Octobox team hosts a shared instance of Octobox at [octobox.io](https://octobox.io/), but perhaps you're looking to host
your own or get yourself set up to contribute to Octobox. Fantastic! There are a number of install options available to you.

Before you begin, remember that [web notifications must be enabled](https://github.com/octobox/octobox/tree/reorganize-readme#requirements)
in your GitHub settings for Octobox to work.

#### Installation

* [Deployment to Heroku](#deployment-to-heroku)
* [Local installation](#local-installation)
* [Using Docker](#using-docker)

#### Configuration
* [Allowing periodic notification refreshes](#allowing-periodic-notification-refreshes)
* [Scheduling server-side notification syncs](#scheduling-server-side-notification-syncs)
* [Running Octobox for GitHub Enterprise](#running-octobox-for-github-enterprise)
* [Using Personal Access Tokens](#using-personal-access-tokens)
* [Limiting Access](#limiting-access)

## Deployment to Heroku

You can host your own instance of Octobox using Heroku.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/octobox/octobox)

Heroku will ask you to provide OAuth client ID and secret, which you can create
on GitHub. When creating the OAuth application, make sure you enable the
notifications scope on it. For more help with setting up an OAuth application
on GitHub, see below.

## Local installation

First things first, you'll need to install Ruby 2.4.0. I recommend using the excellent [rbenv](https://github.com/rbenv/rbenv),
and [ruby-build](https://github.com/rbenv/ruby-build):

```bash
brew install rbenv ruby-build
rbenv install 2.4.0
rbenv global 2.4.0
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

You can use Docker to run Octobox in development.

First, [install Docker](https://docs.docker.com/engine/installation/). If you've got run macOS or Windows, Docker for Mac/Windows makes this really easy.

> If you have Windows Home Edition, you'll need to download and run [Docker Toolbox](https://www.docker.com/products/docker-toolbox).

Then, run:

```bash
GITHUB_CLIENT_ID=yourclientid GITHUB_CLIENT_SECRET=yourclientsecret docker-compose up --build
```

Octobox will be running on [http://localhost:3000](http://localhost:3000).

**Note**: You can add `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` to a `.env` file instead of supplying them directly on the command-line.

### Allowing periodic notification refreshes

**Note**: This is *not* enabled on the hosted version (octobox.io).

You may allow users to set an auto-refresh interval that will cause a periodic sync and page reload when they are viewing notifications.  To enable this simply set the environment variable `MINIMUM_REFRESH_INTERVAL` to any integer above 0.  `MINIMUM_REFERSH_INTERVAL` is the lowest number of minutes between auto-syncs that the server will allow.

When enabled, user settings pages will have an 'Notification Refresh Interval' option.  This can be set to any value above `MINIMUM_REFRESH_INTERVAL`.

## Scheduling server-side notification syncs

**Note**: This is *not* enabled on the hosted version (octobox.io).

Now that you've set all to go you can configure the app to sync the notifications automatically, there is a rake task that will do this for every user

```
rake tasks:sync_notifications
```

You will need to configure this to run automatically

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

## Source Link for Modified Code

If you have modified the Octobox code in any way, in order to comply with the AGPLv3 license, you must link to the modified source.  You
can do this by setting the `SOURCE_REPO` environment variable to the url of a GitHub repo with the modified source.  For instance, if 
you run this from a fork in the 'NotOctobox' org, you would set `SOURCE_REPO=https://github.com/NotOctobox/octobox`.

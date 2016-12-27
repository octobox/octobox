# Octobox &#128238;

Take back control of your GitHub Notifications with [Octobox]( https://octobox.io).

![Screenshot of Github Inbox](https://cloud.githubusercontent.com/assets/1060/21510049/16ad341c-cc87-11e6-9a83-86c6be94535f.png)

[![Build Status](https://travis-ci.org/octobox/octobox.svg?branch=master)](https://travis-ci.org/octobox/octobox)
[![Code Climate](https://img.shields.io/codeclimate/github/octobox/octobox.svg?style=flat)](https://codeclimate.com/github/octobox/octobox)
[![Test Coverage](https://img.shields.io/codeclimate/coverage/github/octobox/octobox.svg?style=flat)](https://codeclimate.com/github/octobox/octobox)

## Why is this a thing?

If you manage more than one active project on GitHub, you probably find [GitHub Notifications](https://github.com/notifications) pretty lacking.

Notifications are marked as read and disappear from the list as soon as you load the page or view the email of the notification. This makes it very hard to keep on top of which notifications you still need to follow up on.

Most open source maintainers and GitHub staff end up using a complex combination of filters and labels in Gmail to manage their notifications from their inbox. If, like me, you try to avoid email, then you might want something else.

Octobox adds an extra "archived" state to each notification so you can mark it as "done". If new activity happens on the thread/issue/pr, the next time you sync the app the relevant item will be unarchived and moved back into your inbox.

## What state is the project in right now?

You can use [a hosted version](https://octobox.io) right now.

You could also host it yourself, in Heroku or otherwise.

Check out the open issues for a glimpse of the future: https://github.com/octobox/octobox/issues.

## Requirements

Web notifications must be enabled in your GitHub settings for Octobox to work: https://github.com/settings/notifications

<img width="757" alt="Notifications settings screen" src="https://cloud.githubusercontent.com/assets/1060/21509954/3a01794c-cc86-11e6-9bbc-9b33b55f85d1.png">


## Deployment to Heroku

You can host your own instance of Octobox using Heroku. Heroku will ask you to provide a 'personal access token' which you can create on GitHub. When creating it, make sure you enable the notifications scope on it.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

## Running Octobox for [GitHub Enterprise](https://enterprise.github.com/home)
In order to setup Octobox for your GitHub Enterprise instance all you need you do is add your enterprise domain to the `.env` file / deployed environment.

Example:

```
GITHUB_DOMAIN=https://github.foobar.com
```

And that's it :sparkles:

## Development

The source code is hosted at [GitHub](https://github.com/octobox/octobox).
You can report issues/feature requests on [GitHub Issues](https://github.com/octobox/octobox/issues).
For other updates, follow me on Twitter: [@teabass](https://twitter.com/teabass).

### Getting Started

New to Ruby? No worries! You can follow these instructions to install a local server, or you can use the included [Vagrant](https://www.vagrantup.com/docs/why-vagrant/) setup.

#### Installing a Local Server

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
#### Docker

You can use Docker to run Octobox in development.

First, [install Docker](https://docs.docker.com/engine/installation/). If you've got run macOS or Windows, Docker for Mac/Windows makes this really easy.

Then, run:

```bash
GITHUB_CLIENT_ID=yourclientid GITHUB_CLIENT_SECRET=yourclientsecret docker-compose up --build
```

Octobox will be running on [http://localhost:3000](http://localhost:3000).

**Note**: You can add `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` to a `.env` file instead of supplying them directly on the command-line.

### Sync notifications automatically

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

### Keyboard shortcuts

You can use keyboard shortcuts to navigate and perform certain actions:

 - `a` - Select/deselect all
 - `r` or `.` - refresh list
 - `j` - move down the list
 - `k` - move up the list
 - `s` - star current notification
 - `x` - mark/unmark current notification
 - `y` - archive current/marked notification(s)
 - `o` or `Enter` - open current notification in a new window

Press `?` for the help menu.

### Note on Patches/Pull Requests

 * Fork the project.
 * Make your feature addition or bug fix.
 * Add tests for it. This is important so we don't break it in a future version unintentionally.
 * Send a pull request. Bonus points for topic branches.

### Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

## Copyright

Copyright (c) 2016 Andrew Nesbitt. See [LICENSE](https://github.com/octobox/octobox/blob/master/LICENSE.txt) for details.

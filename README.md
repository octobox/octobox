# GitHub Inbox &#128238;

Take back control of your GitHub Notifications

![Screenshot of Github Inbox](https://cloud.githubusercontent.com/assets/1060/21294563/62e8291a-c537-11e6-85dd-300f43141b6d.png)

## Why is this a thing?

If you manage more than one active project on GitHub, you probably find [GitHub Notifications](https://github.com/notifications) pretty lacking.

Notifications are marked as read and disappear from the list as soon as you load the page or view the email of the notification. This makes it very hard to keep on top of which notifications you still need to follow up on.

Most open source maintainers and GitHub staff end up using a complex combination of filters and labels in Gmail to manage their notifications from their inbox. If, like me, you try to avoid email, then you might want something else.

GitHub Inbox adds an extra "archived" state to each notification so you can mark it as "done". If new activity happens on the thread/issue/pr, the next time you sync the app the relevant item will be unarchived and moved back into your inbox.

## What state is the project in right now?

GitHub Inbox is like a little baby. You have to host it yourself and it only works for one user at a time.

Check out the open issues for a glimpse of the future: https://github.com/andrew/github-inbox/issues.

## Deployment to Heroku

You can host your own instance of GitHub Inbox using Heroku. Heroku will ask you to provide a 'personal access token' which you can create on GitHub. When creating it, make sure you enable the notifications scope on it.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

## Development

The source code is hosted at [GitHub](https://github.com/andrew/github-inbox).
You can report issues/feature requests on [GitHub Issues](https://github.com/andrew/github-inbox/issues).
For other updates, follow me on Twitter: [@teabass](https://twitter.com/teabass).

### Getting Started

New to Ruby? No worries! You can follow these instructions to install a local server, or you can use the included [Vagrant](https://www.vagrantup.com/docs/why-vagrant/) setup.

#### Installing a Local Server

First things first, you'll need to install Ruby 2.3.3. I recommend using the excellent [rbenv](https://github.com/rbenv/rbenv),
and [ruby-build](https://github.com/rbenv/ruby-build):

```bash
brew install rbenv ruby-build
rbenv install 2.3.3
rbenv global 2.3.3
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
bundle exec rake db:create:all
bundle exec rake db:migrate
```

Now go and create a [personal access token](https://github.com/settings/tokens) on GitHub with the `notifications` scope enabled and add it to `.env`:

```
GITHUB_TOKEN=yourpersonalaccesstoken
```

Finally you can boot the rails app:

```bash
rails s
```


### Note on Patches/Pull Requests

 * Fork the project.
 * Make your feature addition or bug fix.
 * Add tests for it. This is important so we don't break it in a future version unintentionally.
 * Send a pull request. Bonus points for topic branches.

### Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

## Copyright

Copyright (c) 2016 Andrew Nesbitt. See [LICENSE](https://github.com/andrew/github-inbox/blob/master/LICENSE.txt) for details.

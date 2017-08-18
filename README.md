# Octobox &#128238;

Take back control of your GitHub Notifications with [Octobox]( https://octobox.io).

![Screenshot of  Octobox](https://cloud.githubusercontent.com/assets/1060/25845986/feeca52c-34a7-11e7-82cf-d9b64546e4f6.png)

[![Build Status](https://travis-ci.org/octobox/octobox.svg?branch=master)](https://travis-ci.org/octobox/octobox)
[![Code Climate](https://img.shields.io/codeclimate/github/octobox/octobox.svg?style=flat)](https://codeclimate.com/github/octobox/octobox)
[![Test Coverage](https://img.shields.io/codeclimate/coverage/github/octobox/octobox.svg?style=flat)](https://codeclimate.com/github/octobox/octobox)
[![Code Climate](https://img.shields.io/codeclimate/issues/github/octobox/octobox.svg)](https://codeclimate.com/github/octobox/octobox/issues)
[![Docker](https://img.shields.io/docker/pulls/octoboxio/octobox.svg)](https://hub.docker.com/r/octoboxio/octobox/)
[![Gitter](https://img.shields.io/gitter/room/nwjs/nw.js.svg)](https://gitter.im/octobox/octobox)
[![license](https://img.shields.io/github/license/octobox/octobox.svg)](https://github.com/octobox/octobox/blob/master/LICENSE.txt)


## Why is this a thing?

If you manage more than one active project on GitHub, you probably find [GitHub Notifications](https://github.com/notifications) pretty lacking.

Notifications are marked as read and disappear from the list as soon as you load the page or view the email of the notification. This makes it very hard to keep on top of which notifications you still need to follow up on. Most open source maintainers and GitHub staff end up using a complex combination of filters and labels in Gmail to manage their notifications from their inbox. If, like me, you try to avoid email, then you might want something else.

Octobox adds an extra "archived" state to each notification so you can mark it as "done". If new activity happens on the thread/issue/pr, the next time you sync the app the relevant item will be unarchived and moved back into your inbox.

## Table of Contents

- [Getting Started](#getting-started)
	- [Octobox.io](#octoboxio)
	- [Install](#install)
	- [Desktop usage](#desktop-usage)
- [Requirements](#requirements)
- [Keyboard shortcuts](#keyboard-shortcuts)
- [Alternatives](#alternatives)
- [Development](#development)
	- [Note on Patches/Pull Requests](#note-on-patchespull-requests)
- [Contribute](#contribute)
	- [Code of Conduct](#code-of-conduct)
- [Copyright](#copyright)

## Getting Started

### Octobox.io

You can use Octobox right now at [octobox.io](https://octobox.io), a shared instance hosted by the Octobox team.

**Note:** octobox.io has a few features intentionally disabled:

* Auto refreshing of notifications page ([#200](https://github.com/octobox/octobox/pull/200))
* Personal Access Tokens ([#185](https://github.com/octobox/octobox/pull/185))

Features are disabled for various reasons, such as not wanting to store users' tokens at this time.

### Install

You can also host Octobox yourself! See [the installation guide](https://github.com/octobox/octobox/blob/master/INSTALLATION.md)
for installation instructions and details regarding deployment to Heroku, Docker, and more.

### Desktop usage

You can run Octobox locally as a desktop app too if you'd like, using [Nativefier](https://www.npmjs.com/package/nativefier):

```bash
npm install -g nativefier
nativefier "https://octobox.io" # Or your own self-hosted URL
```

This will build a local application (.exe, .app, etc) and put it in your current folder, ready to use.

## Requirements

[Web notifications](https://github.com/settings/notifications) must be enabled in your GitHub settings for Octobox to work.

<img width="757" alt="Notifications settings screen" src="https://cloud.githubusercontent.com/assets/1060/21509954/3a01794c-cc86-11e6-9bbc-9b33b55f85d1.png">

## Keyboard shortcuts

You can use keyboard shortcuts to navigate and perform certain actions:

 - `a` - Select/deselect all
 - `r` or `.` - Refresh list
 - `j` - Move down the list
 - `k` - Move up the list
 - `s` - Star current notification
 - `x` - Mark/unmark current notification
 - `y` or `e` - Archive current/marked notification(s)
 - `m` - Mute current/marked notification(s)
 - `d` - Mark current/marked notification(s) as read here and on GitHub
 - `o` or `Enter` - Open current notification in a new window

Press `?` for the help menu.

## Backers

Support us with a monthly donation and help us continue our activities. [Become a backer](https://opencollective.com/octobox#backer)

<a href="https://opencollective.com/octobox/backer/0/website" target="_blank"><img src="https://opencollective.com/octobox/backer/0/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/1/website" target="_blank"><img src="https://opencollective.com/octobox/backer/1/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/2/website" target="_blank"><img src="https://opencollective.com/octobox/backer/2/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/3/website" target="_blank"><img src="https://opencollective.com/octobox/backer/3/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/4/website" target="_blank"><img src="https://opencollective.com/octobox/backer/4/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/5/website" target="_blank"><img src="https://opencollective.com/octobox/backer/5/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/6/website" target="_blank"><img src="https://opencollective.com/octobox/backer/6/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/7/website" target="_blank"><img src="https://opencollective.com/octobox/backer/7/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/8/website" target="_blank"><img src="https://opencollective.com/octobox/backer/8/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/9/website" target="_blank"><img src="https://opencollective.com/octobox/backer/9/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/10/website" target="_blank"><img src="https://opencollective.com/octobox/backer/10/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/11/website" target="_blank"><img src="https://opencollective.com/octobox/backer/11/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/12/website" target="_blank"><img src="https://opencollective.com/octobox/backer/12/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/13/website" target="_blank"><img src="https://opencollective.com/octobox/backer/13/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/14/website" target="_blank"><img src="https://opencollective.com/octobox/backer/14/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/15/website" target="_blank"><img src="https://opencollective.com/octobox/backer/15/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/16/website" target="_blank"><img src="https://opencollective.com/octobox/backer/16/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/17/website" target="_blank"><img src="https://opencollective.com/octobox/backer/17/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/18/website" target="_blank"><img src="https://opencollective.com/octobox/backer/18/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/19/website" target="_blank"><img src="https://opencollective.com/octobox/backer/19/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/20/website" target="_blank"><img src="https://opencollective.com/octobox/backer/20/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/21/website" target="_blank"><img src="https://opencollective.com/octobox/backer/21/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/22/website" target="_blank"><img src="https://opencollective.com/octobox/backer/22/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/23/website" target="_blank"><img src="https://opencollective.com/octobox/backer/23/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/24/website" target="_blank"><img src="https://opencollective.com/octobox/backer/24/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/25/website" target="_blank"><img src="https://opencollective.com/octobox/backer/25/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/26/website" target="_blank"><img src="https://opencollective.com/octobox/backer/26/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/27/website" target="_blank"><img src="https://opencollective.com/octobox/backer/27/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/28/website" target="_blank"><img src="https://opencollective.com/octobox/backer/28/avatar.svg"></a>
<a href="https://opencollective.com/octobox/backer/29/website" target="_blank"><img src="https://opencollective.com/octobox/backer/29/avatar.svg"></a>


## Sponsors

Become a sponsor and get your logo on our README on Github with a link to your site. [Become a sponsor](https://opencollective.com/octobox#sponsor)

<a href="https://opencollective.com/octobox/sponsor/0/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/0/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/1/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/1/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/2/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/2/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/3/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/3/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/4/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/4/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/5/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/5/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/6/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/6/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/7/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/7/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/8/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/8/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/9/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/9/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/10/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/10/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/11/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/11/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/12/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/12/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/13/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/13/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/14/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/14/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/15/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/15/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/16/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/16/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/17/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/17/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/18/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/18/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/19/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/19/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/20/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/20/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/21/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/21/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/22/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/22/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/23/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/23/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/24/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/24/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/25/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/25/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/26/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/26/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/27/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/27/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/28/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/28/avatar.svg"></a>
<a href="https://opencollective.com/octobox/sponsor/29/website" target="_blank"><img src="https://opencollective.com/octobox/sponsor/29/avatar.svg"></a>

## Alternatives

- [LaraGit](https://github.com/m1guelpf/laragit) - PHP rewrite
- [octobox.js](https://github.com/doowb/octobox.js) - JavaScript rewrite

## Contribute

Please do! The source code is hosted at [GitHub](https://github.com/octobox/octobox). If you want something, [open an issue](https://github.com/octobox/octobox/issues/new) or a pull request.

If you need want to contribute but don't know where to start, take a look at the issues tagged as ["Help Wanted"](https://github.com/octobox/octobox/issues?q=is%3Aopen+is%3Aissue+label%3A%22help+wanted%22).

Finally, this is an open source project. If you would like to become a maintainer, we will consider adding you if you contribute frequently to the project. Feel free to ask.

For other updates, follow me on Twitter: [@teabass](https://twitter.com/teabass).

### Note on Patches/Pull Requests

 * Fork the project.
 * Make your feature addition or bug fix.
 * Add tests for it. This is important so we don't break it in a future version unintentionally.
 * Send a pull request. Bonus points for topic branches.

### Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

## Copyright

[GNU Affero License](LICENSE.txt) © 2017 [Andrew Nesbitt](https://github.com/andrew).

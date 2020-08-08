# Octobox Roadmap

This document highlights significant Octobox features planned for development in the short/medium term future.

If you'd like to propose an addition to this list, send a pull request with your addition added to this file for discussion.

If you'd like to work on one of these features or add thoughts and feedback, comment on the related open issue.


## Snoozing notifications [#452](https://github.com/octobox/octobox/issues/452)

Allow for certain notifications to be "snoozed" until a certain date or time, for instance "Tomorrow" or "1 week", snoozed notifications are then hidden from the regular inbox and archived views until that date/time arrives, then they reappear in the inbox.

This is handy for ignoring certain things for a few days where you can't work on it, making space to focus on other things.


## Notification filters and automated actions [#8](https://github.com/octobox/octobox/issues/8)

Allow sets of rules to be configured that enable notification actions to happen automatically under certain circumstances.

For example you may wish all notifications on a particular repositories except `Release` notifications to skip your inbox and be archived automatically. You'd create a search query that matches all the notifications you'd like to apply an action to, choose one or more "actions" that should be applied and save the filter.

All your saved filters will then be ran each time you sync your notifications.

Example actions:

- archive a notification
- star a notification
- move a notification to the inbox
- mute a notification
- delete a notification


## Localization [#703](https://github.com/octobox/octobox/issues/703)

Let's make Octobox more friendly for people whose primary language isn't English, allowing them to switch interface text to the language of their preference.


## Import issues and pull requests from all repositories managed [#883](https://github.com/octobox/octobox/issues/883)

Currently Octobox only imports issues and pull requests for you that have generated notifications, this often misses critical items that you manage as part of your work flow, especially when you first start using Octobox.

This is a move to make it possible to use the power of Octobox as a more general purpose Issue and Pull Request management tool.


## ~Thread view [#709](https://github.com/octobox/octobox/pull/709)~

See the comment thread right from within the Octobox interface, either in a three column layout or a separate page depending on screen size.

- Expand notification to see entire subject body and comment thread
- Show how many items in a notification thread (i.e. comments count)
- Show everyone who’s involved in a notification thread
- Show new comments since last viewed

## Private discussions

<<<<<<< HEAD
GitHub used to have this years and years ago. The additional context and social engagement is often useful for projects of globally distributed, disparate contributors. This might be implemented alongside 'reply on GitHub' functions as part of the above.
=======
GitHub used to have this years and years ago. The additonal context and social engagement is often useful for projects of globally distributed, disparate contributors. This might be implemented alongside 'reply on GitHub' functions as part of the above.
>>>>>>> upstream/NiR--improve-dockerfile

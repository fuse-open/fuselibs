# Contributing

When contributing to this repository, please first discuss the change you
wish to make via an issue, in our [slack](https://fusecommunity.slack.com)
community, or any other method with the owners of this repository before
making a change.

Please note we have a [code of conduct](#code-of-conduct), please follow
it in all your interactions with the project.

We also have a [contributor license agreement][1], that we require
contributors to sign in order to have their changes considered for
inclusion.

## Pull Request Process

1. Features should generally be pulled against the `master` branch.
   Bug-fixes, depending on the urgency and risk, goes either against an
   active release-branch, or `master`.
2. Make sure the code follows our [coding-style](Documentation/CodingStyle.md).
3. New features should have tests added, ensuring the feature does not
   silently break. Bug-fixes generally should have a regression-test added
   to ensure it isn't reintroduced.
4. New features must be documented. Please read [this](Documentation/WritingDocumentation.md)
   for details on how to write documentation.
5. If there's any functional changes, update CHANGELOG.md with a brief
   explanation.
6. Ensure that tests pass locally before sending a pull-request.
7. Make sure your pull-request passes the required CI (continuous
   integration). If there's a spurious error, re-trigger the CI until your
   pull-request pass, and feel free to file a ticket about the spurious
   test.
8. Make sure you follow up any feedback to get your pull-request merged.
9. If the pull-request is against `master`, you may merge once the
   pull-request have been approved by a project-member and passed CI, if
   you have the permissions needed. Otherwise, ping the project-member who
   approved the pull-request. Pull-requests against release-branches should
   be done by the release-manager (if you're unsure who this is, contact
   the project-team).

## Code of Conduct

Please read and adhere to our [Code of Conduct](CODE_OF_CONDUCT.md)

[1]: https://cla-assistant.io/fusetools/fuselibs-public

# Contributing

> *Please note that at this point, we are not accepting outside pull-requests.
> We are currently working on changing this, but for now, all pull-requests
> from people not working for the fusetools organization will be rejected
> until further notice. We are sorry for the inconvenience this entails.*

When contributing to this repository, please first discuss the change you
wish to make via an issue, in our [slack](https://fusecommunity.slack.com)
community, or any other method with the owners of this repository before
making a change.

Please note we have a [code of conduct](#code-of-conduct), please follow
it in all your interactions with the project.

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

### Our Pledge

In the interest of fostering an open and welcoming environment, we as
contributors and maintainers pledge to making participation in our project
and our community a harassment-free experience for everyone, regardless of
age, body size, disability, ethnicity, gender identity and expression, level
of experience, nationality, personal appearance, race, religion, or sexual
identity and orientation.

### Our Standards

Examples of behavior that contributes to creating a positive environment
include:

* Using welcoming and inclusive language
* Being respectful of differing viewpoints and experiences
* Gracefully accepting constructive criticism
* Focusing on what is best for the community
* Showing empathy towards other community members

Examples of unacceptable behavior by participants include:

* The use of sexualized language or imagery and unwelcome sexual attention
  or advances
* Trolling, insulting/derogatory comments, and personal or political attacks
* Public or private harassment
* Publishing others' private information, such as a physical or electronic
  address, without explicit permission
* Other conduct which could reasonably be considered inappropriate in a
  professional setting

### Our Responsibilities

Project maintainers are responsible for clarifying the standards of
acceptable behavior and are expected to take appropriate and fair corrective
action in response to any instances of unacceptable behavior.

Project maintainers have the right and responsibility to remove, edit, or
reject comments, commits, code, wiki edits, issues, and other contributions
that are not aligned to this Code of Conduct, or to ban temporarily or
permanently any contributor for other behaviors that they deem
inappropriate, threatening, offensive, or harmful.

### Scope

This Code of Conduct applies both within project spaces and in public spaces
when an individual is representing the project or its community. Examples of
representing a project or community include using an official project e-mail
address, posting via an official social media account, or acting as an
appointed representative at an online or offline event. Representation of a
project may be further defined and clarified by project maintainers.

### Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be
reported by contacting the project team at contact@fusetools.com. All
complaints will be reviewed and investigated and will result in a response
that is deemed necessary and appropriate to the circumstances. The project
team is obligated to maintain confidentiality with regard to the reporter
of an incident. Further details of specific enforcement policies may be
posted separately.

Project maintainers who do not follow or enforce the Code of Conduct in good
faith may face temporary or permanent repercussions as determined by other
members of the project's leadership.

### Attribution

This Code of Conduct is adapted from the
[Contributor Covenant](http://contributor-covenant.org), version 1.4,
available at <http://contributor-covenant.org/version/1/4>

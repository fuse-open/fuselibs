This section covers how to set up a iOS Push Notifications to the point that you can send messages to a Fuse App.

### Certifying your app for ACS

To do this you need an SSL certificate for your app.

- Go to the [Apple Dev Center](https://developer.apple.com/account/overview.action)
- Go to the Certificates Section for iOS apps
- In the link bar on the left, under the `Identifiers` section click `App IDs`
- Click the `+` icon in the top right to create a new App ID
- Fill in the details, you cant use push notification with a `Wildcard App ID` so pick `Explicit App ID` and check in XCode for the app's `Bundle ID`
- Under `App Services` enable Push notifications (and anything else you need)
- Click `Continue` and confirm the certificate choice you made.

### Syncing XCode

Your app is now authenticated for Push notifications. Be sure to resync your profiles in XCode before re-building your app.
To do this:
- Open XCode
- In the menu-bar choose `XCode`->`Preferences`
- In the Preferences window view the `Accounts` tab
- In the `Accounts` tab click `View Details` for the relevant Apple ID
- Click the small refresh button in the bottom left of the `View Details` window

### Sending Push Notifications to iOS from OSX

For simple testing you may find that setting up a server is a bit of an overkill. To this end we recommend [NWPusher](https://github.com/noodlewerk/NWPusher). Download the binary [here](https://github.com/noodlewerk/NWPusher/releases/tag/0.6.3) and then follow the following sections from the README

- `Getting started`
- `Certificate`
- Instead of reading the `Device Token` section simply add the example from above to your UX file
- Finally, follow the `Push from OS X` Section

Done, you should now be pushing notifications from OSX to iOS.


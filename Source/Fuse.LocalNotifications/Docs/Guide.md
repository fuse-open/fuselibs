Sometimes you need to alert your user to an event in your app even when your app is not running in the foreground. For this, most mobile devices have some concept of Notifications. This piece of documentation covers 'Local Notifications', which are notifications scheduled from the app itself. 'Push Notifications' are notifications sent from a server elsewhere and are covered [here](api:fuse/pushnotifications/push).

As with many of our bindings over OS features we like to start with a light API and build up. We are very interested in comments & requests, so do drop by the forums and let us know.

## Getting Set Up

Include the Fuse local notification library by adding the following to your `.unoproj` file

    "Packages": [
        ...
        "Fuse.LocalNotifications",
        ...
    ],

This is enough to start using this feature in your apps. Let's look at that now.


## App Example

This is a full Fuse app that uses Local Notifications:

    <App>
        <JavaScript>
            var LocalNotify = require("FuseJS/LocalNotifications");

            LocalNotify.on("receivedMessage", function(payload) {
                console.log("Received Local Notification: " + payload);
                LocalNotify.clearAllNotifications();
            });

            function sendLater() {
                LocalNotify.later(4, "Finally!", "4 seconds is a long time", "hmm?", true);
            }

            function sendNow() {
                LocalNotify.now("Boom!", "Just like that", "payload", true);
            }

            module.exports = {
                sendNow: sendNow,
                sendLater: sendLater
            };
        </JavaScript>
        <DockPanel>
            <TopFrameBackground DockPanel.Dock="Top" />
            <ScrollView>
                <StackPanel>
                    <Button Clicked="{sendNow}" Text="Send notification now" Height="60"/>
                    <Button Clicked="{sendLater}" Text="Send notification in 4 seconds" Height="60"/>
                </StackPanel>
            </ScrollView>
            <BottomBarBackground DockPanel.Dock="Bottom" />
        </DockPanel>
    </App>

Let's break down what is happening here.

## How it works

We will skip the `module.exports` and stuff inside the `DockPanel`, as that is better explained in other guides. Let's instead go through the JS.

After `require`ing our module like normal, we set up a function which will deliver a notification 4 seconds in the future.

    function sendLater() {
        LocalNotify.later(4, "Finally!", "4 seconds is a long time", "hmm?", true);
    }

The `later` function take the following parameters:

- `secondsFromNow`: How long in seconds until the notification fires
- `title`: the `string` which will be the title in the notification when it shows in the device's notification bar
- `body`: the `string` which will be the body of the notification when it shows in the device's notification bar
- `payload`: a string which is not shown in the notification itself, but will be present in the callback.
- `sound`: a `bool` specifying whether or not the device should make the default notification sound when it is shown in the notification bar
- `badgeNumber`: An optional parameter that is only used on iOS, which puts a badge number against the apps icon. This is often used for showing the quantity of 'things' that need the user's attention. For example an email app could show the number of unread emails.


    function sendNow() {
        LocalNotify.now("Boom!", "Just like that", "payload", true);
    }

The `now` function is almost identical to the `later` function, except that it doesnt have the `secondsFromNow` parameter.

One last thing to note about both `now` and `later`, is that they will not deliver a notification to the user if the app is open. Instead, they will trigger the `receivedMessage` event silently.

Finally, we set up the function that will be called whenever we get a notification, by using the @EventEmitter `on` method to register it.

    LocalNotify.on("receivedMessage", function(payload) {
        console.log("Received Local Notification: " + payload);
        LocalNotify.clearAllNotifications();
        LocalNotify.clearBadgeNumber();
    });

This function is called whenever a notification is delivered while the app is open, or when the app is started from a notification the user has selected.

The `payload` will be a string in JSON format containing the following keys:
- `'title'`: the notification's title as a `string`
- `'body'`: the body text of the notification as a `string`
- `'payload'`: the `string` of data that was sent with the notification.

`clearAllNotifications()` clears all notifications made by the app that have already been delivered. This can be used to remove similar notifications if one is clicked.

Last, but not least, `clearBadgeNumber()` clears the little number next to the app icon on the home screen, showing the amount of notifications the app has.


## Lifecyle Behavior

How your notification is treated by the OS depends on the state of the app. If the app is `Interactive`, the notification does not appear, and is instead delivered straight to your running app. If it is not interactive, the OS will create a notification based on the parameters you gave to the `later` or `not` functions. `Interactive` not only means that your app is in the `Foreground`, but that it also is not being obscured by other windows. One example of being in the `Foreground` and not `Interactive`, is when you swipe the status-bar to open the 'Notification Center/Drawer'.

You can try this with the example app above. Hit the `Send notification in 4 seconds` button, and open the 'Notification Center/Drawer'

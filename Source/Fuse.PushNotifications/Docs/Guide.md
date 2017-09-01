Fuse provides support for push-notifications from Firebase Cloud Messaging (FCM) and Apple' Push Notification Service (APNS).

We have opted for a lightweight consistent interface across iOS and Android which we can easily expand as needed.

> We are very interested in comments & requests you have on what we have so far so do drop by the forums and let us know.

## Setting up the client side

### Step 1.

Include the Fuse push notification library by adding the following to your `.unoproj` file

    "Packages": [
        ...
        "Fuse.PushNotifications",
        ...
    ],

### Step 2. (Only for Android)

Google notifications require a little extra info.

Add the following to you `.unoproj`

    "Android": {
        ...
        "GooglePlay": {
            "SenderID": "111781901112"
        }
        ...
    },

The `SenderID` is the sender ID from the [Firebase Console](https://console.firebase.google.com).
If you don't yet have a project set up please see the [Android setup](#android-setup) section later in this document.

## How this behaves in your app

Referencing `Fuse.PushNotifications` will do the the following:

### Both Platforms

- You get a callback telling you if the registration succeeded or failed.
- The succeeded callback will contain your unique registration id (also called a token in iOS docs)
- All future received push notifications will fire a callback containing the JSON of the notification.

All three callbacks mentioned are available in JavaScript and Uno.

### Android specific

- Your SenderID is added to the project's `Manifest.xml` file along with some other plumbing
- When your app starts the app registers with the `GCM` service.

### iOS specific

- When your app starts it registers with APNS. As all access is controlled through Apple's certificate system there is no extra info to provide (we will mention server side a bit later)

If you wish to disable auto-registration you can place the following in your unoproj file:

    "iOS": {
        "PushNotifications": {
            "RegisterOnLaunch": false
        }
    },

You must then register for push notifications by calling `register()` from JS. This option is useful as when the notifications are registered the OS may ask the user for permission to use push notifications and this may be undesirable on launch.

## Using the API from JavaScript

Integrating with notifications from JavaScript is simple. Here is an example that just logs when the callbacks fire:

    <JavaScript>
        var push = require("FuseJS/Push");

        push.on("registrationSucceeded", function(regID) {
            console.log("Reg Succeeded: " + regID);
        });

        push.on("error", function(reason) {
            console.log("Reg Failed: " + reason);
        });

        push.on("receivedMessage", function(payload) {
            console.log("Recieved Push Notification: " + payload);
        });
    </JavaScript>

Here we're using the @EventEmitter `on` method to register our functions with the different events.
In a real app we should send our `registration ID` to our server when `registrationSucceeded` is triggered.

## Server Side

When we have our client all set up and ready to go we move on to the backend. For this we are required to jump through the hoops provided by Apple and Google.

See below for the following guides on how to do this for specific platforms:

- [iOS Setup](#ios-setup)
- [Android Setup](#android-setup)

## The Notification

We support push notifications in JSON format. When a notification arrives one of two things will happen:

- If our app has focus, the callback is called right away with the full JSON payload
- If our app doesn't have focus, (and our JSON contains the correct data) we will add a system notification to the notification bar (called the Notification Center in iOS). When the user clicks the notification in the drop down then our app is launched and the notification is delivered.

Apple and Google's APIs define how the data in the payload is used to populate the system notification, however we have normalized it a little.

For iOS we'll just include an `aps` entry in the notification's JSON, like so:

    'aps': {
        alert: {
            'title': 'Well would ya look at that!',
            'body': 'Hello from the server'
        }
    },

And 'title' and 'body' will be used as the title and body of the system notification.

For Android we can use exactly the same `'aps'` entry or the alternatively the following:

    'notification': {
        alert: {
            'title': 'Well would ya look at that!',
            'body': 'Hello from the server'
        }
    },

The `notification` entry is the standard Google way of doing this but we felt that it wouldn't hurt to support the Apple way too.

> The current implementation only guarantees the `title` and `body` entries will work. We also always use your app's icon as the notification icon. This is an area we will extend as Fuse matures. If you have specific requests, be sure to let us know!

## Message size limits

Google and Apple has different limits on the size of push notifications.

- Google limits to 4096 bytes
- Apple limits to 2048 bytes on iOS 8 and up but only 256 bytes on all earlier versions


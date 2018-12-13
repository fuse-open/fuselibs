This section covers how to set up Firebase Push Notifications to the point that you can send test messages to a Fuse App from the Firebase console.

### Registering the Sender ID

- Open the [Firebase Console](https://console.firebase.google.com)
- Select your project or create one if you haven't already
- Click the little cogwheel button at the top of the sidebar, and press "Project settings"
- Navigate to the "Cloud Messaging" tab
- Copy the "Sender ID" into your `.unoproj` like this:

		"Android": {
			"GooglePlay": {
				"SenderID": "<Sender ID goes here>"
			}
		}

### Registering the Android app

To enable Firebase Cloud Messaging, you need to register an Android app with your Firebase project.
If you haven't already registered an Android app, follow these steps:

- From the settings page, click the button to add a new Android app to the project
- A dialog will pop up, prompting you for a package name (the other fields are optional).
	By default, this will be `com.apps.<yourappnameinlowercase>`.
	However, it is recommended to set your own:

		"Android": {
			"Package": "com.mycompany.myapp",
		}

- After adding the Android app, you will be prompted to download a `google-services.json` file. Download and copy it to the root of your project.
- Add the following file to tell fuse to copy google-services.json to your android app folder:

Android.uxl

```
<Extensions Backend="CPlusPlus" Condition="Android">
    <CopyFile Condition="Android" Name="google-services.json" TargetName="app/google-services.json" />
</Extensions>
```



### Sending notifications

After rebuilding your project with the new settings, you should be ready to send and receive push notifications.

> **Note:** Fuse currently only supports `data` type messages. See [here for details on messages types](https://firebase.google.com/docs/cloud-messaging/concept-options#data_messages) & [this forum post](https://forums.fusetools.com/t/push-notificacions-with-google-firebase-notifications/2910/16) for more information on how we will fix this in future.
> Sadly this means you currently can't use the Firebase Console to send test notifications (they will appear in the notification bar but will fail to reach JS).
> See the example below for an example of how to send messages to a Fuse app.

When your app starts, the `registrationSucceeded` event will be triggered and you will be given the `regID`
This, along with your FCM Server key, are the details that is needed to send that app a notification.

Your server key can be found under the "Cloud Messaging" tab of the Project Settings page (where you obtained your Sender ID).

Here some example Fuse code for sending your app a notification.

    <JavaScript>
        var API_ACCESS_KEY = '----HARDCODED API KEY----';
        var regID = '----HARDCODED REG ID FROM THE APP YOU ARE SENDING TO----';

        module.exports.send = function() {
            fetch('https://android.googleapis.com/gcm/send', {
                method: 'post',
                headers: {
                    'Authorization': 'key=' + API_ACCESS_KEY,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    registration_ids: [regID],
                    data: {
                        notification: {
                            alert: {
                                title: 'Well would ya look at that!',
                                body: 'Hello from some other app'
                            }
                        },
                        payload: 'anything you like'
                    }
                })
            }).then(function(response) {
                console.log(JSON.stringify(response));
            }, function(error) {
                console.log(error);
            });
        }
    </JavaScript>

Whilst hardcoding the RegID is clearly not a good idea, it serves the purpose for this simple test.

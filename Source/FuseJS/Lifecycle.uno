using Uno.UX;
using Fuse.Platform;
using Fuse.Scripting;

namespace FuseJS
{
	[UXGlobalModule]
	/**  Monitor the application lifecycle from JS
		@scriptmodule Lifecycle

		The lifecycle of an app is the time from when your app starts to the time it terminates.
		During this time the app will go through a number of states.

		The Lifecycle module allows you query the current state and also be alerted when the
		app changes state.

		## The States

		- Starting
		- Background
		- Foreground
		- Interactive

		### Starting
		Your app start event is implicit, as this is when your JavaScript is first evaluated.

		### Background
		Your app is not the app the user is interactive with right now and so the operating system
		has put it into a 'sleep' state.

		Whilst your app is in this state is is not allowed to run code, but you don't have to worry
		about this as Fuse will ensure your JS/UX is not doing something when it shouldn't.

		### Foreground
		Your app is front and center on the user's device but they cannot yet interact with it. The
		main reason to be in this state is that the user has opened the notification bar on iOS or
		Android.

		### Interactive
		Your app is now in the foreground and is accepting input from the user.

		## Changing States
		It would be hard to work with app lifecycle if your app could just jump around the states
		randomly. Instead we guarentee the following flow through the states:

		Starting
		   ↓
		Background ⟷ Foreground ⟷ Interactive
		   ↓
		Terminating


		## No `terminating` event
		You may be wondering why there is no `terminating` event. The reason is that on mobile
		platforms the OS doesn't promise to call you when terminating your app. It may, but in
		certain circumstances (low memory, emergency phone call, etc) it won't.

		Because of this the guides for mobile platforms strongly advise against using the `terminating`
		event as a cue that the app is shutting down, instead you should be regularly 'checkpointing'
		your app so you can recover from any kind of shutdown.

		Given that we are not meant to use it, we have opted not to expose the event.

		This module is an @EventEmitter, so the methods from @EventEmitter can be used to listen to events.

		## Example

			<JavaScript>
				var Lifecycle = require('FuseJS/Lifecycle');

				Lifecycle.on("enteringForeground", function() {
					console.log("on enteringForeground");
				});
				Lifecycle.on("enteringInteractive", function() {
					console.log("on enteringInteractive");
				});
				Lifecycle.on("exitedInteractive", function() {
					console.log("on exitedInteractive");
				});
				Lifecycle.on("enteringBackground", function() {
					console.log("on enteringBackground");
				});
				Lifecycle.on("stateChanged", function(newState) {
					console.log("on stateChanged " + newState);
				});
				module.exports = { lifecycleState: Lifecycle.observe("stateChanged") }
			</JavaScript>
			<StackPanel>
				<Text TextWrapping="Wrap">Open the Fuse Monitor to see the logs</Text>
				<Text>Current lifecycle state:</Text>
				<Text Value="{lifecycleState}" />
			</StackPanel>

		In the above example we're using the @EventEmitter `on` method to listen to the different events.
		We're also using the @EventEmitter `observe` method on the `"stateChanged"` event to get an @Observable containing the current state.
	*/
	public sealed class Lifecycle : NativeEventEmitterModule
	{
		NativeProperty<int, int> _state;
		NativeProperty<int, int> _background;
		NativeProperty<int, int> _foreground;
		NativeProperty<int, int> _interactive;

		static readonly Lifecycle _instance;

		public Lifecycle()
			: base(true,
				"enteringInteractive",
				"exitedInteractive",
				"enteringForeground",
				"enteringBackground",
				"stateChanged")
		{
			if(_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/Lifecycle");
			var onEnteringInteractive = new NativeEvent("onEnteringInteractive");
			var onEnteringForeground = new NativeEvent("onEnteringForeground");
			var onEnteringBackground = new NativeEvent("onEnteringBackground");
			var onExitedInteractive = new NativeEvent("onExitedInteractive");

			On("enteringInteractive", onEnteringInteractive);
			On("enteringForeground", onEnteringForeground);
			On("enteringBackground", onEnteringBackground);
			On("exitedInteractive", onExitedInteractive);

			_state = new NativeProperty<int, int>("state", GetCurrentState, null, Converter);

			// TODO: We should add NativeField instead. Properties are slow.
			_background = new NativeProperty<int, int>("BACKGROUND", GetApplicationStateBackground);
			_foreground = new NativeProperty<int, int>("FOREGROUND", GetApplicationStateForeground);
			_interactive = new NativeProperty<int, int>("INTERACTIVE", GetApplicationStateInteractive);

			AddMember(_state);
			AddMember(onEnteringInteractive);
			AddMember(onEnteringForeground);
			AddMember(onEnteringBackground);
			AddMember(onExitedInteractive);
			AddMember(_background);
			AddMember(_foreground);
			AddMember(_interactive);

			Fuse.Platform.Lifecycle.EnteringForeground += OnEnteringForeground;
			Fuse.Platform.Lifecycle.EnteringInteractive += OnEnteringInteractive;
			Fuse.Platform.Lifecycle.ExitedInteractive += OnExitedInteractive;
			Fuse.Platform.Lifecycle.EnteringBackground += OnEnteringBackground;

			Fuse.Platform.Lifecycle.EnteringForeground += OnStateChanged;
			Fuse.Platform.Lifecycle.EnteringInteractive += OnStateChanged;
			Fuse.Platform.Lifecycle.ExitedInteractive += OnStateChanged;
			Fuse.Platform.Lifecycle.EnteringBackground += OnStateChanged;
		}

		/**
			@scriptproperty BACKGROUND
		*/
		static int GetApplicationStateBackground()
		{
			return ApplicationState.Background;
		}

		/**
			@scriptproperty FOREGROUND
		*/
		static int GetApplicationStateForeground()
		{
			return ApplicationState.Foreground;
		}

		/**
			@scriptproperty INTERACTIVE
		*/
		static int GetApplicationStateInteractive()
		{
			return ApplicationState.Interactive;
		}

		/**
			@scriptproperty state

			Will give you the current state as an integer

				var Lifecycle = require("FuseJS/Lifecycle");

				console.log(Lifecycle.state === Lifecycle.BACKGROUND);
				console.log(Lifecycle.state === Lifecycle.FOREGROUND);
				console.log(Lifecycle.state === Lifecycle.INTERACTIVE);
		*/
		static int GetCurrentState()
		{
			return Fuse.Platform.Lifecycle.State;
		}

		/**
			@scriptevent enteringForeground

			Triggered when the app has left the suspended state and now is running.
			You will receive this event when the app starts.

				var Lifecycle = require("FuseJS/Lifecycle");

				Lifecycle.on("enteringForeground", function() {
					console.log("Entering foreground");
				});
		*/
		void OnEnteringForeground(ApplicationState newState)
		{
			Emit("enteringForeground");
		}

		/**
			@scriptevent enteringInteractive

			Triggered when the app is entering a state where it is fully focused and receiving events.

				var Lifecycle = require("FuseJS/Lifecycle");

				Lifecycle.on("enteringInteractive", function() {
					console.log("The app is gaining focus");
				});
		*/
		void OnEnteringInteractive(ApplicationState newState)
		{
			Emit("enteringInteractive");
		}

		/**
			@scriptevent exitedInteractive

			Triggered when the app is partially obscured or is no longer the focus (e.g. when you drag open the notification bar)

				var Lifecycle = require("FuseJS/Lifecycle");

				Lifecycle.on("exitedInteractive", function() {
					console.log("The app is no longer in focus");
				});
		*/
		void OnExitedInteractive(ApplicationState newState)
		{
			Emit("exitedInteractive");
		}

		/**
			@scriptevent enteringBackground

			Triggered when the app is leaving the running state and is about to be suspended.

				var Lifecycle = require("FuseJS/Lifecycle");

				Lifecycle.on("enteringBackground", function() {
					console.log("Entering background");
				});
		*/
		void OnEnteringBackground(ApplicationState newState)
		{
			Emit("enteringBackground");
		}

		/**
			@scriptevent stateChanged
			@param newState (Number) The new lifecycle state.

			Triggered when the app's lifecycle state has changed.

				var Lifecycle = require("FuseJS/Lifecycle");

				Lifecycle.on("stateChanged", function(newState) {
					console.log("The lifecycle state changed " + newState);
				});
		*/
		void OnStateChanged(ApplicationState newState)
		{
			Emit("stateChanged", (int)newState);
		}

		static int Converter(Context context, int state)
		{
			return state;
		}
	}
}

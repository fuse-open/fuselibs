using Uno;
using Uno.UX;

using Fuse.Triggers.Actions;
using Fuse.Scripting;

namespace Fuse
{

	public class AlertArgs : EventArgs, IScriptEvent
	{
		string _buttonLabel;

		public AlertArgs(string buttonLabel)
		{
			_buttonLabel = buttonLabel;
		}
		void IScriptEvent.Serialize(IEventSerializer s)
		{
			Serialize(s);
		}

		virtual void Serialize(IEventSerializer s)
		{
			s.AddString("buttonLabel", _buttonLabel);
		}
	}

	public delegate void AlertHandler(object sender, AlertArgs args);

	/**
		This is trigger action for showing native alert dialog with a single button. Only available on iOS or Android

		## Example

		The following example shows how to use it:

		'''javascript
		<JavaScript>
			module.exports = {
				handler: function(data) {
					if (data.buttonLabel == 'Yes'){
						console.log("yes button clicked")
					}
				}
			};
		</JavaScript>
		<Panel>
			<Button Text="Display Alert" Alignment="Center">
				<Clicked>
					<ShowAlert Message="Hello world!" OkLabelButton="Yes" Handler="{handler}"/>
				</Clicked>
			</Button>
		</Panel>
		```
		
	*/
	public class ShowAlert: TriggerAction
	{
		Node _target;

		string _title = "Alert";
		/**
			The title of the alert dialog
		*/
		public string Title
		{
			get
			{
				return _title;
			}
			set
			{
				_title = value;
			}
		}

		/**
			String message to show in the dialog
		*/
		public string Message
		{
			get; set;
		}

		string _okLabel = "OK";
		/**
			Ok label button on the alert dialog
		*/
		public string OkLabelButton
		{
			get
			{
				return _okLabel;
			}
			set
			{
				_okLabel = value;
			}
		}

		/**
			Optionally specifies a handler that will be called when this trigger is pulsed.
		*/
		public event AlertHandler Handler;

		extern(!MOBILE)
		protected override void Perform(Node n)
		{
			Fuse.Diagnostics.UserWarning("Alert dialog is not implemented for this platform", this);
		}

		extern(MOBILE)
		protected override void Perform(Node n)
		{
			_target = n;
			if (Message == null)
			{
				Fuse.Diagnostics.UserError("Message is null", this);
				return;
			}
			if defined(iOS)
				Fuse.Alerts.NativeAlerts.AlertNative(Title, Message, OkLabelButton, OnOK);
			if defined(Android)
				Fuse.Alerts.NativeAlerts.AlertNative(Title, Message, OkLabelButton, OnOK);
		}

		void OnOK()
		{
			if (Handler != null)
			{
				var visual = _target.FindByType<Visual>();
				Handler(visual, new AlertArgs(OkLabelButton));
			}
		}
	}

	/**
This is trigger action for showing an ok/cancel dialog. Only available on iOS or Android

## Example

The following example shows how to use it:
```javascript
<JavaScript>
	module.exports = {
		handler: function(data) {
			if (data.buttonLabel == 'Yes'){
				console.log("yes button clicked")
			} else if (data.buttonLabel == 'Cancel'){
				console.log("cancel button clicked")
			}
		}
	};
</JavaScript>
<Panel>
	<Button Text="Display Alert" Alignment="Center">
		<Clicked>
			<ShowConfirm Message="Are you sure want to logout?" OkLabelButton="Yes" CancelLabelButton="Cancel" Handler="{handler}"/>
		</Clicked>
	</Button>
</Panel>
```
	*/
	public class ShowConfirm: TriggerAction
	{
		Node _target;

		string _title = "Confirm";
		/**
			The title of the confirm dialog
		*/
		public string Title
		{
			get
			{
				return _title;
			}
			set
			{
				_title = value;
			}
		}

		/**
			String message to show in the dialog
		*/
		public string Message
		{
			get; set;
		}

		string _okLabel = "OK";
		/**
			Ok label button on the confirm dialog
		*/
		public string OkLabelButton
		{
			get
			{
				return _okLabel;
			}
			set
			{
				_okLabel = value;
			}
		}

		string _cancelLabel = "Cancel";
		/**
			Cancel label button on the confirm dialog
		*/
		public string CancelLabelButton
		{
			get
			{
				return _cancelLabel;
			}
			set
			{
				_cancelLabel = value;
			}
		}

		/**
			Optionally specifies a handler that will be called when this trigger is pulsed.
		*/
		public event AlertHandler Handler;

		extern(!MOBILE)
		protected override void Perform(Node n)
		{
			Fuse.Diagnostics.UserWarning("Confirm dialog is not implemented for this platform", this);
		}

		extern(MOBILE)
		protected override void Perform(Node n)
		{
			_target = n;
			if (Message == null)
			{
				Fuse.Diagnostics.UserError("Message is null", this);
				return;
			}
			if defined(iOS)
				Fuse.Alerts.NativeAlerts.ConfirmNative(Title, Message, OkLabelButton, CancelLabelButton, OnOK, OnCancel);
			if defined(Android)
				Fuse.Alerts.NativeAlerts.ConfirmNative(Title, Message, OkLabelButton, CancelLabelButton, OnOK, OnCancel);
		}

		void OnOK()
		{
			if (Handler != null)
			{
				var visual = _target.FindByType<Visual>();
				Handler(visual, new AlertArgs(OkLabelButton));
			}
		}

		void OnCancel()
		{
			if (Handler != null)
			{
				var visual = _target.FindByType<Visual>();
				Handler(visual, new AlertArgs(CancelLabelButton));
			}
		}
	}
}
using Uno.Platform;

using Fuse.Input;
using Fuse.Triggers;

namespace Fuse.Gestures
{
	/**
		Triggers when a pointer is pressed on a visual.
		As opposed to @Clicked or @Tapped, this trigger triggers immediately when a
		pointer is pressed on the visual. It does not wait for a pointer release or minimum
		amount of press time.
	*/
	public class Pressed : Fuse.Triggers.Trigger
	{
		protected override void OnRooted()
		{
			base.OnRooted();
			Pointer.Pressed.AddHandler(Parent, OnPressed);
		}

		protected override void OnUnrooted()
		{
			Pointer.Pressed.RemoveHandler(Parent, OnPressed);
			base.OnUnrooted();
		}

		void OnPressed(object s, object a)
		{
			Pulse();
		}
	}

	/** Active while at least one pointer is pressed on a visual.

		If `Capture` is `true` then this behaves more like a normal gesture and captures the pointer.
		Moving the pointer away from the element will cause the trigger to deactivate, but another visual will be prevented from capturing it.
		This should be used when you wish to track the same pressing status as a @Clicked gesture.

		# Example
		In this example, a panel will double in size when it is pressed:

			<Panel Width="50" Height="50">
				<WhilePressed>
					<Scale Factor="2" Duration="0.2"/>
				</WhilePressed>
			</Panel>
	*/
	public class WhilePressed : WhileTrigger
	{
		public bool Capture { get; set; }

		/** Holds the initiall press-down position of the pointer that activated the trigger (read-only).

			This can be used with a `{SnapshotProperty}` binding to place things in response to the pointer position. If the trigger
			isn't active at the time of reading, this property returns `(0,0)`;

			This property does not emit changed events, it is only intended for snapshotting.

			This property is read-only. Writing to it does nothing.

			## Example

				<Panel Color="Red">
					<WhilePressed ux:Name="wpGesture">
						<Rectangle ux:Name="rect" Alignment="TopLeft" Offset="{SnapshotProperty wpGesture.PressedPosition}" Width="20" Height="20" Color="White">
							<RemovingAnimation>
								<Change rect.Opacity="0" Duration="1" />
							</RemovingAnimation>
						</Rectangle>
					</WhilePressed>
				</Panel>
		*/
		float2 _pressedPosition;
		public float2 PressedPosition
		{
			get { return Clicker != null ? Clicker.PressedPosition : _pressedPosition; }

			// To make this visible to UX
			set {}
		}

		Clicker Clicker;

		PointerType _pointerType = (PointerType)0;
		public PointerType PointerType
		{
			get { return _pointerType; }
			set { _pointerType = value; }
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			if (Capture)
			{
				Clicker = Clicker.AttachClicker(Parent);
				Clicker.PressingEvent += OnClickerPressing;
			}
			else
			{
				Pointer.Entered.AddHandler(Parent, OnPointerEntered);
				Pointer.Left.AddHandler(Parent, OnPointerLeft);
				Pointer.Pressed.AddHandler(Parent, CheckStatus);
				//global to ensure we get the up regardless of capture status
				Pointer.Released.AddGlobalHandler(CheckStatus);
				Parent.IsContextEnabledChanged += CheckStatus;
				_inside = false;
			}

			SetActive(false);
		}

		protected override void OnUnrooted()
		{
			if (Capture)
			{
				Clicker.PressingEvent -= OnClickerPressing;
				Clicker.Detach();
				Clicker = null;
			}
			else
			{
				Pointer.Entered.RemoveHandler(Parent, OnPointerEntered);
				Pointer.Left.RemoveHandler(Parent, OnPointerLeft);
				Pointer.Pressed.RemoveHandler(Parent, CheckStatus);
				Pointer.Released.RemoveGlobalHandler(CheckStatus);
				Parent.IsContextEnabledChanged -= CheckStatus;
			}

			base.OnUnrooted();
		}

		void OnClickerPressing(Fuse.Input.PointerEventArgs args, int count)
		{
			var q = PointerType == (PointerType)0 || PointerType == args.PointerType;
			var on = count > 0;
			if (q)
				SetActive(on);
		}

		bool _inside;
		void OnPointerEntered(object sender, object args)
		{
			_inside = true;
			CheckStatus(sender,args);
		}

		void OnPointerLeft(object sender, object args)
		{
			_inside = false;
			CheckStatus(sender,args);
		}

		void CheckStatus(object s, object a)
		{
			var ppa = a as PointerPressedArgs;
			if (ppa != null) { _pressedPosition = Parent.WindowToLocal(ppa.WindowPoint); }

			//TODO: PointerType?
			SetActive( _inside && Parent.IsContextEnabled && Pointer.IsPressed() );
		}
	}
}

using Uno;
using Uno.UX;

using Fuse.Input;
using Fuse.Triggers;

namespace Fuse.Gestures
{
	public class TappedArgs : CustomPointerEventArgs
	{
		public TappedArgs(PointerEventArgs args, Visual visual)
			: base(args, visual)
		{
		}
	}

	public delegate void TappedHandler(object sender, TappedArgs args);

	/** Triggers when a pointer is tapped on a @Visual. 

		The `Tapped` trigger is quite similar to the @(Clicked) trigger, but these two triggers differ slightly in the interactions they handle.
		While a click represents a pointer being pressed and then released on an element, a tap represents a pointer being both pressed and released within a certain period of time.

		# Example
		In this example, a panel will rotate for 0.4 seconds, then rotate back, when tapped:

			<Panel Background="#F00">
				<Tapped>
					<Rotate Degrees="90" Duration=".4" DurationBack=".2" />
				</Tapped>
			</Panel>

		@see Clicked
	*/
	public class Tapped : ClickerTrigger
	{
		[UXAttachedEventAdder("Gestures.Tapped")]
		public static void AddHandler(Visual visual, TappedHandler handler)
		{
			var t = visual.FirstChild<Tapped>();
			if (t == null)
			{
				t = new Tapped();
				visual.Children.Add(t);
			}
			t.Handler += handler;
		}

		[UXAttachedEventRemover("Gestures.Tapped")]
		public static void RemoveHandler(Visual visual, TappedHandler handler)
		{
			var t = visual.FirstChild<Tapped>();
			if (t != null)
				t.Handler -= handler;
		}

		/** Optionally specifies a handler that will be called when this trigger is pulsed.
		*/
		public event TappedHandler Handler;

		public Tapped() {}

		public Tapped(TappedHandler handler)
		{
			Handler += handler;
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			Clicker.TappedEvent += OnTapped;
		}

		protected override void OnUnrooted()
		{
			Clicker.TappedEvent -= OnTapped;
			base.OnUnrooted();
		}

		void OnTapped(PointerEventArgs args, int tapCount)
		{
			if (!Accept(args))
				return;
			Pulse();
			if (Handler != null)
				Handler(this, new TappedArgs(args, Parent));
		}
	}

	/**
		Triggers when a pointer is double tapped (quickly) on a @Visual.
		@see DoubleClicked
	*/
	public class DoubleTappedArgs : CustomPointerEventArgs
	{
		public DoubleTappedArgs(PointerEventArgs args, Visual visual)
			: base(args, visual)
		{
		}
	}

	public delegate void DoubleTappedHandler(object sender, DoubleTappedArgs args);

	/** Triggers when a pointer is double-tapped on a @Visual.

	This `DoubleTapped` trigger is very similar to the `DoubleClicked` trigger, but these two triggers differ slightly in the interactions they handle.
	While a click represents a pointer being pressed and then released on an element, a tap represents a pointer being both pressed and released within a certain period of time.

	## Example
	The following example rotates a rectangle if it is double tapped.

		<Panel Width="100" Height="100" Color="#F00" >
			<DoubleTapped>
				<Rotate Degrees="270" Easing="ExponentialOut" Duration=".3"/>
			</DoubleTapped>
		</Panel>
	*/
	public class DoubleTapped : ClickerTrigger
	{
		/** Optionally specifies a handler that will be called when this trigger is pulsed.
		*/
		public event DoubleTappedHandler Handler;

		public DoubleTapped() {}

		public DoubleTapped(DoubleTappedHandler handler)
		{
			Handler += handler;
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			Clicker.TappedEvent += OnTapped;
		}

		protected override void OnUnrooted()
		{
			Clicker.TappedEvent -= OnTapped;
			base.OnUnrooted();
		}

		void OnTapped(PointerEventArgs args, int tapCount)
		{
			if (!Accept(args))
				return;
			if (tapCount != 2)
				return;

			Pulse();
			if (Handler != null)
				Handler(this, new DoubleTappedArgs(args, Parent));
		}
	}
}

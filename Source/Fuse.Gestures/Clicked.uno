using Uno;
using Uno.UX;
using Fuse.Input;

namespace Fuse.Gestures
{
	public class ClickedArgs: CustomPointerEventArgs
	{
		public ClickedArgs(PointerEventArgs args, Visual visual) : base(args,visual) {}
	}

	public delegate void ClickedHandler(object sender, ClickedArgs args);

	/** Triggers when a pointer is clicked on a @Visual. 

		The `Clicked` trigger is quite similar to the @(Tapped) trigger, but these two triggers differ slightly in the interactions they handle.
		While a click represents a pointer being pressed and then released on an element, a tap represents a pointer being both pressed and released within a certain period of time.

		# Example
		In this example, a panel will rotate for 0.4 seconds, then rotate back, when clicked:

			<Panel Background="#F00">
				<Clicked>
					<Rotate Degrees="90" Duration=".4" DurationBack=".2" />
				</Clicked>
			</Panel>

		@see Tapped
	*/
	public class Clicked : Fuse.Gestures.ClickerTrigger
	{
		[UXAttachedEventAdder("Gestures.Clicked")]
		public static void AddHandler(Visual visual, ClickedHandler handler)
		{
			var c = visual.FirstChild<Clicked>();
			if (c == null)
			{
				c = new Clicked();
				visual.Children.Add(c);
			}

			c.Handler += handler;
		}

		[UXAttachedEventRemover("Gestures.Clicked")]
		public static void RemoveHandler(Visual visual, ClickedHandler handler)
		{
			var c = visual.FirstChild<Clicked>();
			if (c != null)
				c.Handler -= handler;
		}

		/** Optionally specifies a handler that will be called when this trigger is pulsed.
		*/
		public event ClickedHandler Handler;

		protected override void OnRooted()
		{
			base.OnRooted();
			Clicker.ClickedEvent += OnClicked;
		}

		protected override void OnUnrooted()
		{
			Clicker.ClickedEvent -= OnClicked;
			base.OnUnrooted();
		}

		void OnClicked(PointerEventArgs args, int clickCount)
		{
			if (!Accept(args))
				return;

			Pulse();
			if (Handler != null)
				Handler(this, new ClickedArgs(args, Parent));
		}
	}

	/**
		Triggers when a pointer is double-clicked on a @Visual.

		This `DoubleClicked` trigger is very similar to the `DoubleTapped` trigger, but these two triggers differ slightly in the interactions they handle.
		While a click represents a pointer being pressed and then released on an element, a tap represents a pointer being both pressed and released within a certain period of time.

		## Example
		The following example rotates a rectangle if it is double clicked.

			<Panel Width="100" Height="100" Color="#F00" >
				<DoubleClicked>
					<Rotate Degrees="270" Easing="ExponentialOut" Duration=".3"/>
				</DoubleClicked>
			</Panel>
	*/
	public class DoubleClicked : Fuse.Gestures.ClickerTrigger
	{
		/** Optionally specifies a handler that will be called when this trigger is pulsed.
		*/
		public event ClickedHandler Handler;

		protected override void OnRooted()
		{
			base.OnRooted();
			Clicker.ClickedEvent += OnClicked;
		}

		protected override void OnUnrooted()
		{
			Clicker.ClickedEvent -= OnClicked;
			base.OnUnrooted();
		}

		void OnClicked(PointerEventArgs args, int clickCount)
		{
			if (!Accept(args))
				return;
			if (clickCount != 2)
				return;

			Pulse();
			if (Handler != null)
				Handler(this, new ClickedArgs(args, Parent));
		}
	}

}

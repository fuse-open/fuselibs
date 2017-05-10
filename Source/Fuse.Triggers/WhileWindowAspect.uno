using Uno;
using Fuse;
namespace Fuse.Triggers
{
	abstract public class WindowSizeTrigger : WhileTrigger
	{

		protected IViewport Viewport { get; private set; }

		protected override void OnRooted()
		{
			base.OnRooted();
			Viewport = Parent.FindByType<RootViewport>() as IViewport ?? Parent.Viewport;

			if defined(MOBILE)
			{
				Fuse.Platform.SystemUI.FrameChanged += OnResize;
			} else {
				Uno.Application.Current.Window.Resized += OnResize;
			}

			SetActive(IsActive);
		}

		protected override void OnUnrooted()
		{
			Viewport = null;
			if defined(MOBILE)
			{
				Fuse.Platform.SystemUI.FrameChanged -= OnResize;
			} else {
				Uno.Application.Current.Window.Resized -= OnResize;
			}
			base.OnUnrooted();
		}

		private void OnResize(object sender, EventArgs args)
		{
			if(Viewport!=null)
				SetActive(IsActive);
		}

		protected abstract bool IsActive { get; }
	}

	/**
		Active while the size of the app's viewport fulfills some given constraints.
		
		Constraints are specified via the @GreaterThan, @LessThan and @EqualTo
		properties. Each constraint must be provided as a pair of numbers,
		representing the target width and height (in points) to match against.
		
		Note that both the X and Y axis must satisfy the constraints you provide.

		## Examples
		
		The following example changes the color of `myRect` if the size of the
		app's viewport exceeds 400x400 points.

			<Rectangle ux:Name="myRect" Color="#f00" />
			<WhileWindowSize GreaterThan="400,400">
				<Change myRect.Color="#00f" Duration=".5"/>
			</WhileWindowSize>

		If you want to match on a single axis only, you can provide a value for
		the other axis that is greater than zero, and that you can safely assume
		will always match.
		
		For instance, if you want to check if only the width of the viewport is
		greater than 400 points, you could do the following:

			<WhileWindowSize GreaterThan="400,1">
		
		This also works for @LessThan by providing a big value.
		
			<WhileWindowSize LessThan="400,99999">

		You can also specify multiple constraints on the same `WhileWindowSize`
		trigger. Note that all constraints that you specify must be satisfied in
		order for the trigger to activate.

			<WhileWindowSize GreaterThan="200,300" LessThan="700,1000">
		
	*/
	public class WhileWindowSize : WindowSizeTrigger 
	{

		/** Active when the window size is greater than the provided value. */
		public float2 GreaterThan { get; set; }
		/** Active when the window size is less than the provided value. */
		public float2 LessThan { get; set; }
		/** Active when the window size is equal to the provided value. */
		public float2 EqualTo { get; set; }

		protected override bool IsActive 
		{ 
			get 
			{
				if(Viewport==null) return false;
				var sz = Viewport.Size;

				if(GreaterThan.X > 0 && GreaterThan.Y > 0 )
				{
					if(sz.X < GreaterThan.X || sz.Y < GreaterThan.Y)
						return false;
				}

				if(LessThan.X > 0 && LessThan.Y > 0)
				{
					if(sz.X > LessThan.X || sz.Y > LessThan.Y)
						return false;
				}

				if(EqualTo.X > 0 && EqualTo.Y > 0)
				{
					if(sz.X != EqualTo.X || sz.Y != EqualTo.Y)
						return false;
				}

				return true;
			} 
		}
	}

	abstract public class WhileWindowAspect : WindowSizeTrigger {
		protected float Aspect
		{
			get
			{
				if(Viewport==null) return 0.5f; //forcing portrait when in doubt...
				var sz = Viewport.Size;
				return sz.X / sz.Y;
			}
		}
	}

	/**
		Active when the app's viewport width is larger than its height.
		
		## Example
		
		The following example changes the color of `myRect` from black to white
		while the device is in landscape.

			<Rectangle ux:Name="myRect" Color="#000" />
			<WhileWindowLandscape>
				<Change myRect.Color="#fff" Duration="0.5" />
			</WhileWindowLandscape>
	*/
	public sealed class WhileWindowLandscape : WhileWindowAspect
	{
		protected override bool IsActive { get { return Aspect > 1; } }
	}

	/**
		Active when the app's viewport height is larger than or equal to its width.

		The following example changes the color of `myRect` from black to white
		while the device is in portrait.

			<Rectangle ux:Name="myRect" Color="#000" />
			<WhileWindowPortrait>
				<Change myRect.Color="#fff" Duration="0.5" />
			</WhileWindowPortrait>
	*/
	public sealed class WhileWindowPortrait : WhileWindowAspect
	{
		protected override bool IsActive { get { return Aspect <= 1; } }
	}
}

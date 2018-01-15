using Uno;
using Uno.UX;

using Fuse.Elements;
using Fuse.Gestures;

namespace Fuse.Controls
{
	/**
		Used to navigate contents that are larger than the available size.
		
		# Example
		
		This example demonstrates the use of `ScrollView` by having it contain a `Panel` that would normally be too big to be viewed. 
		
			<ScrollView>
				<Panel Width="2000" Height="2000" />
			</ScrollView>

		You may also constrain the directions the ScrollView is allowed to scroll in using the `AllowedScrollDirections` property.

			<ScrollView AllowedScrollDirections="Horizontal">
				<!-- Contents -->
			</ScrollView>

		By default, ScrollView tries to take up the same amount of space as its content in the scrollable directions.
		However, when placed in a @Panel (or @DockPanel, @Grid, etc.), the size of the ScrollView itself will be limited to the size of its parent.
		
		> **Note**
		>
		> *@StackPanel* does not limit the size of its children, but rather lets them extend to whatever size they want to take up.
		> This is a problem with ScrollView, since it inherits the size of its content by default.
		> If we were to place a ScrollView inside a @StackPanel, the size of the ScrollView would extend beyond the bounds of the screen.
		> What we want instead is that only the ScrollView's *content* should extend to whatever size it needs, while the ScrollView itself is constrained to the bounds of its parent.
		>
		> This means that *a ScrollView inside a @StackPanel probably won't behave as you expect it to*.
		> Alternatives include using a different type of @Panel (e.g. a @DockPanel) as the parent of the ScrollView or specifying its size explicitly.
		
		The `Alignment` of the child content influences the `MinScroll` and `MaxScroll` values as well as the starting `ScrollPosition`.
		For example a `Bottom` aligned element will start with the bottom of the content visible (aligned to the bottom of the `ScrollView`) and `MinScroll` will be negative, as the overflow is to the top of the `ScrollView`.

		## LayoutMode
		
		By default a `ScrollView` keeps a consistent `ScrollPosition` when the layout changes. This may result in jumping when content is added/removed.
		
		An alternate mode `LayoutMode="PreserveVisual"` instead attempts to maintain visual consistency when its children or parent layout is changed. It assumes it's immediate content is a container and looks at that container's children.  For example, a layout like this:
		
			<ScrollView>
				<StackPanel>
					<Panel/>
					<Panel/>
				<StackPanel>
			</ScrollView>
		
		Visuals without `LayoutRole=Standard` are not considered when retaining the visual consistency. The `LayoutMode` property can be used to adjust this behavior.		

	*/
	public partial class ScrollView
	{
		protected override void OnRooted()
		{
			base.OnRooted();
			if (VisualContext != VisualContext.Native)
				Children.Add(new Scroller(true/*for internal ctor*/));
			Children.Add(new DefaultTrigger(this));
		}

		protected override void OnUnrooted()
		{
			RemoveAllChildren<Scroller>();
			RemoveAllChildren<DefaultTrigger>();
			base.OnUnrooted();
		}
	}
}

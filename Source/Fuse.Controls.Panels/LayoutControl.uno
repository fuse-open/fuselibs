using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Layouts;
using Fuse.Elements;

namespace Fuse.Controls
{
	/**
		Layout controls perform layout of the children.

		@topic Layout controls

		## Available layout controls
		[subclass Fuse.Controls.LayoutControl]
	*/
	public partial class LayoutControl: Control
	{
		//this is here because we want to set the LayoutRole as well
		[UXAttachedPropertySetter("Element.LayoutMaster")]
		/** Makes an element inherit the layout of another.
		
			## Examples
			
			The following example will result in two overlapping @Rectangles.
			
				<StackPanel>
					<Rectangle ux:Name="master" Height="150" Color="#f00a" />
					<Rectangle LayoutMaster="master" Color="#00fa" />
				</StackPanel>
			
				
			Changing the `LayoutMaster` of an element will trigger any @LayoutAnimations on that element.
			The above example illustrates how `LayoutMaster` can be used to implement a moving selection rectangle.
			It consists of two panels that when clicked, animate the `selection` @Rectangle to inherit their size and position.

				<Panel>
					<Rectangle ux:Name="selection" LayoutMaster="target1">
						<Stroke Width="2" Brush="#3498db" Offset="2" />
						<LayoutAnimation>
							<Move RelativeTo="WorldPositionChange" X="1" Y="1" Duration="0.3" Easing="CubicInOut" />
							<Resize RelativeTo="SizeChange" X="1" Y="1" Duration="0.3" Easing="CubicInOut" />
						</LayoutAnimation>
					</Rectangle>

					<StackPanel>
						<Panel ux:Name="target1" Margin="10" Height="50" Background="#eee">
							<Text Alignment="Center">Click me</Text>
							<Clicked>
								<Set selection.LayoutMaster="target1" />
							</Clicked>
						</Panel>
						<Panel ux:Name="target2" Width="150" Height="100" Background="#eee">
							<Text Alignment="Center">Me too!</Text>
							<Clicked>
								<Set selection.LayoutMaster="target2" />
							</Clicked>
						</Panel>
					</StackPanel>
				</Panel>
				
		*/
		public static void SetLayoutMaster(Element elm, Element master)
		{
			if (master == null)
			{
				elm.BoxSizing = BoxSizingMode.Standard;
				elm.LayoutRole = LayoutRole.Standard;
				LayoutMasterBoxSizing.SetLayoutMaster(elm, null);
			}
			else
			{
				elm.BoxSizing = BoxSizingMode.LayoutMaster;
				elm.LayoutRole = LayoutRole.Independent;
				LayoutMasterBoxSizing.SetLayoutMaster(elm, master);
			}
		}
		
		[UXAttachedPropertyGetter("Element.LayoutMaster")]
		public static Element GetLayoutMaster(Element elm)
		{	
			return LayoutMasterBoxSizing.GetLayoutMaster(elm); 
		}
			
		Layout _layout;
		[UXContent]
		/** The layout that will be applied to the children.

			This property is rarely set directly. Instead, you use a subclass of @LayoutControl
			that already sets this property, such as a @Panel class.

			## Available Panel classes

			[subclass Fuse.Controls.Panel]

			## Available Layout classes

			[subclass Fuse.Layouts.Layout]
		*/
		public Layout Layout
		{
			get { return _layout ?? Fuse.Layouts.Layouts.Default; }
			set 
			{ 
				if (value != _layout)
				{
					if (IsRootingCompleted && _layout != null) _layout.Unrooted(this);
					_layout = value;
					if (IsRootingCompleted && _layout != null) _layout.Rooted(this);
					InvalidateLayout();
				}
			}
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			if (_layout != null)
				_layout.Rooted(this);
		}

		protected override void OnUnrooted()
		{
			if (_layout != null)
				_layout.Unrooted(this);
			base.OnUnrooted();
		}

		protected override float2 GetContentSize( LayoutParams lp )
		{
			var b = base.GetContentSize( lp );

			if (HasVisualChildren)
				return Math.Max(b, Layout.GetContentSize(this, lp));

			return b;
		}

		protected override void ArrangePaddingBox(LayoutParams lp)
		{
			base.ArrangePaddingBox(lp);
			
			if (HasVisualChildren) // optimization
				Layout.ArrangePaddingBox(this, Padding, lp);
		}

		protected override void OnChildAdded(Node elm)
		{
			if (elm is Visual)
				InvalidateLayout();
			base.OnChildAdded(elm);
		}

		protected override void OnChildRemoved(Node elm)
		{
			if (elm is Visual)
				InvalidateLayout();
			base.OnChildRemoved(elm);
		}
		
		protected override void OnChildMoved(Node elm)
		{	
			if (elm is Visual)
				InvalidateLayout();
			base.OnChildMoved(elm);
		}

		protected override LayoutDependent IsMarginBoxDependent( Visual child )
		{
			var outer = BoxSizingObject.IsContentRelativeSize(this);
			var inner = Layout.IsMarginBoxDependent(child);
			
			if (outer == LayoutDependent.Yes)
			{
				if (inner == LayoutDependent.No)
					return LayoutDependent.No;
				return LayoutDependent.Yes;
			}
			else if (outer == LayoutDependent.No)
			{
				if (inner == LayoutDependent.Yes)
					return LayoutDependent.NoArrange;
				if (inner == LayoutDependent.No)
					return LayoutDependent.No;
				return LayoutDependent.MaybeArrange;
			}
			else //Maybe
			{
				if (inner == LayoutDependent.Yes)
					return LayoutDependent.MaybeArrange;
				if (inner == LayoutDependent.No)
					return LayoutDependent.No;
				return LayoutDependent.Maybe;
			}
		}

		protected override bool FastTrackDrawWithOpacity(DrawContext dc)
		{
			if (HasChildren) return false;
			
			if (Background != null)
				DrawBackground(dc, Opacity);
			
			// Asserting base class doesn't need to draw anything!
			return true;
		}
	}
}

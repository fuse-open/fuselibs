using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse.Animations;
using Fuse.Elements;
using Fuse.Controls;
using Fuse.Triggers;

namespace Fuse.Controls
{
	public class MultiLayout : Behavior
	{
		protected override void OnRooted()
		{
			base.OnRooted();

			ChangeLayout(_layoutElement);
		}

		void ChangeLayout(Visual layoutRoot)
		{
			if (layoutRoot == null)
				return;

			// Avoid changing layout on inner multi layout panels
			if (layoutRoot.FirstChild<MultiLayout>() != null)
				return;

			if (layoutRoot is Placeholder)
			{
				((Placeholder)layoutRoot).AcquireTarget();
			}
			for (var v = layoutRoot.FirstChild<Visual>(); v != null; v = v.NextSibling<Visual>())
				ChangeLayout(v);
		}

		Element _layoutElement;
		public Element LayoutElement
		{
			get
			{
				return _layoutElement;
			}
			set
			{
				if (_layoutElement != value)
				{
					_layoutElement = value;
					ChangeLayout(_layoutElement);
				}
			}
		}
	}

	/**
		Allows you to move @Elements between different layouts using the `Placeholder` class.
		
		This allows us to @Move elements between different locations in the visual tree, and also switch between certain layouts on the fly.
		
		**Note:** `MultiLayoutPanel` is a good option for when you want to have different layouts based on on the value of certain data. In the cases where you are mostly interested in using different layouts as a means of creating animations, using the @Element.LayoutMaster property might be a better choice.
		
		# Example
		This example shows a simple 3-choice Selection which uses a `MultiLayoutPanel` together with `LayoutAnimation` to animate an indicator for the selected option:
		
			<Panel Alignment="Center" Width="200" Height="50" >
				<MultiLayoutPanel ux:Name="multiLayout">
					<Grid ColumnCount="3">
						<Panel ux:Name="offPanel">
							<Placeholder>
								<Panel ux:Name="pointer" Color="#2196F3" Width="50" Height="2">
									<LayoutAnimation>
										<Move X="1" Y="1" RelativeTo="LayoutChange" Duration=".4" Easing="QuadraticInOut" />
									</LayoutAnimation>
								</Panel>
							</Placeholder>
							<Text TextAlignment="Center">Off</Text>
							<Clicked>
							<Set multiLayout.LayoutElement="offPanel" />
							</Clicked>
						</Panel>
						<Panel ux:Name="standbyPanel">
							<Placeholder Target="pointer" />
							<Text TextAlignment="Center">Standby</Text>
							<Clicked>
								<Set multiLayout.LayoutElement="standbyPanel" />
							</Clicked>
						</Panel>
						<Panel ux:Name="onPanel">
							<Placeholder Target="pointer" />
							<Text TextAlignment="Center">On</Text>
							<Clicked>
								<Set multiLayout.LayoutElement="onPanel" />
							</Clicked>
						</Panel>
					</Grid>
				</MultiLayoutPanel>
			</Panel>
	*/
	public class MultiLayoutPanel: Panel
	{
		MultiLayout _multiLayout = new MultiLayout();
		public MultiLayoutPanel()
		{
			Children.Add( _multiLayout );
		}

		public Element LayoutElement
		{
			get { return _multiLayout.LayoutElement; }
			set { _multiLayout.LayoutElement = value; }
		}
	}

	/**
		@mount UI Components / Layout Animation
	*/
	public class Placeholder: ContentControl
	{
		public Element Target
		{
			get; set;
		}

		[UXPrimary]
		public Element PlaceholderContent
		{
			get { return base.Content; }
			set
			{
				base.Content = value;
				Target = value;
			}
		}

		Template _contentTemplate;
		public Template ContentTemplate
		{
			get { return _contentTemplate; }
			set
			{
				if (_contentTemplate == value)
					return;

				_contentTemplate = value;
				if (_contentTemplate == null)
					Content = null;
				else
					Content = _contentTemplate.New() as Element;
			}
		}

		public Template ContentFactory
		{
			get { return ContentTemplate; }
			set 
			{
				Diagnostics.Deprecated("ContentFactory is deprecated, use ContentTemplate instead", this);
				ContentTemplate = value;
			}
		}

		protected override void OnChildAdded(Node n)
		{
			base.OnChildAdded(n);
			n.OverrideContextParent = n.OverrideContextParent ?? this;
		}

		protected override void OnChildRemoved(Node n)
		{
			base.OnChildRemoved(n);
			if (n.OverrideContextParent == this) n.OverrideContextParent = null;
		}

		internal void AcquireTarget()
		{
			if (Target == null) return;
			if (Content == Target) return;

			var oldParent = Target.Parent as Placeholder;

			// We can only steal targets from other Placeholders
			if (oldParent == null)
				return;

			Target.PreserveRootFrame();

			oldParent.Content = null;
			Content = Target;
		}
	}
}


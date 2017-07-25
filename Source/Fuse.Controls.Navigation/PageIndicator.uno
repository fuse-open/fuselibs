using Uno;
using Uno.UX;

using Fuse.Navigation;
using Fuse.Elements;
using Fuse.Resources;

namespace Fuse.Controls
{
	/**
		Builds indicator icons for each page of a @PageControl based on a specified template, and displays them next to each other. To use it, you have to provide a template named `Dot`, 
		as well as providing a @PageControl to listen to through the `Navigation` property.

		The @ActivatingAnimation animator can be used to animate a `Dot` when its corresponding page is active.

		# Example

		The following example shows the use of `PageIndicator` to indicate the current progress in a @PageControl navigation, by scaling the rectangle indicator representing the current page by a `Factor` of 1.3.


			<DockPanel>
				<JavaScript>
					var Observable = require("FuseJS/Observable");
					module.exports.pages = Observable("#FF0000", "#00FF00", "#0000FF");
				</JavaScript>
				<PageControl ux:Name="nav">
					<Each Items="{pages}">
						<Page Color="{}">
							
						</Page>
					</Each>
				</PageControl>
				<PageIndicator Dock="Bottom" Navigation="nav" Alignment="Center">
					<Rectangle ux:Template="Dot" Width="30" Height="30" Margin="10" Color="#555">
						<ActivatingAnimation>
							<Scale Factor="1.3" />
						</ActivatingAnimation>
					</Rectangle>
				</PageIndicator>
			</DockPanel>


		@mount UI Components / Navigation
	*/
	public sealed partial class PageIndicator
	{
		INavigation _pageProgress;
		
		[UXConstructor]
		public PageIndicator([UXParameter("Navigation")] INavigation navigation)
		{
			InitializeUX();
			_pageProgress = navigation;
			_dotTemplate = new PageIndicatorDotTemplate();
			Fuse.Navigation.Navigation.SetNavigationNavigation(this, navigation);
		}

		Template _dotTemplate;
		public Template DotTemplate 
		{ 
			get { return FindTemplate("Dot") ?? _dotTemplate; }
			set 
			{ 
				if (_dotTemplate != value)
				{
					Diagnostics.Deprecated("PageIndicator.DotTemplate is deprecated, use ux:Template=\"Dot\" instead.", this);
					_dotTemplate = value;
					RecreateDots();
				}
			}
		}

		public Template DotFactory
		{
			get { return DotTemplate; }
			set
			{
				Diagnostics.Deprecated("PageIndicator.DotFactory is deprecated, use ux:Template=\"Dot\" instead.", this);
				DotTemplate = value;
			}
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			_pageProgress.PageCountChanged += UpdateCount;
			UpdateCount(null);
		}
		
		protected override void OnUnrooted()
		{
			_pageProgress.PageCountChanged -= UpdateCount;
			base.OnUnrooted();
		}
		
		void UpdateCount(object s)
		{
			RecreateDots();
		}

		void RecreateDots()
		{
			var count = _pageProgress.PageCount;

			while (VisualChildCount > count)
				Children.Remove(LastVisualChild);

			while (VisualChildCount < count)
			{
				var dot = DotTemplate.New() as Visual;
				var page = _pageProgress.GetPage(VisualChildCount);
				//prevent dot {Page} bindings from ever binding to the navigation object (Page is always present)
				NavigationPageProperty.SetNavigationPage(dot, page);
				Children.Add( dot );
			}

			var p = 0;
			for (var v = FirstChild<Visual>(); v != null; v = v.NextSibling<Visual>())
			{
				var page = _pageProgress.GetPage(p++);
				NavigationPageProperty.SetNavigationPage(v, page);
			}
		}
	}
	
	class PageIndicatorDotTemplate: Uno.UX.Template
	{
		public PageIndicatorDotTemplate(): base(null, false) {}

		public override object New()
		{
			return new Fuse.Controls.PageIndicatorDot();
		}
	}
}

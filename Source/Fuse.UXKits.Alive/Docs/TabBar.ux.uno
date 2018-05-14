namespace Alive
{
	/**
		A PageIndicator that uses values provided by the `Label` property of [TabPage](api:alive/tabpage)
		to instantiate tabs with text labels for each page in a @PageControl or other @LinearNavigation.
		
		*Note:* You can use the simpler [TabPageControl](api:alive/tabpagecontrol) in most cases,
		which combines a `TabBar` with a @PageControl.
		
		You must specify a `Navigation`, which refers to the @PageControl or other @LinearNavigation
		that contains the pages.
		
			<DockPanel>
				<Alive.TabBar Dock="Top" Navigation="pageControl" />
				<PageControl ux:Name="pageControl">
					<Alive.TabPage Label="Page 1">
						<!-- page content -->
					</Alive.TabPage>
					<Alive.TabPage Label="Page 2">
						<!-- page content -->
					</Alive.TabPage>
					<Alive.TabPage Label="Page 3">
						<!-- page content -->
					</Alive.TabPage>
				</PageControl>
			</DockPanel>
	*/
	public partial class TabBar {}
}

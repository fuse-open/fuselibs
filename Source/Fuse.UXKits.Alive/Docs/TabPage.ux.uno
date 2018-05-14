namespace Alive
{
	/**
		A @Page that exports a title for use with [TabPageControl](api:alive/tabpagecontrol) or [TabBar](api:alive/tabbar).
	
		The `Label` property on each TabPage in a @PageControl or [TabPageControl](api:alive/tabpagecontrol) is used
		to generate labelled tabs for each page.
		
		See also [PartialTabPage](api:alive/partialtabpage).
		
			<TabPageControl>
				<Alive.TabPage Label="Page 1">
					<!-- page content -->
				</Alive.TabPage>
				<Alive.TabPage Label="Page 2">
					<!-- page content -->
				</Alive.TabPage>
				<Alive.TabPage Label="Page 3">
					<!-- page content -->
				</Alive.TabPage>
			</TabPageControl>
	*/
	public partial class TabPage {}
}

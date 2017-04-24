using Uno;
using Uno.UX;
using Fuse;
using Fuse.Layouts;
using Fuse.Elements;

namespace Fuse.Controls
{

	/** Lays out its children by docking them to the different sides, one after the other. 

		One can specify which side per element by using the @Dock property like this:

			<DockPanel>
			    <Rectangle Dock="Left"/>
			</DockPanel>

		The @Dock property can be assigned to be either Left, Right, Top, Bottom or Fill (which is the default).

			<DockPanel>
			    <Rectangle ux:Class="MyRectangle" MinWidth="100" MinHeight="200" />
			    <MyRectangle Color="Red" Dock="Left"/>
			    <MyRectangle Color="Green" Dock="Top"/>
			    <MyRectangle Color="Blue" Dock="Right"/>
			    <MyRectangle Color="Yellow" Dock="Bottom"/>
			    <MyRectangle Color="Teal" />
			</DockPanel>
	*/
	public class DockPanel: Panel
	{

		[UXAttachedPropertySetter("DockPanel.Dock")]
		/** Specifies how an element is docked while inside a @DockPanel */
		public static void SetDock(Element elm, Dock dock)
		{
			DockLayout.SetDock(elm, dock);
		}

		[UXAttachedPropertyGetter("DockPanel.Dock")]
		public static Dock GetDock(Element elm)
		{
			return DockLayout.GetDock(elm);
		}

		[UXAttachedPropertyResetter("DockPanel.Dock")]
		public static void ResetDock(Element elm)
		{
			DockLayout.ResetDock(elm);
		}

		readonly DockLayout _dockLayout;

		public DockPanel()
		{
			Layout = _dockLayout = new DockLayout();
		}
	}
}

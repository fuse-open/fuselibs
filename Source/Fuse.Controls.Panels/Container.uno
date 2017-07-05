using Uno;
using Uno.Collections;
using Uno.UX;
using Fuse.Layouts;
using Fuse.Elements;

namespace Fuse.Controls
{
	/** A panel that places children in a dedicated `Subtree` visual, allowing you to create custom container.

		## Usage example 

		We use the `Subtree` property to identify the inner visual that will receive the children.

			<Container ux:Class="MyContainer" Subtree="innerPanel">
				<Rectangle ux:Binding="Children" CornerRadius="10" Margin="10">
					<Stroke Color="Red" Width="2" />
					<Panel Margin="10" ux:Name="innerPanel" />
				</Rectangle>
			</Container>

		Note that to add nodes that make up the container itself (e.g. decoration), we need to explicitly mark them 
		with `ux:Binding="Children"`, otherwise these nodes will be added to `innerPanel`.

		To use the container, we can simply do:

			<MyContainer>
				<Panel Color="Blue" />
			</MyContainer>

		Here, the blue panel will be placed as a child of `innerPanel`, instead of as a direct child of the
		container.
	*/
	public class Container: Panel
	{
		Visual _subtree;
		/** The visual that contains the subtree. */
		public Visual Subtree 
		{
			get { return _subtree; }
			set 
			{
				if (_subtree != value)
				{
					if (_subtree != null && _subtreeNodes != null && IsRootingCompleted) 
						_subtreeNodes.RootUnsubscribe();
						
					_subtree = value;
					
					if (_subtree != null && _subtreeNodes != null && IsRootingCompleted) 
						_subtreeNodes.RootSubscribe(OnNodeAdded, OnNodeRemoved);
				}
			}
		}


		RootableList<Node> _subtreeNodes;

		[UXPrimary]
		/** The list of nodes that will be added to the `Subtree` visual. This is the default property for UX markup children of `Container`. */
		public IList<Node> SubtreeNodes 
		{ 
			get 
			{ 
				if (_subtreeNodes == null)
				{
					_subtreeNodes = new RootableList<Node>();
					if (IsRootingCompleted)
						_subtreeNodes.Subscribe(OnNodeAdded, OnNodeRemoved);
				}

				return _subtreeNodes;
			} 
		}

		void OnNodeAdded(Node n)
		{
			if (_subtree != null) _subtree.Children.Add(n);
		}

		void OnNodeRemoved(Node n)
		{
			if (_subtree != null) _subtree.Children.Remove(n);
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			if (_subtreeNodes != null)
				_subtreeNodes.RootSubscribe(OnNodeAdded, OnNodeRemoved);
		}
		
		protected override void OnUnrooted()
		{
			if (_subtreeNodes != null)
				_subtreeNodes.RootUnsubscribe();
			base.OnUnrooted();
		}
	}
}
using Uno.UX;

namespace Fuse
{
	/**
		Allows placing a node in a different place in the UX tree than the location of this 
		behavior, while keeping the data context from this behavior.

		## Example
			<Panel ux:Class="MyPage">
				<Visual ux:Dependency="navBar" />
				<string ux:Property="Content" />
				<float4 ux:Property="Highlight" />
				<Text Alignment="Center" Value="{ReadProperty Content}" />
				<WhileActive>
					<AlternateRoot ParentNode="navBar">
						<Rectangle Color="{ReadProperty Highlight}" />
					</AlternateRoot>
				</WhileActive>
			</Panel>

			<ClientPanel>
				<Panel ux:Name="navBar" Dock="Top" Height="56" />
				<PageControl>
					<MyPage Content="Page 1" Highlight="#18f" navBar="navBar" />
					<MyPage Content="Page 2" Highlight="#1f8" navBar="navBar" />
				</PageControl>
			</ClientPanel>
	*/
	public sealed class AlternateRoot : Behavior
	{
		Visual _parentNode;
		/** The visual that will be the actual parent of the @Visual. */
		public Visual ParentNode
		{
			get { return _parentNode; }
			set
			{
				if (value == _parentNode)
					return;
					
				if (!IsRootingCompleted)
				{
					_parentNode = value;
					return;
				}
				
				Remove();
				_parentNode = value;
				Add();
			}
		}
		
		Node _node;
		
		[UXContent]
		/** The node that will be inserted into the @ParentNode */
		public Node Node
		{
			get { return _node; }
			set
			{
				if (value == _node)
					return;
					
				if (!IsRootingCompleted)
				{	
					_node = value;
					return;
				}
				
				Remove();
				_node = value;
				Add();
			}
		}

		/** Deprecated, for backwards compatibility. Use `Node` instead. */
		public Node Visual
		{
			get { return Node; }
			set { Node = value; }
		}

		bool _isEnabled = true;
		/** Whether this behavior is enabled.
			@default true */
		public bool IsEnabled
		{
			get { return _isEnabled; }
			set
			{
				if (_isEnabled == value)
					return;
					
				_isEnabled = value;
				if (!IsRootingCompleted)
					return;
					
				if (_isEnabled)
					Add();
				else
					Remove();
			}
		}
		
		bool _preserveContext = true;
		/** Whether to preserve the data context from the @AlternateRoot.
			@default true. */
		public bool PreserveContext
		{
			get { return _preserveContext; }
			set { _preserveContext = value; }
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();
			if (IsEnabled)
				Add();
		}
		
		protected override void OnUnrooted()
		{
			Remove();
			base.OnUnrooted();
		}
		
		void Remove()
		{
			if (ParentNode == null || Node == null)
				return;
			ParentNode.BeginRemoveChild(Node);
		}
		
		void Add()
		{
			if (ParentNode == null || Node == null)
				return;
			if (PreserveContext)
				Node.OverrideContextParent = base.Parent;
			ParentNode.Children.Add(Node);
		}
	}
}
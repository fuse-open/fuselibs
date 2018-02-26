using Uno;
using Uno.UX;

using Fuse.Reactive;

namespace Fuse.Selection
{
	[UXFunction("isSelected")]
	/**
		`true` while the @Selectable is currently selected.
		
		This expression attaches to the first @Selectable node that is an ancestory of the expression node. Optionally,  you may specify an argument to get a different selectable `isSelected( myPanel )`.
	*/
	public class IsSelectedFunction : VarArgFunction
	{
		[UXConstructor]
		public IsSelectedFunction()
		{ }
		
 		public override string ToString()
 		{
 			return FormatString("isSelected");
 		}
		
		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			if (Arguments.Count > 1)
			{
				Fuse.Diagnostics.UserError( "too many arguments for isSelected", this );
				return null;
			}
			
			var ins = new OuterSubscription(this, listener, context.Node );
			ins.Init(context);
			return ins;
		}
		
		class OuterSubscription : Subscription, IPropertyListener
		{
			//static values
			IsSelectedFunction _expr;
			IListener _listener;
			IExpression _node;
			Node _from;
			
			//the actual object values for the function
			Node _curFrom;
			Selection _selection;
			Selectable _selectable;

			IDisposable _nodeSub;

			public OuterSubscription( IsSelectedFunction expr, IListener listener, Node from ) : 
				base( expr )
			{
				_from = from;
				_expr = expr;
				_listener = listener;
			}

			protected override void OnNewArguments(Argument[] args)
			{
				var node = _from;
				if (args.Length > 0 )
				{
					node = args[0].Value as Node;
					if (node == null)
					{
						Fuse.Diagnostics.UserError( "Argument does not resolve to a Node", _expr );
					}
					else if (!node.IsRootingCompleted)
					{
						CleanPending();
						_pendingNode = node;
						_pendingNode.RootingCompleted += OnPendingRooted;
						node = null;
					}
				}
				NewNode( node );
			}
			
			Node _pendingNode;
			void OnPendingRooted()
			{
				if (_pendingNode == null)
					return;
				var p = _pendingNode;
				CleanPending();
				NewNode( p );
			}
			
			void CleanPending()
			{
				if (_pendingNode == null)
					return;
				_pendingNode.RootingCompleted -= OnPendingRooted;
				_pendingNode = null;
			}
			
			void NewNode( Node from )
			{
				if (_curFrom == from)
					return;
					
				CleanListener();
				
				_curFrom = from;
				if (from == null)
				{
					_listener.OnLostData(_expr);
					return;
				}
				
				if (!Selection.TryFindSelectable(_curFrom, out _selectable, out _selection))
				{
					Fuse.Diagnostics.UserError( "Unable to locate a `Selectable` and `Selection`", _expr );
					_listener.OnLostData(_expr);
					return;
				}
			
				_selection.SelectionChanged += OnSelectionChanged;
				_selectable.AddPropertyListener(this);
				PushNewValue();
			}
			
			void PushNewValue()
			{
				if (_selection != null)
					_listener.OnNewData(_expr, _selection.IsSelected(_selectable));
			}
			
			void CleanListener()
			{
				if (_selection == null)
					return;
				_selection.SelectionChanged -= OnSelectionChanged;
				_selectable.RemovePropertyListener(this);
				_selection = null;
				_selectable = null;
			}
			
			public override void Dispose()
			{
				base.Dispose();
				CleanPending();
				CleanListener();
			}
			
			void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector prop)
			{
				if (obj == _selectable)
					PushNewValue();
			}
		
			void OnSelectionChanged(object s, object args)
			{
				PushNewValue();
			}
		}
	}
}

using Uno;
using Uno.Collections;
using Uno.UX;
using Uno.Text;
using Fuse.Scripting;

namespace Fuse
{
	/** Nodes are the basic building blocks of Fuse apps. 

		@topic Nodes

		Nodes are typically instantiated in UX Markup, and come in many different subclasses.

		Subclasses inheriting @Visual have a visual representation on the screen, and/or manages input for a
		specific visual region.

		Subclasses inheriting @Behaviors modify the behavior of @Visuals.

		@remarks Docs/RootedRemarks.md
	*/
	public abstract partial class Node: PropertyObject, IList<Binding>, Scripting.IScriptObject, IProperties,
		INotifyUnrooted, ISourceLocation
	{
		Scripting.Context _scriptContext;
		object _scriptObject;

		object IScriptObject.ScriptObject
		{
			get { return _scriptObject; }
		}

		Scripting.Context IScriptObject.ScriptContext
		{
			get { return _scriptContext; }
		}

		void Scripting.IScriptObject.SetScriptObject(object obj, Scripting.Context context)
		{
			_scriptObject = obj;
			_scriptContext = context;
		}

		Properties _properties;
		/** A linked list holding data for extrinsic properties. */
		public Properties Properties
		{
			get
			{
				if (_properties == null) _properties = new Properties();
				return _properties;
			}
		}

		Visual _parent;

		/** The parent @Visual of this node. Will return null if the node is not rooted. */
		public Visual Parent { get { return _parent; } }

		/** The number of Parent nodes to traverse before reading the root. */
		internal int NodeDepth
		{
			get
			{
				var n = Parent;
				var c = 0;
				while (n != null)
				{
					c++;
					n = n.Parent;
				}
				
				return c;
			}
		}
		
		/**
			The context parent is the semantic parent of this node. It is where non-UI structure should
			be resolved, like looking for the DataContext, a Navigation, or other semantic item.
		*/
		public Node ContextParent
		{
			get { return OverrideContextParent ?? Parent; }
		}
		
		/**
			Allows an alternate contextParent. This will be reset on each unrooting, preventing unrooted
			use, and breaking any loops.
		*/
		[WeakReference]
		internal Node OverrideContextParent;

		public virtual bool TryGetResource(string key, Predicate<object> acceptor, out object resource)
		{
			if (ContextParent != null)
				return ContextParent.TryGetResource(key, acceptor, out resource);

			resource = null;
			return false;
		}

		public virtual void VisitSubtree(Action<Node> action)
		{
			action(this);
		}

		public override string ToString()
		{
			if (!Name.IsNull)
				return base.ToString() + ", Name: " +Name.ToString();
			else
				return base.ToString();
		}

		public string SubtreeToString()
		{
			var sb = new StringBuilder();
			SubtreeToString(sb, 0);
			return sb.ToString();
		}

		protected virtual void SubtreeToString(StringBuilder sb, int indent)
		{
			for (int i = 0; i < indent; i++) sb.Append("  ");
			sb.AppendLine(this.ToString());
		}
		
		/** 
			Allows a way for things that insert nodes (like `Each`) to determine the end of the
			group of nodes further inserted by that node (such as a combination with `Match` or `Deferred`)
		*/
		internal virtual Node GetLastNodeInGroup()
		{
			return this;
		}

		//We want `: Behavior` here. This is an attempt to workaround a Uno/DotNet issue on some platforms
		internal T FindBehavior<T>() where T : Node /*Behavior*/
		{
			var from = this;
			while (from != null)
			{
				//allow specifying the target behavior directly (for overrides). Or the eventual
				//situation where Behaviors can have children
				var b = from as T;
				if (b != null)
					return b;
					
				var v = from as Visual;
				if (v != null)
				{
					var c = v.FirstChild<T>();
					if (c != null)
						return c;
				}
				from = from.ContextParent;
			}
			return null;
		}
		
		public T FindByType<T>() where T : class
		{
			if (this is T) return this as T;
			return GetNearestAncestorOfType<T>();
		}

		public T GetNearestAncestorOfType<T>() where T : class
		{
			Node current = Parent;
			while(current != null)
			{
				if(current is T) return current as T;
				current = current.Parent;
			}
			return null;
		}
		
		[UXLineNumber]
		/** @hide */
		public int SourceLineNumber { get; set; }
		[UXSourceFileName]
		/** @hide */
		public string SourceFileName { get; set; }
		
		ISourceLocation ISourceLocation.SourceNearest
		{
			get
			{
				if (SourceFileName != null)
					return this;
				if (Parent != null)
					return ((ISourceLocation)Parent).SourceNearest;
				return null;
			}
		}
	}
}

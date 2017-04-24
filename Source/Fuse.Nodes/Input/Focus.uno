using Uno;
using Uno.UX;
using Uno.Compiler;


namespace Fuse.Input
{
	public enum FocusNavigationDirection
	{
		Up,
		Down,
		Left,
		Right
	}

	public delegate Visual FocusDelegator();

	public interface INotifyFocus
	{
		void OnFocusLost();
		void OnFocusGained();
	}

	public static partial class Focus
	{
		static readonly FocusGained _gained = new FocusGained();
		static readonly FocusLost _lost = new FocusLost();
		static readonly IsFocusableChangedEvent _isFoucsableChanged = new IsFocusableChangedEvent();

		public static VisualEvent<FocusGainedHandler, FocusGainedArgs> Gained { get { return _gained; } }
		public static VisualEvent<FocusLostHandler, FocusLostArgs> Lost { get { return _lost; } }
		public static VisualEvent<IsFocusableChangedHandler, IsFocusableChangedArgs> IsFocusableChanged { get { return _isFoucsableChanged; }}

		static Visual _focusedObject;
		static Visual _lastFocusedVisual;

		public static Visual FocusedVisual
		{
			get { return _focusedObject; }
		}

		static PropertyHandle _focusDelegatorHandle = Properties.CreateHandle();

		public static void SetDelegator(Visual n, FocusDelegator delegator)
		{
			n.Properties.Set(_focusDelegatorHandle, delegator);
		}

		static FocusDelegator GetDelegator(Visual n)
		{
			object res;
			if (n.Properties.TryGet(_focusDelegatorHandle, out res)) return (FocusDelegator)res;
			return null;
		}

		internal static void OnWindowGotFocus(object sender, EventArgs args)
		{
			//Android we appear to get focus for a control prior to the window event
			ChangeFocusedVisual(_focusedObject ?? _lastFocusedVisual);
		}

		internal static void OnWindowLostFocus(object sender, EventArgs args)
		{
			//ChangeFocusedVisual(null);
		}

		public static void Move(FocusNavigationDirection direction)
		{
			var predictedFocus = Predict(direction);
			if (predictedFocus == null)
				return;

			ChangeFocusedVisual(predictedFocus);
		}

		public static void Release()
		{
			_lastFocusedVisual = null;
			ChangeFocusedVisual(null);
		}
		
		/** Release only if the current focus is the given node. For native integration. */
		public static void ReleaseFrom(Visual n)
		{
			if (FocusedVisual == n)
				Release();
		}
		
		/** Implies this control has obtained the focus, unlike GiveTo this is not a request.*/
		public static void Obtained(Visual n)
		{
			ChangeFocusedVisual(n);
		}

		public static void GiveTo(Visual n)
		{
			ChangeFocusedVisual(n);
		}

		public static bool IsWithin(Visual n)
		{
			var k = FocusedVisual;

			while (k != null)
			{
				if (k == n) return true;
				k = k.Parent;
			}

			return false;
		}

		static Visual FindRoot()
		{
			var app = AppBase.Current;
			if (app != null)
			{
				Visual root = null;

				foreach (var child in app.Children)
				{
					if (child is Visual)
					{
						root = (Visual)child;
						break;
					}
				}

				while (root != null)
				{
					if (root.Parent != null)
					{
						root = root.Parent;
					}
					else break;
				}

				return root;
			}

			return null;
		}

		static Visual Predict(FocusNavigationDirection direction)
		{
			// TODO: Add possibility for custom predictstrategy
			var node = FocusPredictStrategy.Predict(_focusedObject, direction);

			if(node == null)
			{
				var root = FindRoot();
				if(root != null)
				{
					node = FocusPredictStrategy.Predict(root, direction);
					if(node == null && CanSetFocus(root))
						node = root;
				}
			}
			return node;
		}

		static void ChangeFocusedVisual(Visual node, [CallerMemberName] string memberName = "")
		{
			//shortcut to help frequent calls (like from iOS)
			if (node == _focusedObject)
				return;
				
			while (node != null)
			{
				var delegator = GetDelegator(node);
				if (delegator != null)
				{
					node = delegator();
					continue;
				}
				
				var focusDelegate = GetFocusDelegate(node);
				if (focusDelegate != null)
				{
					node = focusDelegate;
					continue;
				}
				
				break;
			}
			
			if (!CanSetFocus(node))
				node = null;
			
			if (node == _focusedObject)
				return;

			//switch focus prior to event so callback checks can see new focus
			_lastFocusedVisual = _focusedObject;
			_focusedObject = node;
			
			if(_lastFocusedVisual != null) 
			{
				var nf = _lastFocusedVisual as INotifyFocus;
				if (nf != null) nf.OnFocusLost();

				Lost.RaiseWithBubble(new FocusLostArgs(_lastFocusedVisual));
			}

			if(_focusedObject != null) 
			{
				var nf = _focusedObject as INotifyFocus;
				if (nf != null) nf.OnFocusGained();
				
				Gained.RaiseWithBubble(new FocusGainedArgs(_focusedObject));
			}
		}

		internal static bool CanSetFocus(Node node)
		{
			if (node == null) return true;
			var v = node as Visual;
			if (v == null) return false;
			return v.IsRootingCompleted && v.IsContextEnabled && IsFocusable(v);
		}

		[UXAttachedPropertyGetter("Focus.IsFocusable")]
		public static bool IsFocusable(Visual n)
		{
			return n._isFocusable;
		}

		[UXAttachedPropertySetter("Focus.IsFocusable")]
		public static void SetIsFocusable(Visual n, bool focusable)
		{
			n._isFocusable = focusable;
		}

		[UXAttachedPropertyResetter("Focus.IsFocusable")]
		public static void ResetIsFocusable(Visual n)
		{
			n._isFocusable = false;
		}

		static void OnIsFocusableChanged(Visual n)
		{
			IsFocusableChanged.RaiseWithoutBubble(new IsFocusableChangedArgs(n));
		}
	
		static internal bool HandlesFocusEvent(Visual n)
		{
			return IsFocusable(n) ||
				GetDelegator(n) != null ||
				GetFocusDelegate(n) != null;
		}
		
		
		[UXAttachedPropertyGetter("Focus.Delegate")]
		public static Visual GetFocusDelegate(Visual n)
		{
			return n._focusDelegate;
		}

		[UXAttachedPropertySetter("Focus.Delegate")]
		public static void SetFocusDelegate(Visual n, Visual d)
		{
			n._focusDelegate = d;
		}

		[UXAttachedPropertyResetter("Focus.Delegate")]
		public static void ResetFocusDelegate(Visual n)
		{
			n._focusDelegate = null;
		}
		
		static void OnFocusDelegateChanged(Visual n) { }
	}
}

using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Elements;
using Fuse.Gestures;
using Fuse.Gestures.Internal;

namespace Fuse.Navigation
{
	public enum NavigationEdge
	{
		Left = Edge.Left,
		Right = Edge.Right,
		Top = Edge.Top,
		Bottom = Edge.Bottom,
		None,
	}

	public sealed class EdgeNavigation : VisualNavigation
	{
		static PropertyHandle _edgeHandle = Properties.CreateHandle();

		[UXAttachedPropertySetter("EdgeNavigation.Edge")]
		static public void SetEdge(Visual elm, NavigationEdge edge)
		{
			elm.Properties.Set(_edgeHandle, edge);
		}

		[UXAttachedPropertyGetter("EdgeNavigation.Edge")]
		static public NavigationEdge GetEdge(Visual elm)
		{
			object res;
			if (elm.Properties.TryGet(_edgeHandle,out res))
				return (NavigationEdge)res;
			return NavigationEdge.None;
		}

		[UXAttachedPropertyResetter("EdgeNavigation.Edge")]
		static public void ResetEdge(Visual elm)
		{
			elm.Properties.Clear(_edgeHandle);
		}

		public override void Goto(Visual element, NavigationGotoMode mode)
		{
			if (mode != NavigationGotoMode.Transition &&
				mode != NavigationGotoMode.Bypass)
				return;
				
			//TODO: mode
			foreach (var sw in _swipers)
			{
				if (sw.Value.Target == element)
					sw.Value.Enable();
				else
					sw.Value.Disable();
			}
			CheckProgress();
		}
		
		public override void Toggle(Visual page)
		{
			if (Active == page)
				Active = null;
			else
				Active = page;
		}

		Visual _active;
		public override Visual Active
		{
			get
			{
				//this is to ensure a RoutePageProxy can identiy the active page (there is no good
				//mapping for Active in an EdgeNavigator, this will have to be rethough at some point)
				if (_active == null && _mains.Count > 0)
					return _mains[0];
				return _active;
			}
			set
			{
				Goto(value, NavigationGotoMode.Transition);
			}
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			if (!(Parent is Element))
			{
				Fuse.Diagnostics.UserRootError( "Element", Parent, this );
				//throw here instead of message, due to later assumption in this code (TODO: fix)
				throw new Exception( "EdgeNavigation must be rooted in an Element" );
			}
				
			CheckChildren();
		}

		protected override void OnUnrooted()
		{
			ClearChildren();
			base.OnUnrooted();
		}

		public override void OnChildAddedWhileRooted(Node child)
		{
			base.OnChildAddedWhileRooted(child);
			CheckChildren();
		}

		public override void OnChildRemovedWhileRooted(Node child)
		{
			base.OnChildRemovedWhileRooted(child);
			CheckChildren();
		}

		Dictionary<NavigationEdge,EdgeSwiper> _swipers = new Dictionary<NavigationEdge,EdgeSwiper>();
		List<Visual> _mains = new List<Visual>()	;

		void ClearChildren()
		{
			foreach (var s in _swipers)
			{
				s.Value.ProgressChanged -= OnProgressChanged;
				s.Value.Unrooted();
			}
			_swipers.Clear();
			_mains.Clear();
		}

		void CheckChildren()
		{
			//inefficient for now (don't expect children to change often)
			ClearChildren();

			for (int i = 0; i < Pages.Count; i++)
			{
				var nodeChild = Pages[i].Visual;

				var element = nodeChild as Element;
				var edge = element == null ? NavigationEdge.None : GetEdge(element);
				if (edge == NavigationEdge.None)
				{
					_mains.Add(nodeChild);
					if (_mains.Count > 1)
						Fuse.Diagnostics.UserWarning( "EdgeNavigation may not work as expected with more than one main (non-edge) page." , this );
				}
				else
				{
					//TODO: duplicates?
					var s = new EdgeSwiper();
					s.Edge = (Edge)edge;
					s.Target = element;
					s.ProgressChanged += OnProgressChanged;
					s.Rooted(Parent as Element);
					_swipers[edge] = s;
				}
			}
			
			OnPageProgressChanged(NavigationMode.Bypass);
		}

		double _maxProgress;
		void OnProgressChanged(object s, double progress)
		{
			var swiper = s as EdgeSwiper;
			var panel = swiper.Target;
			if (panel == null || swiper == null)
			{
				return;
			}
			CheckProgress();
		}
		
		void CheckProgress()
		{
			//determine active page (undefined if multiple open)
			Visual maxPage = null;
			_maxProgress = 0;
			foreach (var sw in _swipers)
			{
				if (sw.Value.Progress > _maxProgress)
				{
					maxPage = sw.Value.Target;
					_maxProgress = sw.Value.Progress;
				}
			}
			var newActive = _maxProgress == 0 ? null : maxPage;
			if (newActive != _active)
			{
				_active = newActive;
				OnActiveChanged(_active);
			}

			OnPageProgressChanged(NavigationMode.Seek);
		}

		//support to get EdgeNavigator working, very rough now
		internal bool IsDismissPoint(float2 windowPoint)
		{
			foreach (var sw in _swipers)
			{
				var local = sw.Value.Target.WindowToLocal(windowPoint);
				if (sw.Value.Target.IsPointInside(local))
					return false;
			}

			return true;
		}

		internal bool IsAnyPanelActive()
		{
			foreach (var sw in _swipers)
			{
				if (sw.Value.Progress > 0)
					return true;
			}
			return false;
		}

		public override void GoBack()
		{
			foreach (var sw in _swipers)
				sw.Value.Disable();
		}

		public override bool CanGoBack { get { return IsAnyPanelActive(); } }

		public override double PageProgress
		{
			get { return GetPageIndex(_active); }
		}
		
		public override NavigationPageState GetPageState(Visual page)
		{
			foreach (var sw in _swipers)
			{
				//panels come from the front (historical decision I guess)
				if(sw.Value.Target == page)
					return new NavigationPageState{ Progress = 1 - (float)sw.Value.Progress,
						PreviousProgress = 0 }; //TODO: Previous
			}
			
			return new NavigationPageState{ Progress = (float)-_maxProgress, PreviousProgress = 0 };
		}
	}
}

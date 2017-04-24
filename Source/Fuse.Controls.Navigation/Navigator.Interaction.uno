using Uno;
using Uno.UX;

using Fuse.Animations;
using Fuse.Elements;
using Fuse.Gestures;
using Fuse.Navigation;
using Fuse.Triggers.Actions;

namespace Fuse.Controls
{
	
	public partial class Navigator
	{
		NavigatorSwipeDirection _swipeBack = NavigatorSwipeDirection.None;
		/**
			Adds a swipe gesture to navigate backwards in the router history.
			
			This specifies the direction the user should swipe to go back. The default is `None`, indicating swiping is not enabled.
			
			This can be disabled on a per-page basis by specifying `SwipeBack="None"` on the page.
		*/
		public NavigatorSwipeDirection SwipeBack
		{
			get { return _swipeBack; }
			set { _swipeBack = value; } //only changes on rooting
		}

		NavigatorSwipe _navigatorSwipeBack;
		NavigatorSwipe NavigatorSwipeBack
		{
			get 
			{
				if (_navigatorSwipeBack == null)
				{
					_navigatorSwipeBack = new NavigatorSwipe();
					Children.Add(_navigatorSwipeBack);
				}
				return _navigatorSwipeBack;
			}
		}
		
		Router _router;
		void RootInteraction()
		{
			if (SwipeBack == NavigatorSwipeDirection.None)
			{
				//in case turned off after unrooting
				if (_navigatorSwipeBack != null)
				{	
					Children.Remove(_navigatorSwipeBack);
					_navigatorSwipeBack = null;
				}
				return;
			}
			
			NavigatorSwipeBack.Direction = SwipeBack;
			NavigatorSwipeBack.How = NavigatorSwipeHow.Back;
				
			//add in local bounds to ensure it always works. There is no way we can determine if the
			//hittestmode has been overidden by the user :/
			HitTestMode = HitTestMode | HitTestMode.LocalBounds;
			
			_router = Router.TryFindRouter(this);
			if (_router == null)
			{
				Fuse.Diagnostics.UserError( "Navigator requires a Router for interaction", this );
				return;
			}
		
			//this is easier than adding a WhileCanGoBack trigger
			_router.HistoryChanged += OnHistoryChanged;
			OnHistoryChanged(null);
		}
		
		void UnrootInteraction()
		{
		}
		
		void OnHistoryChanged(object sender)
		{
			EnablePageSwipeBack();
		}
		
		void CheckInteraction()
		{
			EnablePageSwipeBack();
		}
		
		void EnablePageSwipeBack()
		{
			if (_navigatorSwipeBack != null && _router != null)
			{
				if (!_router.CanGoBack)
				{
					NavigatorSwipeBack.IsEnabled = false;
				}
				else
				{
					NavigatorSwipeBack.IsEnabled = true;
					NavigatorSwipeBack.Direction = PageSwipeBackDirection(_current.Visual);
				}
			}
		}
		
		static PropertyHandle _propSwipeBack = Properties.CreateHandle();
		[UXAttachedPropertySetter("Navigator.SwipeBack")]
		static public void SetSwipeBack(Visual elm, NavigatorSwipeDirection value)
		{
			elm.Properties.Set(_propSwipeBack, value);
		}

		[UXAttachedPropertyGetter("Navigator.SwipeBack")]
		static public NavigatorSwipeDirection GetSwipeBack(Visual elm)
		{
			if (elm != null)
			{
				object res;
				if (elm.Properties.TryGet(_propSwipeBack,out res))
					return (NavigatorSwipeDirection)res;
			}
			return NavigatorSwipeDirection.Default;
		}
		
		NavigatorSwipeDirection PageSwipeBackDirection(Visual elm)
		{
			var n = GetSwipeBack(elm);
			return n == NavigatorSwipeDirection.Default ? SwipeBack : n;
		}
		
	}
}
using Uno;
using Uno.UX;

using Fuse.Scripting;

namespace Fuse.Navigation
{
	public enum NavigationDirection
	{
		Forward, Backward
	}

	/**
		What type of navigation page transition is being performed.
		
		Each mode should be explicitly handled to allow for future additions.
	*/
	public enum NavigationGotoMode
	{	
		/** The request is for a normal transition (animated) to the target page */
		Transition,
		/** The request is to immediately change to target page bypassing any animations  */
		Bypass,
		/** This page is being prepared for an interactive transition, such as the user sliding the page into view.
			The indicated page becomes the target of partial progress. If this is not supported then nothing happens and partial progress does not work.
		*/
		Prepare,
	}

	public class NavigatedArgs: EventArgs, IScriptEvent
	{
		public Visual NewVisual { get; private set; }
		
		public NavigatedArgs(Visual newVisual)
		{
			NewVisual = newVisual;
		}

		void IScriptEvent.Serialize(IEventSerializer s)
		{
			if (NewVisual.Name != null) s.AddString("name", NewVisual.Name);
			else s.AddString("name", "");
		}
	}
	
	public delegate void NavigatedHandler(object sender, NavigatedArgs args);
	public delegate void HistoryChangedHandler(object sender);
	public delegate void NavigationPageCountHandler(object sender);
	public delegate void NavigationPageProgressHandler(object sender, double Current, double Previous);
	public delegate void ActivePageChangedHandler(object sender, Visual active);
	public delegate void NavigationStateChangedHandler(object sender, ValueChangedArgs<NavigationState> args );

	/**
		A minimal interface implemented by simple navigation behaviors and controls.
	*/
	public interface IBaseNavigation
	{
		void GoForward();
		void GoBack();
		bool CanGoBack { get; }
		bool CanGoForward { get; }
		event HistoryChangedHandler HistoryChanged;
	}

	public struct NavigationPageState
	{
		public float Progress;
		public float PreviousProgress;
	}
	
	/**
		An extended navigation interface implemented by full navigation behaviors.
		
		This API is subject to significant changes in coming versions. Though previously not marked as experimental, there is a need to consolidate and group some of the events and states to remain maintainable, fix some defects, and add some required features.
		@experimental
	*/
	public interface INavigation : IBaseNavigation
	{
		int PageCount { get; }
		double PageProgress { get; }
		Visual GetPage(int index);
		Visual ActivePage { get; }
		NavigationPageState GetPageState(Visual page);
		NavigationState State { get; }
		
		/** @hide */
		event NavigationPageCountHandler PageCountChanged;
		/** @hide */
		event NavigationHandler PageProgressChanged;
		/** @hide */
		event NavigatedHandler Navigated;
		/** @hide */
		event ActivePageChangedHandler ActivePageChanged;
		/** @hide */
		event ValueChangedHandler<NavigationState> StateChanged;
		
		void Goto(Visual node, NavigationGotoMode mode = NavigationGotoMode.Transition);
		void Toggle(Visual node);
	}
	
	//this is internal for now as it was done quickly to resolve an issue, and not thought about as a feature
	internal interface ISeekableNavigation : INavigation
	{
		void BeginSeek();
		float2 SeekRange { get; }
		void Seek(UpdateSeekArgs args);
		void EndSeek(EndSeekArgs args);
	}
}
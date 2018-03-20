using Uno;
using Uno.Collections;
using Uno.Text;

namespace Fuse
{
	enum RootStage
	{
		Unrooted,
		Started,
		Completed,
		Unrooting,
	}

	interface INotifyUnrooted
	{
		event Action Unrooted;
	}

	public abstract partial class Node
	{
		RootStage _rootStage = RootStage.Unrooted;

		/** Whether rooting of this node has started.
			Note that even if this property returns true, rooting may not yet be
			completed for the node. See also @IsRootingCompleted. */
		public bool IsRootingStarted
		{
			get { return _rootStage == RootStage.Started || _rootStage == RootStage.Completed; }
		}
		
		internal virtual bool ShouldRootChildren
		{
			get { return IsRootingStarted; }
		}

		/** Whether rooting for this node is completed.
			Returns false if unrooting has started. */
		public bool IsRootingCompleted { get { return _rootStage == RootStage.Completed; } }

		internal bool IsUnrooting { get { return _rootStage == RootStage.Unrooting; } }
		
		internal bool IsUnrooted { get { return _rootStage == RootStage.Unrooted; } }

		/*
			Rooting is done in groups. The initial call to `RootInternal` will capture the rooting group and release it when it is done. This is important for Triggers that need to know if an operation is being performed during rooting or not. Simply tracking the UpdateManager.FrameIndex is not enough since multiple operations can happen in one frame that may require distinct groups (NavigatorTest.DeferredActivation).
			
			Anything that wants to manually open a frame can follow the pattern in RootInternal.
		*/
		static int _rootCaptureIndex = 0;
		static internal int RootCaptureIndex { get { return _rootCaptureIndex; } }
		static internal bool IsRootCapture( int index )
		{
			return _hasRootCapture && index == _rootCaptureIndex;
		}
		static bool _hasRootCapture = false;
		static internal bool CaptureRooting()
		{
			if (_hasRootCapture)
				return false;
				
			_rootCaptureIndex++;
			//wraparound protection (just in case, also allows 0 to be a non-value)
			if (_rootCaptureIndex < 1)
				_rootCaptureIndex = 1;
				
			_hasRootCapture = true;
			return true;
		}
		static internal void ReleaseRooting(bool captured)
		{
			if (!captured)
				return;
				
			UpdateManager.AddDeferredAction( _laterReleaseRooting, LayoutPriority.EndGroup );
		}
		
		static Action _laterReleaseRooting = LaterReleaseRooting;
		static void LaterReleaseRooting()
		{
			_hasRootCapture = false;
		}
		
		/**
			This is the prime entry point to rooting. No other rooting function should be called outside of a call to this function (and it's descendent calls in turn).
		*/
		internal void RootInternal(Visual parent)
		{
			bool captured = CaptureRooting();
			try
			{
				RootInternalImpl(parent);
			}
			finally
			{
				ReleaseRooting(captured);
			}
		}
			
		void RootInternalImpl(Visual parent)
		{
			//to help detect errors like https://github.com/fusetools/fuselibs-private/issues/2244
			if (_rootStage != RootStage.Unrooted)
				throw new Exception( "Incomplete or duplicate rooting: " + this + "/" + Name );

			if (_parent != null)
			{
				if (_parent != parent) throw new Exception("Node is already rooted with a different parent");
				else
				{
					// This case happens e.g. when a trigger was adding nodes while rooting. Don't root again!
					return;
				}
			}

			_rootStage = RootStage.Started;
			_parent = parent;

			if (Name != null)
				NameRegistry.SetName(this, Name);

			OnRooted();

			_rootStage = RootStage.Completed;

			if (RootingCompleted != null)
				RootingCompleted();

			//to help detect errors like https://github.com/fusetools/fuselibs-private/issues/2244
			if (_rootStage != RootStage.Completed)
				throw new Exception( "Invalid RootStage post rooting: " + this + "/" + Name );
		}

		internal event Action RootingCompleted;

		/**
			If you override `OnRooted` you must call `base.OnRooted()` first in your derived class. No other processing should happen first, otherwise you might end up in an undefined state.
		*/
		protected virtual void OnRooted()
		{
			RootBindings();
		}

		internal event Action Unrooted;

		event Action INotifyUnrooted.Unrooted
		{
			add { this.Unrooted += value; }
			remove { this.Unrooted -= value; }
		}

		internal void UnrootInternal()
		{
			if (_rootStage == RootStage.Unrooted) return;
			if (_rootStage != RootStage.Completed)
				throw new Exception( "Incomplete or duplicate unrooting: " + this + "/" + Name );

			_rootStage = RootStage.Unrooting;

			OnUnrooted();
			if (Unrooted != null)
				Unrooted();

			if (Name != null)
				NameRegistry.ClearName(this);

			OverrideContextParent = null;
			SoftDispose();

			_parent = null;
			_rootStage = RootStage.Unrooted;
		}

		protected virtual void OnUnrooted()
		{
			UnrootBindings();
		}

		internal static void Relate(Visual parent, Node child)
		{
			if (child != null)
			{
				if (parent.ShouldRootChildren) child.RootInternal(parent);
			}
		}

		internal static void Unrelate(Visual parent, Node child)
		{
			//Refer to Issue1063 test for a scenario where we end up during the unrooting process
			if (child != null && !child.IsUnrooting)
			{
				child.UnrootInternal();
			}
		}

		protected virtual void SoftDispose() { }
		
		int _preservedRootFrame = -1;
		
		internal bool IsPreservedRootFrame
		{
			get { return _preservedRootFrame == UpdateManager.FrameIndex; }
		}
		
		/**
			Indicates that a Node is about is to be unrooted, but the next rooting should as much as possible
			behave as though it were rooted before. This is most relevant for `Placeholder` and `Trigger`.
			
			This is limited to unrooting/rooting within the same frame now. Delayed rerooting will be
			treated as a new rooting (we have no use-case to support this yet).
		*/
		internal void PreserveRootFrame()
		{
			VisitSubtree(IterPreserveRootFrame);
		}
		
		void IterPreserveRootFrame(Node n)
		{
			n.OnPreserveRootFrame();
		}
		
		internal virtual void OnPreserveRootFrame()
		{
			_preservedRootFrame = UpdateManager.FrameIndex;
		}
	}
}

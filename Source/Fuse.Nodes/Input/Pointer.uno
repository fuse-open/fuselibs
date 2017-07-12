using Uno;
using Uno.Collections;

namespace Fuse.Input
{
	[Flags]
	/**
		Multiple captures can be performed on a single point index. The type indicates the type of interest the capture has on the pointer events.
	*/
	public enum CaptureType
	{
		None = 0,
		/**
			A soft capture is a non-exclusive capture which allows any other soft captures to also exist. These are used when a gesture has not yet been fully identified (selection of gestures), or the capturer never needs to make visual feedback, or if the capturer doesn't care about losing the capture.
			
			Only one of Soft or Hard can be specified.
		*/
		Soft = 1 << 0,
		/**
			A hard capture indicates a strong desire to be the exclusive recipient of pointer events. It likely means visual feedback is being tied to this capture, and tries to intentionally exclude other behaviors from also acting on the same feedback.
		*/
		Hard = 1 << 1,
		/**
			Targetting still looks at children. Normally the pointer input is directed strictly to the bottom most capture element. This allows capturing within part of the UI tree.
		*/
		Children = 1 << 2,
		/**
			Multiple Soft/Hard-NodeShared captures can exist on the same node. Usually a hard capture will release all other captures. NodeShare allows captures on the same node to persist even in the presence of a hard capture.
			
			This is use for specific situations such as a SwipeGesture in a ScrollView where it makes sense that both gestures can handle the same input at the same time.
		*/
		NodeShare = 1 << 3,
	}
	
	static public class CaptureTypeHelper
	{
		static public bool GainedCapture( CaptureType prev, CaptureType next )
		{
			return !prev.HasFlag(CaptureType.Soft) && !prev.HasFlag(CaptureType.Hard) &&
				(next.HasFlag(CaptureType.Soft) || next.HasFlag(CaptureType.Hard));
		}
		
		static public bool BecameHard( CaptureType prev, CaptureType next )
		{
			return !prev.HasFlag(CaptureType.Hard) && next.HasFlag(CaptureType.Hard);
		}
	}
	
	internal class Capture
	{
		public Visual Visual { get; private set; }
		public int VisualDepth;
		public object Identity { get; private set; }
		public Action LostCallback;
		public CaptureType Type = CaptureType.None;
		
		public bool Deleted;

		public List<int> PointIndex = new List<int>(); //TODO: make and use a MiniList
		
		public Capture(Visual n, object identity)
		{
			if (n == null || identity == null)
				throw new Exception( "Invalid Capture parameters" );
				
			Visual = n;
			Identity = identity;
			
			//calc VisualDepth
			VisualDepth = 0;
			var q = Visual;
			while (q.Parent != null)
			{
				VisualDepth++;
				q = q.Parent;
			}
		}
		
		public bool AcceptsPoint( int index)
		{
			return PointIndex.Contains(index);
		}
		
		public bool IsSuitable
		{
			get 
			{
				return Visual.IsContextEnabled &&
					Visual.IsRootingCompleted;
			}
		}
		
		public int CompareStrength(Capture o)
		{
			var hardThis = Type.HasFlag(CaptureType.Hard);
			var hardO = o.Type.HasFlag(CaptureType.Hard);
			if (hardThis == hardO)
				return 0;
				
			return hardThis ? 1 : -1;
		}
	}

	public interface IPointerEventResponder
	{
		void OnPointerPressed(PointerPressedArgs args);
		void OnPointerMoved(PointerMovedArgs args);
		void OnPointerReleased(PointerReleasedArgs args);
		void OnPointerWheelMoved(PointerWheelMovedArgs args);
	}

	/**
		Directly using the `Pointer` class is not advised. For all typical UI controls you should iuse the @Gestures system. The gesture system is better able to deal with conflict between gestures.

		## Captures
		
		A capture indicates some listener is interested in receiving events for a pointer event even if they no longer hit the target visual. Any capture blocks events from being sent outside of the tree starting at the provided visual.
		
		An `identity` is used to identify the capture listener. Each identity has only one capture. This may be at different levels, or involve single or multiple pointer indexes. Multiple captures with the same `identity` can not be created -- it always modifies the existing one.
		
		Only one `CaptureType.Hard` can exist for a `PointIndex` at one time. This will also cancel all soft captures that also accept that point (even if it isn't the only point they accept). An exception is those with `NodeShare`.

		@advanced
	*/
	public static partial class Pointer
	{
		public static IPointerEventResponder EventResponder { get; set; }

		static Pointer()
		{
			EventResponder = new DefaultPointerEventResponder();
		}

		static PointerPressed _pressed = new PointerPressed();
		static PointerMoved _moved = new PointerMoved();
		static PointerReleased _released = new PointerReleased();
		static PointerEntered _entered = new PointerEntered();
		static PointerLeft _left = new PointerLeft();
		static PointerWheelMoved _wheelMoved = new PointerWheelMoved();

		public static VisualEvent<PointerPressedHandler, PointerPressedArgs> Pressed { get { return _pressed; } }
		public static VisualEvent<PointerMovedHandler, PointerMovedArgs> Moved { get { return _moved; } }
		public static VisualEvent<PointerReleasedHandler, PointerReleasedArgs> Released { get { return _released; } }
		public static VisualEvent<PointerEnteredHandler, PointerEnteredArgs> Entered { get { return _entered; } }
		public static VisualEvent<PointerLeftHandler, PointerLeftArgs> Left { get { return _left; } }
		public static VisualEvent<PointerWheelMovedHandler, PointerWheelMovedArgs> WheelMoved { get { return _wheelMoved; } }

		public static void AddHandlers(Visual node, 
			PointerPressedHandler pressed = null, 
			PointerMovedHandler moved = null, 
			PointerReleasedHandler released = null, 
			PointerEnteredHandler entered = null,
			PointerLeftHandler left = null,
			PointerWheelMovedHandler wheelMoved = null)
		{
			if (pressed != null) Pressed.AddHandler(node, pressed);
			if (moved != null) Moved.AddHandler(node, moved);
			if (released != null) Released.AddHandler(node, released);
			if (entered != null) Entered.AddHandler(node, entered);
			if (left != null) Left.AddHandler(node, left);
			if (wheelMoved != null) WheelMoved.AddHandler(node, wheelMoved);
		}

		public static void RemoveHandlers(Visual node, 
			PointerPressedHandler pressed = null, 
			PointerMovedHandler moved = null, 
			PointerReleasedHandler released = null, 
			PointerEnteredHandler entered = null,
			PointerLeftHandler left = null,
			PointerWheelMovedHandler wheelMoved = null)
		{
			if (pressed != null) Pressed.RemoveHandler(node, pressed);
			if (moved != null) Moved.RemoveHandler(node, moved);
			if (released != null) Released.RemoveHandler(node, released);
			if (entered != null) Entered.RemoveHandler(node, entered);
			if (left != null) Left.RemoveHandler(node, left);
			if (wheelMoved != null) WheelMoved.RemoveHandler(node, wheelMoved);
		}

		

		public static float2[] Coords
		{
			get
			{
				var f = new float2[_pointersDown.Count];
				int i = 0;
				foreach (var p in _pointersDown) f[i++] = p.Value.WindowPoint;
				return f;
			}
		}

		class PointerRecord
		{
			public float2 WindowPoint;
			public bool WasHandled;
			public float DistanceMoved;
			public double TimeAppeared = Uno.Diagnostics.Clock.GetSeconds();

			public double TimeSinceAppeared { get { return Uno.Diagnostics.Clock.GetSeconds() - TimeAppeared; } }
		}

		static Dictionary<int, PointerRecord> _pointersDown = new Dictionary<int, PointerRecord>();

		internal static void ClearPointersDown()
		{
			_pointersDown.Clear();
		}

		public static bool IsPressed()
		{
			return _pointersDown.Count > 0;
		}

		public static bool IsPressed(int pointIndex)
		{
			foreach (var p in _pointersDown) if (p.Key == pointIndex) return true;
			return false;
		}

		public static float2 Coord { get; private set; }

		static List<Capture> _captures = new List<Capture>();

		class CaptureLockImpl : IDisposable
		{
			public int Count;
			public bool AnyDeleted;
			
			public void Dispose()
			{
				if (--Count > 0)
					return;
					
				//safety
				if (Count < 0)
				{
					Fuse.Diagnostics.InternalError( "Inconsistent Count", this );
					Count = 0;
				}
				
				if (AnyDeleted)
				{
					for (int i=_captures.Count-1; i >= 0; --i )
					{
						if (_captures[i].Deleted)
							_captures.RemoveAt(i);
					}
					AnyDeleted = false;
				}
			}
			
			public void Delete( Capture c )
			{
				c.Deleted = true;
				AnyDeleted = true;
			}
		}
		static CaptureLockImpl _captureLockImpl = new CaptureLockImpl();
		
		static CaptureLockImpl CaptureLock()
		{
			_captureLockImpl.Count++;
			return _captureLockImpl;
		}

		internal static Capture GetPrimaryCapture(int pointIndex)
		{
			Capture best = null;
			using (var cl = CaptureLock())
			{
				for (int i=0; i < _captures.Count; ++i)
				{
					var c = _captures[i];
					if (c.Deleted)
						continue;
						
					if (!c.AcceptsPoint(pointIndex))
						continue;
						
					//drop nodes that are no longer suitable
					if (!c.IsSuitable)
					{
						c.LostCallback();
						cl.Delete(c);
						continue;
					}
					
					var str = best == null ? 1 : c.CompareStrength(best);
					if ( (str > 0) || //first come wins on tie
						(str == 0 && c.VisualDepth > best.VisualDepth)) //or lower in tree on tie
						best = c;
				}
			}
			return best;
		}
		
		internal static Capture GetCapture(object identity)
		{
			using (var cl = CaptureLock())
			{
				for (int i=0; i < _captures.Count; ++i)
				{
					var c = _captures[i];
					if (c.Deleted)
						continue;
						
					if (c.Identity != identity)	
						continue;
					
					return c;
				}
			}
			
			return null;
		}

		public static bool IsCaptured(int pointIndex, object identity)
		{
			return IsCaptured( CaptureType.None, pointIndex, identity );
		}
		
		public static bool IsCaptured(CaptureType type, int pointIndex, object identity)
		{
			return GetFirstCapture( type, pointIndex, identity ) != null;
		}
		
		static Capture GetFirstCapture( CaptureType type, int pointIndex, object identity )
		{
			for (int i=0; i < _captures.Count; ++i)
			{
				var c = _captures[i];
				if (c.Deleted)
					continue;
				if (pointIndex >= 0 && !c.AcceptsPoint(pointIndex))
					continue;
				if (identity != null && c.Identity != identity)
					continue;
				if ( (c.Type & type) != type )
					continue;
					
				return c;
			}
			return null;
		}
		
		/**
			Is the new capture request allowed based on what is already in the capture list.
		*/
		static bool IsCaptureAllowed( CaptureType type, Visual visual, int pointIndex, object identity )
		{
			for (int i=0; i < _captures.Count; ++i)
			{
				var c = _captures[i];
				if (c.Deleted)
					continue;
				if (!IsCaptureAllowedAgainst( c, type, visual, pointIndex, identity ))
					return false;
			}
			
			return true;
		}
		
		/**
			Is the capture allowed given an existing `current` capture?
		*/
		static bool IsCaptureAllowedAgainst( Capture current, CaptureType type, Visual visual, 
			int pointIndex, object identity )
		{
			if (current.Identity == identity)
				return true;
			if (!current.AcceptsPoint(pointIndex))
				return true;
				
			if (current.Type.HasFlag(CaptureType.Hard))
				return visual == current.Visual && current.Type.HasFlag(CaptureType.NodeShare) && 
					type.HasFlag(CaptureType.NodeShare);
					
			return true;
		}

		/**
			Remove any captures that are no longer allowed due to `to` being added to the list.
		*/
		static void LoseSoftCapturesTo( Capture to )
		{
			using(var cl = CaptureLock())
			{
				for (int i=0; i < _captures.Count; ++i)
				{
					var c = _captures[i];
					if (c.Deleted)
						continue;
			
					for (int p=0; p < c.PointIndex.Count; ++p)
					{
						if (!IsCaptureAllowedAgainst( to, c.Type,  c.Visual, c.PointIndex[p], c.Identity))
						{
							c.LostCallback();
							cl.Delete(c);
							break;
						}
					}
				}
			}
		}
		
		
		/**
			Releases a capture with the provided identity. The `LostCallback` will not be called.
			
			If no capture with this identity exists then nothing happens. This makes this function safe to call during cleanup.
		*/
		public static void ReleaseCapture(object identity)
		{
			using (var cl = CaptureLock())
			{
				for (int i=_captures.Count - 1; i >= 0; --i)
				{
					var c = _captures[i];
					if (c.Deleted)
						continue;
					if (c.Identity == identity)
						cl.Delete(c);
				}
			}
		}
		
		internal static void LoseCapture(int pointIndex)
		{
			using (var cl = CaptureLock())
			{
				for (int i=_captures.Count - 1; i >= 0; --i)
				{
					var c = _captures[i];
					if (c.Deleted)
						continue;
					if (c.AcceptsPoint(pointIndex))
					{
						c.LostCallback();
						cl.Delete(c);
					}
				}
			}
		}

		/**
			Only one capture per identity is allowed. If an existing capture is overridden the previous lostCallback will not be called.
			
			@return true if the capture succeeded. false if it was not allowed due to something else having a higher priority capture.
		*/
		public static bool ModifyCapture(object identity, Visual visual, Action lostCallback,
			CaptureType type, int pointIndex)
		{
			if (lostCallback == null)
				throw new Exception( "Capture requires lostCallback Action" );
			if (identity == null)
				throw new Exception( "Capture requires identity object" );
			if (visual == null)
				throw new Exception( "Capture requires visual" );
			//we can't emit an error here as there are too many cases with async events, especially 
			//with Gesture, where the state suddenly changes. Simply failing should be fine
			if (!visual.IsContextEnabled || !visual.IsRootingCompleted)
				return false;
				
			if (!IsCaptureAllowed( type, visual, pointIndex, identity ))
				return false;
				
			var c = GetCapture(identity);
			if (c != null)
			{
				if (c.Visual != visual)
					Fuse.Diagnostics.InternalError( "Cannot modify the Visual of a capture", identity);
			}
			else
			{
				c = new Capture(visual, identity);
				_captures.Add(c);
			}
			
			c.Type = type;
			c.LostCallback = lostCallback;
			c.PointIndex.Clear();
			c.PointIndex.Add(pointIndex);
			
			LoseSoftCapturesTo(c);
				
			return true;
		}
		
		/**
			Modifies the type of an existing capture.
		*/
		public static bool ModifyCapture(object identity, CaptureType type)
		{
			var c = GetCapture(identity);
			if (c == null)
			{
				Fuse.Diagnostics.InternalError( "Attempting to modify an unknown capture", identity );
				return false;
			}
			
			//we don't check for existing hard capture, since they would have cleared any soft ones for
			//the point already (also checked in ExtendCapture)
			
			c.Type = type;
			LoseSoftCapturesTo(c);
			return true;
		}
		
		/**
			Adds more points to an existing capture. All the points will be captured in the same fashion as the original capture (such as Hard or Soft).
			
			@return `false` if this is not allowed based on other captures (existing hard capture for example). In this case the original capture will be left unchanged. `true` if the capture now watches this new point in addition to any previous points.
		*/
		public static bool ExtendCapture(object identity, int pointIndex)
		{
			var c = GetCapture(identity);
			if (c == null)
			{
				Fuse.Diagnostics.InternalError( "Attempting to extend unknown capture", identity );
				return false;
			}
			
			if (!IsCaptureAllowed( c.Type, c.Visual, pointIndex, c.Identity ))
				return false;
			
			if (!c.PointIndex.Contains(pointIndex))
				c.PointIndex.Add(pointIndex);
			
			LoseSoftCapturesTo(c);
				
			return true;
		}
		
		internal static bool RaisePressed(Visual root, PointerEventData data)
		{
			var target = RoutePointerEvent(data, root);
			var e = new PointerPressedArgs(data, target);
			EventResponder.OnPointerPressed(e);
			return e.IsHandled;
		}

		internal static bool RaiseMoved(Visual root, PointerEventData data)
		{
			var target = RoutePointerEvent(data, root);
			var e = new PointerMovedArgs(data, target);
			EventResponder.OnPointerMoved(e);
			return e.IsHandled;
		}

		internal static bool RaiseReleased(Visual root, PointerEventData data)
		{
			var target = RoutePointerEvent(data, root);
			var e = new PointerReleasedArgs(data, target);
			EventResponder.OnPointerReleased(e);
			
			//finger's left, so nothing can be hovering anymore
			if (data.PointerType == Uno.Platform.PointerType.Touch)
				ProcessPointerEnterLeave(null, data);
				
			return e.IsHandled;
		}

		internal static bool RaiseWheelMoved(Visual root, PointerEventData data)
		{
			var target = RoutePointerEvent(data, root);
			var e = new PointerWheelMovedArgs(data, target);
			EventResponder.OnPointerWheelMoved(e);
			return e.IsHandled;
		}
		
		internal static void RaiseLeft(Visual root, PointerEventData data)
		{
			ProcessPointerEnterLeave(null, data);
		}

		static Visual RoutePointerEvent(PointerEventData plainEvent, Visual root)
		{	
			var target = root;
			bool toHit = true;
			
			var c = GetPrimaryCapture(plainEvent.PointIndex);
			if (c != null)
			{
				target = c.Visual;
				toHit = c.Type.HasFlag(CaptureType.Children);
			}

			if (toHit)
			{
				var n = RouteToHit(plainEvent, target);
				if (n != null) 
					target = n;
			}

			return target;
		}

		static Visual RouteToHit(PointerEventData args, Visual root)
		{
			var result = HitTestHelpers.HitTestNearest(root, args.WindowPoint);

			//disabled nodes are skipped, so that a softcapture can actually grab this event at the closest enabled node
			while (result != null && !result.HitObject.IsContextEnabled)
				result.HitObject = result.HitObject.Parent;
			
			ProcessPointerEnterLeave(result, args);

			if (result == null) 
				return null;

			return result.HitObject;
		}

		static void ProcessPointerEnterLeave(HitTestResult result, PointerEventData args)
		{
			var lastHitList = GetLastHitList(args.PointIndex);
			MarkAncestorHits( result == null ? null : result.HitObject, lastHitList );

			for (int j = lastHitList.Count-1; j >=0; j-- )
			{
				if (lastHitList[j].Status != PELStatus.Removed)
					continue;
					
				//Use "Force" since anything that got enter must get leave
				Left.RaiseWithoutBubble(new PointerLeftArgs(args, lastHitList[j].Visual), VisualEventMode.Force);
				lastHitList.RemoveAt(j);
			}

			for (int j = 0; j < lastHitList.Count; ++j)
			{
				if (lastHitList[j].Status != PELStatus.Added)
					continue;
				Entered.RaiseWithoutBubble(new PointerEnteredArgs(args, lastHitList[j].Visual), VisualEventMode.Enabled);
			}

		}

		static void MarkAncestorHits(Visual hitObject, List<PELHolder> list)
		{
			for( int i=0; i < list.Count; ++i )
				list[i].Status = PELStatus.Removed;
				
			while (hitObject != null)
			{
				bool found = false;
				for (int i=0; i < list.Count; ++i)
				{
					if (list[i].Visual == hitObject)
					{
						list[i].Status = PELStatus.Remain;
						found = true;
						break;
					}
				}
				
				if (!found)
				{
					list.Add( new PELHolder{
						Visual = hitObject,
						Status = PELStatus.Added,
					});
				}
				
				hitObject = hitObject.Parent;
			}
		}

		enum PELStatus
		{
			Added,
			Removed,
			Remain,
		}
		class PELHolder
		{
			public Visual Visual;
			public PELStatus Status;
		}
		
		static Dictionary<int, List<PELHolder>> _lastHitVisuals = 
			new Dictionary<int, List<PELHolder>>();

		static List<PELHolder> GetLastHitList(int pointIndex)
		{
			List<PELHolder> lastHitList = null;
			if (!_lastHitVisuals.TryGetValue(pointIndex, out lastHitList))
			{
				lastHitList = new List<PELHolder>();
				_lastHitVisuals.Add(pointIndex, lastHitList);
			}
			return lastHitList;
		}

		/**
			On pointer down the focus is released unless something in the path handles
			the event or creates a focus event.
		*/
		static void CheckFocus(PointerPressedArgs args, IList<Visual> nodes)
		{
			if (args.IsHandled)
				return;
				
			var b = false;
			for (int i=0; i < nodes.Count; ++i)
			{
				if (Focus.HandlesFocusEvent(nodes[i]))
				{
					b = true;
					break;
				}
			}
			
			if (!b)
			{
				Focus.Release();
			}
		}


		class DefaultPointerEventResponder : IPointerEventResponder
		{
			public void OnPointerPressed(PointerPressedArgs args)
			{
				var p = new PointerRecord()
				{
					WindowPoint = args.WindowPoint,
					DistanceMoved = 0
				};

				_pointersDown[args.PointIndex] = p;

				Coord = args.WindowPoint;

				if (args.Visual == null)
				{
					Focus.Release();
					return;
				}

				Pressed.RaiseWithBubble(args, VisualEventMode.Enabled, CheckFocus);
				p.WasHandled = args.IsHandled;
			}

			public void OnPointerMoved(PointerMovedArgs args)
			{
				if (_pointersDown.ContainsKey(args.PointIndex))
				{
					var p = _pointersDown[args.PointIndex];

					p.DistanceMoved += Vector.Length(args.WindowPoint-p.WindowPoint);
					p.WindowPoint = args.WindowPoint;
				}

				Coord = args.WindowPoint;
				
				if (args.Visual == null) return;

				Moved.RaiseWithBubble(args, VisualEventMode.Enabled);
			}

			public void OnPointerReleased(PointerReleasedArgs args)
			{
				if (_pointersDown.ContainsKey(args.PointIndex))
				{
					var p = _pointersDown[args.PointIndex];
					p.DistanceMoved += Vector.Length(args.WindowPoint-p.WindowPoint);
					_pointersDown.Remove(args.PointIndex);
				}
				Coord = args.WindowPoint;

				if (args.Visual == null) return;

				Released.RaiseWithBubble(args, VisualEventMode.Enabled);
			}

			public void OnPointerWheelMoved(PointerWheelMovedArgs args)
			{
				if (args.Visual == null) return;

				WheelMoved.RaiseWithBubble(args, VisualEventMode.Enabled);
			}
			
			
			/***** Deprecated interface, doesn't work fully *****/
			[Obsolete("Use IsCaptured instead")]
			public static bool IsSoftCaptured(int pointIndex)
			{ return IsCaptured( CaptureType.Soft, pointIndex, null ); }
			
			[Obsolete("Use IsCaptured instead")]
			public static bool IsSoftCaptured(int pointIndex, object capturerIdentity)
			{ 
				DeprecatedCapture();
				return IsCaptured( CaptureType.Soft, pointIndex, capturerIdentity ); 
			}
			
			[Obsolete("Use ReleaseCapture instead")]
			public static void ReleaseSoftCapture(int pointIndex, object identity)
			{ 
				DeprecatedCapture();
				ReleaseCapture(identity); 
			}
			
			[Obsolete("Use ReleaseCapture instead")]
			public static void ReleaseAllCaptures(object identity)
			{
				DeprecatedCapture();
				ReleaseCapture(identity);
			}
			
			[Obsolete("Use IsCaptured instead")]
			public static bool IsHardCaptured(int pointIndex)
			{ 
				return IsCaptured( CaptureType.Hard, pointIndex, null );
			}
			
			[Obsolete("Use IsCaptured instead")]
			public static bool IsHardCaptured(int pointIndex, object behavior)
			{ 
				DeprecatedCapture();
				return IsCaptured( CaptureType.Hard, pointIndex, behavior ); 
			}
			
			[Obsolete("Use ReleaseCapture instead")]
			public static void ReleaseHardCapture(int pointIndex)
			{
				DeprecatedCapture();
				var c = GetFirstCapture( CaptureType.Hard, pointIndex, null );
				if (c != null)
					ReleaseCapture(c.Identity);
			}
			
			static bool _dcWarn;
			static void DeprecatedCapture()
			{
				//DEPRECATED: 2017-02-21
				if (_dcWarn)
					return;
				
				Fuse.Diagnostics.Deprecated( "The capture system no longer supports distinct captures for Soft and Hard capture, instead treating the same identity/behaviour as a single capture. Old code will only work if it captured just one pointer, and followed the pattern of soft then hard capture on it (or just a hard capture). It's advisable to migrate to avoid any potential issues.", null );
				_dcWarn = true;
			}
			/***** End deprecated interface *****/
		}
	}
}

using Uno;
using Fuse.Scripting;

namespace Fuse.Input
{
	public class PointerEventData
	{
		public int PointIndex;
		public float2 WindowPoint;
		public float2 WheelDelta;
		public Uno.Platform.WheelDeltaMode WheelDeltaMode;
		public bool IsPrimary;
		public Uno.Platform.PointerType PointerType;
		public double Timestamp;
	}

	public abstract class PointerEventArgs : VisualEventArgs
	{
		PointerEventData _data;

		internal PointerEventData Data { get { return _data; } }

		public double Timestamp { get { return _data.Timestamp; }}

		public float2 WindowPoint { get { return _data.WindowPoint; } }
		public float2 WheelDelta { get  { return _data.WheelDelta; } }
		public Uno.Platform.WheelDeltaMode WheelDeltaMode { get { return _data.WheelDeltaMode; } }
		public int PointIndex { get { return _data.PointIndex; } }
		public Uno.Platform.PointerType PointerType { get { return _data.PointerType; } }
		public bool IsPrimary { get { return _data.IsPrimary; } }

		public bool TryHardCapture(object identity, Action lostCallback, Visual captureVisual = null )
		{
			return Pointer.ModifyCapture(identity, captureVisual ?? Visual, lostCallback,
				CaptureType.Hard, PointIndex );
		}

		public bool TrySoftCapture(object identity, Action lostCallback, Visual captureVisual = null )
		{
			return Pointer.ModifyCapture(identity, captureVisual ?? Visual, lostCallback,
				CaptureType.Soft, PointIndex );
		}

		public void ReleaseCapture(object behavior)
		{
			Pointer.ReleaseCapture(behavior);
		}

		public bool IsSoftCapturedTo(object behavior)
		{
			return Pointer.IsCaptured(CaptureType.Soft, PointIndex, behavior);
		}

		public bool IsCapturedTo(object behavior)
		{
			return Pointer.IsCaptured(PointIndex, behavior);
		}
		
		internal bool IsHardCaptured
		{
			get { return Pointer.IsCaptured(CaptureType.Hard, PointIndex, null); }
		}

		public bool IsHardCapturedTo(object behavior)
		{
			return Pointer.IsCaptured(CaptureType.Hard, PointIndex, behavior);
		}

		internal protected PointerEventArgs(PointerEventData data, Visual visual): base(visual)
		{
			_data = data;
		}

		override void Serialize(IEventSerializer s)
		{
			s.AddDouble("x", WindowPoint.X);
			s.AddDouble("y", WindowPoint.Y);
			s.AddInt("index", PointIndex);

			var localPoint = Visual.WindowToLocal(WindowPoint);
			s.AddDouble("localX", localPoint.X);
			s.AddDouble("localY", localPoint.Y);
		}
	}
}

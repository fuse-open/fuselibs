using Uno;
using Uno.Graphics;
using Uno.UX;

namespace Fuse.Drawing
{
	[UXGlobalModule]
	/** @hide */
	public class BrushConverter: Marshal.IConverter
	{
		public bool CanConvert(Type t) 
		{
			return t == typeof(Brush) || t.IsSubclassOf(typeof(Brush));
		}
		public object TryConvert(Type t, object o)
		{
			if (CanConvert(t))
			{
				var b = new SolidColor();
				b.SetColor(Marshal.ToFloat4(o));
				return b;
			}
			return null;
		}
		
		static BrushConverter()
		{
			Marshal.AddConverter(new BrushConverter());
		}
	}
	
	public abstract class Brush: PropertyObject
	{
		apply PreMultipliedAlphaCompositing;
		
		public virtual bool IsCompletelyTransparent { get { return false; }}

		//This must be premultiplied
		public float4 FinalColor : prev, float4(0,0,0,0);
		PixelColor: FinalColor;

		//size of the filling canvas
		public float2 CanvasSize: prev, float2(1);

		// Internal so that derived classes outside Fuse.Drawing must
		// explicitly inherit either DynamicBrush or StaticBrush
		internal Brush() {}
		
		int _pinCount;
		public void Pin()
		{
			_pinCount++;
			if (_pinCount == 1)
				OnPinned();
		}
		
		public void Unpin()
		{
			_pinCount--;
			if (_pinCount == 0)
				OnUnpinned();
		}
		
		public bool IsPinned { get { return _pinCount > 0; } }
		
		public void Prepare(DrawContext dc, float2 canvasSize) 
		{ 
			if (!IsPinned)
				Fuse.Diagnostics.InternalError( "Brush is not pinned, preparation invalid", this );
			OnPrepare(dc, canvasSize);
		}
		
		protected virtual void OnPrepare(DrawContext dc, float2 canvasSize) { }
		
		protected virtual void OnPinned() { }
		protected virtual void OnUnpinned() { }
	}

	public abstract class StaticBrush: Brush {}

	public abstract class DynamicBrush: Brush
	{
		public override bool IsCompletelyTransparent { get { return Opacity == 0; } }

		static Selector _opacityName = "Opacity";
		float _opacity = 1.0f;
		public float Opacity
		{
			get { return _opacity; }
			set
			{
				if (value == _opacity) return;
				_opacity = value;
				OnPropertyChanged(_opacityName);
			}
		}
		
		PixelColor: prev * Opacity;
	}
}

using Uno;
using Uno.Content.Fonts;
using Uno.UX;

using Fuse;
using Fuse.Elements;
using Fuse.Triggers;

public partial class FpsMeter
{
	protected override void OnRooted()
	{
		base.OnRooted();
		IsVisibleChanged += OnIsVisibleChanged;
		UpdateListen();
	}
	
	protected override void OnUnrooted()
	{
		IsVisibleChanged -= OnIsVisibleChanged;
		UpdateListen(true);
		base.OnUnrooted();
	}
	
	void OnIsVisibleChanged(object s, object a)
	{
		UpdateListen();
	}
	
	bool _listening;
	void UpdateListen(bool forceOff = false)
	{
		var should = IsVisible && !forceOff;
		
		if (should == _listening)
			return;
			
		_initial = true;
		if (should)
			UpdateManager.AddAction(OnUpdate);
		else
			UpdateManager.RemoveAction(OnUpdate);
		_listening = should;
	}
	
	double _fpsShort;
	double _fpsLong;
	bool _initial = true;
	
	double _updateIn;
	
	void OnUpdate()
	{
		//assume a timing glitch / startup timing
		if (Time.FrameInterval < 1/500.0f)
			return;
			
		var fps = 1 / Time.FrameInterval;
		
		var alphaShort = 1 / 20.0f;
		_fpsShort = _initial ? fps : Math.Lerp( _fpsShort, fps, alphaShort );
		
		var alphaLong = 1 / 120.0f;
		_fpsLong = _initial ? fps : Math.Lerp( _fpsLong, fps, alphaLong );
		//fast drop, but slow recovery
		_fpsLong = Math.Min( _fpsLong, fps );
	
		//only update infrequently to avoid display flickering
		_updateIn -= Time.FrameInterval;
		if (_updateIn < 0 || _initial)
		{
			FpsLong.Value = (float)_fpsLong;
			FpsShort.Value = (float)_fpsShort;
			_updateIn = 0.5f;
		}
		
		_initial = false;
		
	}
}

/**
	This is just a stop-gap until TextControl supports a `Renderer` property to select
	a different renderer. Since native text is very slow we need a faster one here
	to not affect the FPS much in the meter itself.
*/
public class FastText : Element
{
	static DefaultTextRenderer _renderer = new DefaultTextRenderer();

	string _value = "";
	public string Value
	{
		get { return _value; }
		set 
		{
			if (_value != value)
			{
				_value = value;
				Invalidate(this);
			}
		}
	}
	
	float _fontSize = 18;
	public float FontSize
	{
		get { return _fontSize; }
		set { _fontSize = value; Invalidate(this); }
	}
	
	float4 _textColor = float4(0,0,0,1);
	public float4 TextColor
	{
		get { return _textColor; }
		set { _textColor = value; Invalidate(this); }
	}
	
	static void Invalidate(FastText ft)
	{
		ft._measured = false;
		ft.InvalidateVisual(); //we're "fast", assume layout doesn't change (stretched/fixed size)
	}
	
	public FastText()
	{
		_renderer.FontFace = import FontFace("Assets/texgyreheros-regular.otf");
	}
	
	bool _measured;
	float2 _size;
	void Measure()
	{
		_size = _renderer.MeasureString(FontSize, Viewport.PixelsPerPoint, _value);
		_measured = true;
	}
	
	protected override void OnDraw(DrawContext dc)
	{
		if (!_measured)
			Measure();
			
		
		_renderer.BeginRendering(FontSize, Viewport.PixelsPerPoint, WorldTransform,
			2*ActualSize, TextColor, _value.Length );
		_renderer.DrawLine(dc, ActualSize.X/2*Viewport.PixelsPerPoint - _size.X/2, 
			0/*ActualSize.Y/2*PointDensity - _size.Y/2*/, _value );
		_renderer.EndRendering(dc);
	}
	
	protected override VisualBounds CalcRenderBounds()
	{
		return base.CalcRenderBounds().AddRect(float2(0),ActualSize);
	}
}

	//quick copy of Fuse.Controls.Number (Ideally Text-like items would take a renderer)
namespace Fuse.Controls
{
	public class FastNumber : Panel, IValue<float>
	{
		FastText _text;
		public FastNumber()
		{
			_text = new FastText();
			Children.Add(_text);
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			UpdateValue();
		}
		
		string _format = "F0";

		public string Format
		{
			get { return _format; }
			set { _format = value; FormatChanged(this); }
		}
		
		static void FormatChanged(FastNumber n)
		{
			n.UpdateValue();
		}

		float _value = 0;
		public float Value
		{
			get { return _value; }
			set { _value = value; StaticValueChanged(this);}
		}
		
		static void StaticValueChanged(FastNumber n)
		{
			n.UpdateValue();
			n.OnValueChanged(n.Value,n);
		}
		
		public event ValueChangedHandler<float> ValueChanged;
		
		void OnValueChanged(float n, object origin)
		{
			if (ValueChanged != null)
			{
				var args = new ValueChangedArgs<float>(n);
				ValueChanged(n, args);
			}
		}
		
		void UpdateValue()
		{
			_text.Value = String.Format( "{0:" + Format + "}", Value);
		}
	}
}

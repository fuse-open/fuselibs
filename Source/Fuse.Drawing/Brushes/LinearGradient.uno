using Uno;
using Uno.Collections;
using Uno.Collections.EnumerableExtensions;
using Uno.Graphics;
using Uno.UX;


namespace Fuse.Drawing
{
	/** See @LinearGradient */
	public sealed class GradientStop: PropertyObject
	{
		static Selector _offsetName = "Offset";
		float _offset;
		public float Offset
		{
			get { return _offset; }
			set
			{
				if (_offset != value)
				{
					_offset = value;
					OnPropertyChanged(_offsetName);
				}
			}
		}

		static Selector _colorName = "Color";
		float4 _color = float4(1);
		/**
			The color to be used for the gradient stop.

		 	For more information on what notations Color supports, check out [this subpage](articles:ux-markup/literals#colors).
		*/
		public float4 Color
		{
			get { return _color; }
			set
			{
				if (_color != value)
				{
					_color = value;
					OnPropertyChanged(_colorName);
				}
			}
		}

		public GradientStop() {}

		public GradientStop(float4 color, float offset)
		{
			_color = color;
			_offset = offset;
		}
	}

	public enum LinearGradientInterpolation
	{
		/** Linearly interpolates colors between the GradientStop's */
		Linear,
		/** Smoothly interpolates colors between the GradientStop's */
		Smooth,
	}
	
	/**
		A linear gradient @Brush.
		
		@LinearGradient lets you describe a linear gradient using a collection of @GradientStops.
		The following example displays a @Rectangle with a @LinearGradient that fades from white at the top, to black at the bottom.

		```
		<Rectangle>
			<LinearGradient StartPoint="0,0" EndPoint="0,1">
				<GradientStop Offset="0" Color="#fff" />
				<GradientStop Offset="1" Color="#000" />
			</LinearGradient>
		</Rectangle>
		```
		
		You may also specify any number of @GradientStops.
		
		```
		<Circle>
			<LinearGradient AngleDegrees="90">
				<GradientStop Offset="0" Color="#f00" />
				<GradientStop Offset="0.3" Color="#f0f" />
				<GradientStop Offset="0.6" Color="#00f" />
				<GradientStop Offset="1" Color="#0ff" />
			</LinearGradient>
		</Circle>
		```

		The `StartPoint` and `EndPoint` properties are both specified as a proportion of the total size of the @Shape the brush is applied to.
		For instance, you can specify a diagonal brush by using `StartPoint="0,0" EndPoint="1,1"`.

		Instead of `StartPoint` and `EndPoint`, you can also specify an angle. This can either be in radians using the `Angle` property, or in degrees using the `AngleDegrees` property.

		```
		<LinearGradient Angle="2.4" />
		              or
		<LinearGradient AngleDegrees="45" />
		```
	*/
	public class LinearGradient: DynamicBrush, IPropertyListener
	{
		static Selector _stopsName = "Stops";
		static Selector _stopOffsetName = "Offset";
		static Selector _stopColorName = "Color";
		static Selector _interpolationName = "Interpolation";

		void IPropertyListener.OnPropertyChanged(PropertyObject sender, Selector property)
		{
			if (property == _stopOffsetName || property == _stopColorName)
			{
				_invalid = true;
			}
			OnPropertyChanged(_stopsName);
		}

		RootableList<GradientStop> _stops = new RootableList<GradientStop>();

		static GradientStop[] _emptySortedStops = new GradientStop[0];
		public GradientStop[] SortedStops { get { return ToArray(_stops) ?? _emptySortedStops; } }

		[UXContent]
		public IList<GradientStop> Stops { get { return _stops; } }

		static Selector _startPointName = "StartPoint";
		float2 _startPoint;

		/** 
			Check to ensure that stops are in the right order. If they are not, throw an exception, as the code assumes they are ordered correctly.
		*/
		static void ValidateStopsSorted(IList<GradientStop> stops)
		{
			for (int i = 1; i < stops.Count; ++i)
			{
				if (stops[i].Offset < stops[i - 1].Offset)
					throw new Exception(String.Format("Gradient stop offsets must be in order! Expected something bigger or equal to {0}, but got {1}!", stops[i - 1].Offset, stops[i].Offset));
			}
		}

		/**
			The starting point of the gradient. Can be used together with `EndPoint` instead of specifying an `Angle`.
			Specified as a proportion of the total size of the @Shape the brush is applied to.
			This means that, for instance, a value of `0, 1` results in the gradient starting at the bottom-left corner.
		*/
		public float2 StartPoint
		{
			get { return _startPoint; }
			set
			{
				if (_startPoint != value)
				{
					_startPoint = value;
					OnPropertyChanged(_startPointName);
				}
			}
		}

		static Selector _endPointName = "EndPoint";
		float2 _endPoint = float2(0,1);

		/**
			The ending point of the gradient. Can be used together with `StartPoint` instead of specifying an `Angle`.
			Specified as a proportion of the total size of the @Shape the brush is applied to.
			This means that, for instance, a value of `1, 1` results in the gradient ending at the bottom-right corner.
		*/
		public float2 EndPoint
		{
			get { return _endPoint; }
			set
			{
				if (_endPoint != value)
				{
					_endPoint = value;
					OnPropertyChanged(_endPointName);
				}
			}
		}
		
		static Selector _angleName = "Angle";
		float _angle;
		bool _hasAngle;
		/** The angle of the gradient in radians. Can be used instead of `StartPoint` and `EndPoint`. */
		public float Angle
		{
			get { return _angle; }
			set
			{
				if (_angle != value || !_hasAngle)
				{
					_angle = value;
					_hasAngle = true;
					OnPropertyChanged(_angleName);
				}
			}
		}
		
		/** The angle of the gradient in degrees. Can be used instead of `StartPoint` and `EndPoint`. */
		public float AngleDegrees
		{
			get { return Math.RadiansToDegrees(_angle); }
			set { Angle = Math.DegreesToRadians(value); }
		}
		
		public bool HasAngle { get { return _hasAngle; } }

		LinearGradientInterpolation _interpolation = LinearGradientInterpolation.Linear;
		/**
			Defines how the colors are interpolatied between the points.
			
			The default is `Linear`.
		*/
		public LinearGradientInterpolation Interpolation
		{
			get { return _interpolation; }
			set
			{
				if (_interpolation == value)
					return;
					
				_interpolation = value;
				OnPropertyChanged(_interpolationName);
			}
		}
		
		static int SelectOffset(GradientStop a, GradientStop b)
		{
			return (int)Math.Sign(a.Offset - b.Offset);
		}

		void OnAdded(GradientStop gs)
		{
			gs.AddPropertyListener(this);
			_invalid = true;
			
			if (IsPinned)
			{
				OnPropertyChanged(_stopsName);
				ValidateStopsSorted(_stops);
			}
		}

		void OnRemoved(GradientStop gs)
		{
			gs.RemovePropertyListener(this);
			_invalid = true;
			
			if (IsPinned)
				OnPropertyChanged(_stopsName);
		}

		public LinearGradient()
		{
		}

		public LinearGradient(params GradientStop[] stops)
		{
			foreach (var s in stops) _stops.Add(s);
		}
		
		protected override void OnPinned()
		{
			base.OnPinned();
			_stops.RootSubscribe(OnAdded, OnRemoved);
		}
		
		static LinearGradient()
		{
			_gradientSize = Math.Min( 1028, texture2D.MaxSize );
		}
		
		static int _gradientSize = 256;
		
		//public for `draw`
		public framebuffer _gradientBuffer; 
		public float2 _gradientStart;
		bool _invalid = true;
		protected override void OnPrepare(DrawContext dc, float2 canvasSize)
		{
			if (_gradientBuffer == null)
			{
				_gradientBuffer = FramebufferPool.Lock( int2(_gradientSize,1), Format.RGBA8888, false );
				_invalid = true;
			}
			
			if (_invalid)
			{
				_gradientStart = LinearGradientDrawable.Singleton.FillBuffer(dc, this, _gradientBuffer);
				_invalid = false;
			}
		}
		
		protected override void OnUnpinned()
		{
			_stops.RootUnsubscribe();
			
			if (_gradientBuffer != null)
			{
				FramebufferPool.Release(_gradientBuffer);
				_gradientBuffer = null;
				_invalid = true;
			}
			
			base.OnUnpinned();
		}
		
		public float4 GetEffectiveEndPoints( float2 size ) 
		{
			if (!HasAngle)
				return float4(StartPoint * size, EndPoint * size);
				
			//for Angle this matches the CSS definition so that the gradient nominal start/end (0,1) are in the two corners
			var angleLen = Math.Abs( size.X * Math.Cos(Angle) ) + 
				Math.Abs( size.Y * Math.Sin(Angle) );
			var angleSlope = float2(Math.Cos(Angle), Math.Sin(Angle));
			var angleStartPoint = (size/2 - angleSlope*angleLen/2);
			var angleEndPoint = (size/2 + angleSlope*angleLen/2);
			
			return float4(angleStartPoint, angleEndPoint);
		}

		float4 endPoints: GetEffectiveEndPoints(CanvasSize);
		float2 startPoint: endPoints.XY;
		float2 endPoint: endPoints.ZW;
		float2 tLineSlope: Vector.Normalize(endPoint - startPoint);
		float tLineLen: Vector.Length(endPoint - startPoint);
		
		float tc: req(TexCoord as float2)
		{
			var v = TexCoord * CanvasSize - startPoint;
			var p = Vector.Dot(v, tLineSlope) / tLineLen;
			return (p - _gradientStart.X) / _gradientStart.Y;
		};
		
		FinalColor: sample(_gradientBuffer.ColorBuffer,float2(tc,0.5f), Uno.Graphics.SamplerState.LinearClamp);
	}
	
	class LinearGradientDrawable
	{
		static public LinearGradientDrawable Singleton = new LinearGradientDrawable();
		
		public float2 FillBuffer(DrawContext dc, LinearGradient lg, framebuffer fb)
		{
			var stops = lg.SortedStops;
			if (stops.Length < 2)
				return float2(0,1);
				
			var length = stops[stops.Length-1].Offset - stops[0].Offset;
			
			dc.PushRenderTarget(fb);

			bool smooth = lg.Interpolation == LinearGradientInterpolation.Smooth;
			draw
			{
				float2[] Vertices: new []
				{
					float2(0, 0), float2(0, 1), float2(1, 1),
					float2(0, 0), float2(1, 1), float2(1, 0)
				};
				float2 TexCoord: vertex_attrib(Vertices);
				ClipPosition: float4(TexCoord.X*2-1,-TexCoord.Y*2+1,0,1);
				DepthTestEnabled: false;
				BlendEnabled: false;
				
				float[] Offsets :
				{
					var ofs = new float[Math.Max(stops.Length,1)];
					for (int i = 0; i < stops.Length; i++) ofs[i] = stops[i].Offset;
					return ofs;
				};

				float4[] Colors :
				{
					var cols = new float4[Math.Max(stops.Length,1)];
					for (int i = 0; i < stops.Length; i++) cols[i] = stops[i].Color;
					return cols;
				};

				float2 tc: req(TexCoord as float2) pixel TexCoord;

				PixelColor:
				{
					var p = Offsets[0] + length * tc.X;

					var color = float4(Colors[0].XYZ*Colors[0].W,Colors[0].W);

					for (int i = 0; i < Offsets.Length-1; i++)
					{
						var step1 = Offsets[i];
						var step2 = Offsets[i+1];

						var color2 = Colors[i+1];

						color = Uno.Math.Lerp(
							color, 
							float4(color2.XYZ*color2.W, color2.W), 
							smooth ? Uno.Math.SmoothStep(step1, step2, p) : LinearStep(step1,step2,p));
					}

					return color;
				};
			};

			dc.PopRenderTarget();
			
			return float2(stops[0].Offset, length);
		}
		
		public static float LinearStep(float edge0, float edge1, float x)
		{
			return Math.Clamp((x - edge0) / (edge1 - edge0), 0.0f, 1.0f);
		}
		
	}
}

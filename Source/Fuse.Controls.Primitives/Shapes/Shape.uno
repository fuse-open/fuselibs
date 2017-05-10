using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Drawing;
using Fuse.Elements;
using Fuse.Controls.Native;

namespace Fuse.Controls
{
	/** Displays a shape with fills and strokes
	
		Shape is the baseclass for all shapes in fuse. A shape can have @Fills and @Strokes.
		By default a shape does not have a size, fills or strokes. You must add some for it to be visible.

		## Example:
			
			<Rectangle Width="200" Height="100" CornerRadius="16">
				<LinearGradient>
					<GradientStop Offset="0" Color="#0ee" />
					<GradientStop Offset="1" Color="#e0e" />
				</LinearGradient>
				<Stroke Width="2">
					<SolidColor Color="#000" />
				</Stroke>
			</Rectangle>
			

			<Circle Width="200" Height="100" >
				<LinearGradient>
					<GradientStop Offset="0" Color="#cf0" />
					<GradientStop Offset="1" Color="#f40" />
				</LinearGradient>
				<Stroke Width="1">
					<SolidColor Color="#000" />
				</Stroke>
			</Circle>

			
		## Available Shape classes:

		[subclass Fuse.Controls.Shape]
		
		
		## Strokes
		
		Use only one of the methods of specifying strokes. Either list the desired `Stroke` objects as children, or provide a single object to the `Stroke` property, or specify one or more of `StrokeColor`, `StrokeWidth`, and `StrokeAlignment`.
		
		It is undefined what happens if the different ways of specifying a stroke are combined.
	*/
	public abstract partial class Shape : LayoutControl, ISurfaceDrawable, IPropertyListener,
		IDrawObjectWatcherFeedback
	{
		/**
			The color of the `Shape`

		 	For more information on what notations Color supports, check out [this subpage](articles:ux-markup/literals#colors).
		*/
		[UXOriginSetter("SetColor")]
		public float4 Color
		{
			get 
			{ 
				var f = Fill as ISolidColor; 
				if (f != null) return f.Color;
				return float4(0);
			}
			set 
			{ 
				SetColor(value, this);
			}
		}
		public void SetColor(float4 value, IPropertyListener origin)
		{
			if (Color != value)
			{
				OnColorChanged(value, origin);
			}
		}

		public static readonly Selector ColorPropertyName = "Color";
		void OnColorChanged(float4 value, IPropertyListener origin)
		{
			if (!(Fill is SolidColor))
	 			Fill = new SolidColor(value);
	 		else
	 			((SolidColor)Fill).Color = value;

			OnPropertyChanged(ColorPropertyName, origin as IPropertyListener);
		}

		/** The `Fill` property sets a single fill on the `Shape` */
		public Brush Fill
		{
			get 
			{ 
				if (_fills == null || _fills.Count == 0) return null;
				else return _fills[0];
			}
			set 
			{
				Fills.Clear();
				if (value != null)
					Fills.Add(value);
			}
		}

		RootableList<Brush> _fills;

		/** The `Fills`-property contains a collection of @Brush elements */
		[UXPrimary]
		public IList<Brush> Fills
		{
			get
			{
				if (_fills == null)
				{
					_fills = new RootableList<Brush>();
					if (IsRootingCompleted)
						_fills.Subscribe(OnFillAdded, OnFillRemoved);
				}
				return _fills;
			}
		}

		void OnFillAdded(Brush f)
		{
			// When style is reset f is null (this should never happen anymore)
			if (f == null)
			{
				Fuse.Diagnostics.InternalError( "Unexpected null brush", this );
				return;
			}
			
			f.Pin();
			AddDrawCost(1);

			if (f is DynamicBrush)
			{
				((DynamicBrush)f).AddPropertyListener(this);
			}
			
			AddLoadingResource( f );
			
			InvalidateRenderBounds();
			UpdateNativeShape();
		}

		void OnFillRemoved(Brush f)
		{
			// When style is reset f is null (this should never happen anymore)
			if (f == null)
			{
				Fuse.Diagnostics.InternalError( "Unexpected null brush", this );
				return;
			}
			
			f.Unpin();
			RemoveDrawCost(1);

			if (f is DynamicBrush)
			{
				((DynamicBrush)f).RemovePropertyListener(this);
			}
			
			RemoveLoadingResource( f );

			InvalidateRenderBounds();
			UpdateNativeShape();
		}

		static Selector _widthName = "Width";
		static Selector _offsetName = "Offset";

		public override void OnPropertyChanged(PropertyObject sender, Selector property)
		{
			OnLoadingResourcePropertyChanged(sender, property);
			
			if (sender is Brush) InvalidateVisual();
			else if (sender is Stroke) 
			{
				InvalidateVisual();
				if (property == _widthName || property == _offsetName) 
					InvalidateRenderBounds();
			}
			else base.OnPropertyChanged(sender, property);

			UpdateNativeShape();
		}

		public bool HasFills { get { return _fills != null && _fills.Count > 0; } }

		/** 
			Applies a single `Stroke` to the `Shape`.
		*/
		
		public Stroke Stroke
		{
			get 
			{ 
				if (_strokes == null || _strokes.Count ==0) return null;
				return _strokes[0];
			}
			set 
			{ 
				Strokes.Clear();
				if (value != null)
					Strokes.Add(value);
			}
		}

		/** Whether or not the `Shape` have any `Stroke`s applied */
		public bool HasStrokes { get { return _strokes != null && _strokes.Count > 0; } }

		List<Stroke> _styleStrokes;

		/** 
			A `Stroke`s that will be drawn on the shape. These are drawn layered from bottom-to-top.
			
			These are drawn on top of any fills the shape has.
		*/
		RootableList<Stroke> _strokes;
		[UXContent]
		public IList<Stroke> Strokes
		{
			get
			{
				if (_strokes == null)
				{
					_strokes = new RootableList<Stroke>();
					if (IsRootingCompleted)
						_strokes.Subscribe(OnStrokeAdded, OnStrokeRemoved);
				}
				return _strokes;
			}
		}
		
		Stroke DefaultStroke
		{
			get
			{
				var strokes = Strokes;
				if (strokes.Count == 0 || !(strokes[0].Brush is SolidColor))
				{
					strokes.Clear();
					strokes.Add( new Stroke{ Alignment= StrokeAlignment.Center,
						Width = 1, Brush = new SolidColor{ Color = float4(0,0,0,1) } } );
				}
				return strokes[0];
			}
		}
		
		SolidColor DefaultStrokeBrush
		{
			get
			{
				return DefaultStroke.Brush as SolidColor;
			}
		}
		
		/**
			Sets the color of the stroke for the shape.
		*/
		public float4 StrokeColor
		{
			get { return HasStrokes ? DefaultStrokeBrush.Color : float4(0); }
			set { DefaultStrokeBrush.Color = value; }
		}
		
		/**
			Sets the width of the stroke for the shape.
		*/
		public float StrokeWidth
		{
			get { return HasStrokes ? DefaultStroke.Width : 0; }
			set { DefaultStroke.Width = value; }
		}
		
		/**
			Sets the alignment of the stroke for the shape.
			
			The default is `Center` unlike a `Stroke` object which uses `Inner` as the default.
		*/
		public StrokeAlignment StrokeAlignment
		{
			get { return HasStrokes ? DefaultStroke.Alignment : StrokeAlignment.Center; }
			set { DefaultStroke.Alignment = value; }
		}

		void OnStrokeAdded(Stroke s)
		{
			// When style is reset s is null (this should never happen anymore)
			if (s == null)
			{
				Fuse.Diagnostics.InternalError( "Unexpected null stroke", this );
				return;
			}
			
			s.Pin();
			AddDrawCost(1);
			s.AddPropertyListener(this);

			InvalidateRenderBounds();
			UpdateNativeShape();
		}

		void OnStrokeRemoved(Stroke s)
		{
			if (s == null)
			{
				Fuse.Diagnostics.InternalError( "Unexpected null stroke", this );
				return;
			}
			
			s.Unpin();
			RemoveDrawCost(1);
			s.RemovePropertyListener(this);
			
			InvalidateRenderBounds();
			UpdateNativeShape();
		}

		float _smoothness = 1;
		public float Smoothness
		{
			get { return _smoothness; }
			set 
			{ 
				if (_smoothness != value)
				{
					_smoothness = value;
					InvalidateVisual();
					InvalidateRenderBounds();
				}
			}
		}

		Surface _surface;
		protected Surface Surface { get { return _surface; } }
		DrawObjectWatcher _watcher;
		//internal and not protected since DrawObjectWatcher is an internal class
		internal DrawObjectWatcher Watcher { get { return _watcher; } }
		
		protected override void OnRooted()
		{
			base.OnRooted();
			if (_strokes != null)
			{
				for (int i=0; i < _strokes.Count; ++i)
					OnStrokeAdded(_strokes[i]);
				_strokes.Subscribe(OnStrokeAdded, OnStrokeRemoved);
			}
			if (_fills != null)
			{
				for (int i=0; i < _fills.Count; ++i)
					OnFillAdded(_fills[i]);
				_fills.Subscribe(OnFillAdded, OnFillRemoved);
			}

			OnLoadingResourceRooted();
			
			_surface = NeedSurface ? SurfaceManager.FindOrCreate(this) : SurfaceManager.Find(this);
			if (_surface != null)
				OnSurfaceRooted();
		}

		protected override void OnUnrooted()
		{
			base.OnUnrooted();
			if (_strokes != null)
			{
				for (int i=0; i < _strokes.Count; ++i)
					OnStrokeRemoved(_strokes[i]);
				_strokes.Unsubscribe();
			}
			if (_fills != null)
			{
				for (int i=0; i < _fills.Count; ++i)
					OnFillRemoved(_fills[i]);
				_fills.Unsubscribe();
			}

			OnLoadingResourceUnrooted();
			
			if (_surface != null)	
				OnSurfaceUnrooted();
		}
		
		internal virtual void PrepareDraw(DrawContext dc, float2 canvasSize)
		{
			if (HasFills)
			{
				for (int i=0; i < _fills.Count; ++i)
					_fills[i].Prepare(dc, canvasSize);
			}
			if (HasStrokes)
			{
				for (int i=0; i < _strokes.Count; ++i)
					_strokes[i].Prepare(dc, canvasSize);
			}
		}

		IShapeView NativeShape
		{
			get { return NativeView as IShapeView; }
		}

		void UpdateNativeShape()
		{
			var ns = NativeShape;
			if (ns != null)
			{
				var fills = HasFills
					? Fills.ToArray()
					: new Brush[0];

				var strokes = HasStrokes
					? Strokes.ToArray()
					: new Stroke[0];

				ns.Update(fills, strokes, Viewport.PixelsPerPoint);
			}
		}

		protected override void PushPropertiesToNativeView()
		{
			base.PushPropertiesToNativeView();
			UpdateNativeShape();
		}
		
		protected override void ArrangePaddingBox(LayoutParams lp)
		{
			base.ArrangePaddingBox(lp);
			InvalidateSurfacePath();
		}
		
	}
}

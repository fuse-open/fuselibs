using Uno;
using Uno.Collections;
using Uno.Collections.EnumerableExtensions;
using Uno.Compiler.ExportTargetInterop;

using Fuse.Drawing;

namespace Fuse.Controls.Native.iOS
{

	[Require("Source.Include", "UIKit/UIKit.h")]
	[Require("Source.Include", "iOS/Helpers.h")]
	[Require("Source.Include", "CoreGraphics/CoreGraphics.h")]
	[Require("Source.Include", "QuartzCore/QuartzCore.h")]
	extern(iOS) internal abstract class Shape : View, IShapeView
	{
		protected Shape() : base(Create()) { }

		internal protected override void OnPositionChanged() { OnShapeChanged(); }
		internal protected override void OnSizeChanged() { OnShapeChanged(); }

		protected float2 ShapePosition { get { return float2(0.0f); } }
		protected float2 ShapeSize { get { return Size; } }

		Brush[] _fills;
		Stroke[] _strokes;
		void IShapeView.Update(Brush[] fills, Stroke[] strokes, float pixelsPerPoint)
		{
			_fills = fills;
			_strokes = strokes;
			OnShapeChanged();
		}

		protected void OnShapeChanged()
		{
			var layerCount = 
				(_fills != null ? _fills.Length : 0) +
				(_strokes != null ? _strokes.Length : 0);

			MakeLayers(Handle, layerCount);

			var path = CreatePath();
			var layer = 0;
			if (_fills != null)
			{
				for (var i = 0; i < _fills.Length; i++)
					SetBrush(_fills[i], layer++, path, false, 0.0f);
			}

			if (_strokes != null)
			{
				for (var i = 0; i < _strokes.Length; i++)
				{
					if (_strokes[i].Brush != null)
						SetBrush(_strokes[i].Brush, layer, path, true, _strokes[i].Width);
					layer++;
				}
			}

		}

		void SetBrush(Brush brush, int layer, ObjC.Object path, bool isLine, float strokeWidth)
		{
			if (brush is LinearGradient)
			{
				SetLinearGradient((LinearGradient)brush, layer, path, isLine, strokeWidth);
			}
			else
			{
				var c = float4(0);
				var sc = brush as Fuse.Drawing.SolidColor;
				if (sc != null)
					c = sc.Color;
				var ssc = brush as Fuse.Drawing.StaticSolidColor;
				if (ssc != null)
					c = ssc.Color;
					
				if (sc == null && ssc == null)
					Fuse.Diagnostics.Unsupported( "", brush );

				var db = brush as DynamicBrush;
				SetBrush(Handle, c.X, c.Y, c.Z, c.W, layer, path, isLine, strokeWidth, db != null ? db.Opacity : 1.0f);
			}
		}

		static int SelectOffset(GradientStop a, GradientStop b)
		{
			return (int)Math.Sign(a.Offset - b.Offset);
		}

		void SetLinearGradient(LinearGradient gradient, int layer, ObjC.Object path, bool isLine, float strokeWidth)
		{
			var stops = OrderBy(gradient.Stops, SelectOffset).ToArray();
			var colors = new float[stops.Length * 4];
			var offsets = new float[stops.Length];

			for (var i = 0; i < stops.Length; i++)
			{
				colors[(i * 4) + 0] = stops[i].Color.X;
				colors[(i * 4) + 1] = stops[i].Color.Y;
				colors[(i * 4) + 2] = stops[i].Color.Z;
				colors[(i * 4) + 3] = stops[i].Color.W;
				offsets[i] = stops[i].Offset;
			}

			SetLinearGradient(
				Handle,
				layer,
				path,
				isLine,
				strokeWidth,
				gradient.StartPoint.X,
				gradient.StartPoint.Y,
				gradient.EndPoint.X,
				gradient.EndPoint.Y,
				colors,
				offsets,
				ShapeSize.X,
				ShapeSize.Y);
		}

		[Foreign(Language.ObjC)]
		static void SetLinearGradient(
			ObjC.Object handle,
			int layerIndex,
			ObjC.Object pathHandle,
			bool isLine,
			float strokeWidth,
			float startX,
			float startY,
			float endX,
			float endY,
			float[] colors,
			float[] offsets,
			float width,
			float height)
		@{
			UIControl* uicontrol = [(ShapeView*)handle shapeView];
			UIBezierPath* path = (UIBezierPath*)pathHandle;
			CAShapeLayer* layer = (CAShapeLayer*)([[uicontrol layer] sublayers][layerIndex]);
			

			CAGradientLayer* gradientLayer = [[CAGradientLayer alloc] init];

			CAShapeLayer* mask = [CAShapeLayer layer];
			[mask setFillColor: [UIColor whiteColor].CGColor];
			[mask setFrame:CGRectMake(0.0f, 0.0f, width, height)];

			if (isLine)
			{
				[mask setFillColor:[UIColor clearColor].CGColor];
				[mask setStrokeColor:[UIColor whiteColor].CGColor];
				[mask setLineWidth:strokeWidth];
			}
			else
			{
				[mask setFillColor:[UIColor whiteColor].CGColor];
				[mask setStrokeColor:nil];
			}
			
			[mask setPath: path.CGPath];
			[gradientLayer setMask: mask];

			[layer addSublayer:gradientLayer];

			auto gradientStops = @{float[]:Of(offsets).Length:Get()};

			NSMutableArray* locations = [[NSMutableArray alloc] initWithCapacity:gradientStops];	

			for (int i = 0; i < gradientStops; i++)
			{
				[locations insertObject:[[NSNumber alloc]initWithFloat: @{float[]:Of(offsets).Get(i)}] atIndex:i];
			}
			[gradientLayer setLocations: locations];
			NSMutableArray* cgColors = [[NSMutableArray alloc] initWithCapacity:gradientStops];
			for (int i = 0; i < gradientStops; i++)
			{
				float r = @{float[]:Of(colors).Get((i * 4) + 0)};
				float g = @{float[]:Of(colors).Get((i * 4) + 1)};
				float b = @{float[]:Of(colors).Get((i * 4) + 2)};
				float a = @{float[]:Of(colors).Get((i * 4) + 3)};
				[cgColors insertObject: (id)[[UIColor colorWithRed:r green:g blue:b alpha:a] CGColor] atIndex:i];
			}
			[gradientLayer setColors:cgColors];
			[gradientLayer setStartPoint:CGPointMake(startX, startY)];
			[gradientLayer setEndPoint:CGPointMake(endX, endY)];
			[gradientLayer setFrame:CGRectMake(0.0f, 0.0f, width, height)];
			[gradientLayer setType:kCAGradientLayerAxial];
		@}

		protected abstract ObjC.Object CreatePath();

		[Foreign(Language.ObjC)]
		static void SetBrush(ObjC.Object handle, float r, float g, float b, float a, int layerIndex, ObjC.Object pathHandle, bool isLine, float strokeWidth, float opacity)
		@{
			UIControl* uicontrol = [(ShapeView*)handle shapeView];
			UIBezierPath* path = (UIBezierPath*)pathHandle;
			CAShapeLayer* layer = (CAShapeLayer*)([[uicontrol layer] sublayers][layerIndex]);

			if (isLine)
			{
				[layer setFillColor:nil];
				[layer setStrokeColor:[::UIColor colorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a].CGColor];
				[layer setLineWidth: strokeWidth];
			}
			else
			{
				[layer setFillColor:[::UIColor colorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a].CGColor];
				[layer setStrokeColor:nil];
			}
			[layer setOpacity: opacity];
			[layer setPath: path.CGPath];
		@}

		[Foreign(Language.ObjC)]
		static void MakeLayers(ObjC.Object handle, int layerCount)
		@{
			UIControl* uicontrol = [(ShapeView*)handle shapeView];
			CALayer* layer = [uicontrol layer];
			for (unsigned long i = [[layer sublayers] count]; i--> 0;)
			{
				[[layer sublayers][i] removeFromSuperlayer];
			}

			for (int i = 0; i < layerCount; i++)
			{
				[layer addSublayer: [[CAShapeLayer alloc] init]];
			}
		@}

		[Foreign(Language.ObjC)]
		static ObjC.Object Create()
		@{
			UIControl* uicontrol = [[ShapeView alloc] init];
			[uicontrol setMultipleTouchEnabled:true];
			[uicontrol setOpaque:false];
			return uicontrol;
		@}

	}

}
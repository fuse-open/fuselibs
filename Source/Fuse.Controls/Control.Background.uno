using Uno;
using Uno.UX;
using Fuse.Drawing;
using Fuse.Elements;
using Fuse.Nodes;

namespace Fuse.Controls
{
	public abstract partial class Control : Element
	{
		Brush _background;
		[UXContent]
		/** The brush that will used to paint the background of this control.
			
			To set a solid color as background, consider using the @Color property instead.

			This property is automatically set if you put a brush inside the control, e.g.
			
			<Panel>
				<LinearGradient>
					<GradientStop Offset="0" Color="Black" />
					<GradientStop Offset="0" Color="Black" />
				</LinearGradient>
			</Panel>
		*/
		public Brush Background
		{
			get { return _background; }
			set 
			{
				if (_background != value)
					SetBackground(value);
			}
		}
		void SetBackground(Brush value)
		{
			if (value != null && !(value is ISolidColor))
				Fuse.Diagnostics.Deprecated("Background must be a solid color", this);

			UnrootBackground();
			_background = value;
			RootBackground();
			
			//background on/off will change render bounds
			InvalidateRenderBounds();
			if (IsRootingCompleted)
				OnBackgroundChanged();
		}
		
		bool _backgroundRooted;
		void UnrootBackground()
		{
			if (_background == null)
				return;
				
			if (!_backgroundRooted)
				return;
				
			_backgroundRooted = false;
			_background.Unpin();
			
			var dbg = _background as DynamicBrush;
			if (dbg != null)
				dbg.RemovePropertyListener(this);
		}
		
		void RootBackground()
		{
			if (!IsRootingStarted || _background == null || _backgroundRooted)
				return;

			_backgroundRooted = true;
			_background.Pin();
			
			var dbg = _background as DynamicBrush;
			if (dbg != null)
				dbg.AddPropertyListener(this);
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			RootBackground();
			if (_background != null)
				OnBackgroundChanged();
		}

		protected override void OnUnrooted()
		{
			UnrootBackground();
			base.OnUnrooted();
		}

		public override void OnPropertyChanged(PropertyObject obj, Selector prop)
		{
			if (obj == Background)
			{
				InvalidateVisual();
				if (IsRootingCompleted)
					OnBackgroundChanged();
			}
			base.OnPropertyChanged(obj, prop);
		}

		void OnBackgroundChanged()
		{
			var t = TreeRenderer;
			if (t != null)
				TreeRenderer.BackgroundChanged(this, Background);
		}

		protected void DrawBackground(DrawContext dc, float opacity)
		{
			if (Background != null && !Background.IsCompletelyTransparent)
			{
				extern double t;
				if defined(FUSELIBS_PROFILING)
				{
					Profiling.BeginRegion("Fuse.Controls.Control.DrawBackground");
					t = Uno.Diagnostics.Clock.GetSeconds();
				}

				Background.Prepare(dc, ActualSize);
				Fuse.Internal.Drawing.SolidRectangle.Impl.DrawElement(dc, this, Background, opacity);

				if defined(FUSELIBS_PROFILING)
					Profiling.EndRegion(Uno.Diagnostics.Clock.GetSeconds() - t);
			}
		}
	}

}

namespace Fuse.Internal.Drawing
{
	internal class SolidRectangle
	{
		public static SolidRectangle Impl = new SolidRectangle();

		public void DrawElement(DrawContext dc, Element element, Brush brush, float opacity)
		{
			draw
			{
				apply Fuse.Drawing.Planar.Rectangle;
				DrawContext: dc;
				Visual: element;
				float2 CanvasSize: element.ActualSize; //for the brush
				Size: element.ActualSize;
			},
			virtual brush,
			{ PixelColor: prev*opacity; };

			if defined(FUSELIBS_DEBUG_DRAW_RECTS)
				DrawRectVisualizer.Capture(float2(0), element.ActualSize, element.WorldTransform, dc);
		}
	}
}

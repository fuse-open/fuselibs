using Uno;
using Uno.UX;

using Fuse;
using Fuse.Controls;
using Fuse.Drawing;
using Fuse.Elements;
using Fuse.Resources;

public partial class MyApp
{
}

public class SdfImage : Shape
{
	[UXContent]
	public ImageSource ImageSource { get; set; }
	
	protected override void OnRooted()
	{
		base.OnRooted();
		ImageSource.Pin();
		ImageSource.Changed += OnChanged;
	}
	
	protected override void OnUnrooted()
	{
		ImageSource.Changed -= OnChanged;
		ImageSource.Unpin();
		base.OnUnrooted();
	}
	
	void OnChanged(object s, object a)
	{
		//size is fixed, so no layout
		InvalidateVisual();
	}
	
	protected override void DrawFill(DrawContext dc, Brush fill)
	{
		var scale = Vector.Length(ActualSize / ImageSource.Size);

		draw 
		{
			apply Fuse.Drawing.Planar.Image;
			DrawContext: dc;
			Visual: this;
			Size: ActualSize;
			Texture: ImageSource.GetTexture();
			float RawDistance: (TextureColor.X-0.5f)*64;
			public float EdgeDistance: RawDistance*scale;
			float2 CanvasSize: ActualSize;
			
			apply virtual fill;
			
			public float Sharpness: (1f/Smoothness);
			float Coverage:
				Math.Clamp(0.5f-pixel EdgeDistance*dc.ViewportPixelsPerPoint*Sharpness, 0, 1);
			FinalColor:
				float4(prev.XYZ, prev.W * Coverage);
		};
	}
		
	protected override void DrawStroke(DrawContext dc, Stroke stroke)
	{
		var scale = Vector.Length(ActualSize / ImageSource.Size);

		var r = stroke.GetDeviceAdjusted(dc.ViewportPixelsPerPoint);
			
		draw 
		{
			apply Fuse.Drawing.Planar.Image;
			DrawContext: dc;
			Visual: this;
			Size: ActualSize;
			Texture: ImageSource.GetTexture();
			float RawDistance: (TextureColor.X-0.5f)*64;
			float2 CanvasSize: ActualSize;
			
			apply virtual stroke.Brush;
			
			public float Sharpness: (1f/Smoothness);
			public float EdgeDistance: req(RawDistance as float)
				Math.Abs(RawDistance*scale-r[1]) - r[0]/2;
			float Coverage:
				Math.Clamp(0.5f-pixel EdgeDistance*dc.ViewportPixelsPerPoint*Sharpness, 0, 1);
			FinalColor:
				float4(prev.XYZ, prev.W * Coverage);
		};
	}

	override protected bool NeedSurface { get { return false; } }

	protected override SurfacePath CreateSurfacePath(Fuse.Drawing.Surface surface)
	{
		return null;
	}
}

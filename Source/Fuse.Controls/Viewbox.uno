using Uno;
using Uno.UX;
using Fuse;
using Fuse.Controls;
using Fuse.Elements;

namespace Fuse.Controls 
{
	/** 
		Forces the content (by scaling) to fit inside the available space.

			<Viewbox>
				<Rectangle Color="#808" Width="200" Height="100" />
			</Viewbox>

		This will maintain its aspect ratio of 2:1 while stretching the Rectangle to be the size of the Viewbox.

		You can set which directions you want the content to scale by setting the StretchDirection-property:

		* `Both` - Allow both up- and downscaling
		* `UpOnly` - Only upscale contents
		* `DownOnly` - Only downscale contents
		
		Note that any other setting than `DownOnly` might create pixel artifacts, as the Viewbox performs a bitmap stretch of its contents.

		You can also set the `StretchMode` for the contents, which defaults to `Uniform`.
	*/
	public class Viewbox : ContentControl
	{
		[UXContent]
		new public Element Content
		{
			get { return base.Content as Element; }
			set { base.Content = value; }
		}
		
		Fuse.Internal.SizingContainer sizing = new Fuse.Internal.SizingContainer();
		const float _zeroTolerance = 1e-05f;

		public StretchMode StretchMode
		{
			get { return sizing.stretchMode; }
			set
			{
				if (sizing.SetStretchMode(value))
					OnSizingChanged();
			}
		}

		public StretchDirection StretchDirection
		{
			get { return sizing.stretchDirection; }
			set
			{
				if (sizing.SetStretchDirection(value) )
					OnSizingChanged();
			}
		}
		
		void OnSizingChanged()
		{
			InvalidateLayout();
			InvalidateVisualComposition(); //TODO: why is this here?
		}
		
		float2 _scale = float2(1);
		internal float2 TestScale { get { return _scale; } }
		
		protected float2 GetNaturalContentSize()
		{
			return Content == null ? float2(0) : Content.GetMarginSize(LayoutParams.CreateEmpty());
		}
		
		protected override float2 GetContentSize( LayoutParams lp )
		{
			var natural = GetNaturalContentSize();
			sizing.padding = float4(0);
			var r = sizing.ExpandFillSize( natural, lp );
			return r;
		}
		
		protected override void ArrangePaddingBox( LayoutParams lp )
		{
			sizing.padding = Padding;
			if( Content != null )
			{
				sizing.align = Content.Alignment;
			}

			var contentDesiredSize = GetNaturalContentSize();
			_scale = sizing.CalcScale( lp.Size, contentDesiredSize );

			// Force recalc of implicit transform
			InvalidateLocalTransform();

			var origin = sizing.CalcOrigin( lp.Size, contentDesiredSize * _scale );
			//must divide by scale since the transform is applied to this offset as well
			if ( _scale.X > _zeroTolerance && _scale.Y > _zeroTolerance)
				origin /= _scale;

			if( Content != null )
			{
				var nlp = lp.CloneAndDerive();
				nlp.SetSize(contentDesiredSize);
				Content.ArrangeMarginBox( origin, nlp );
			}
		}
		
		protected override void PrependImplicitTransform( Fuse.FastMatrix m )
		{
			base.PrependImplicitTransform(m);
			//TODO: actually, it should be hidden entirely if scale is so small!
			if (Vector.Length(_scale) > _zeroTolerance)
				m.PrependScale( float3( _scale.X, _scale.Y, 1) );
		}
		
		protected override LayoutDependent IsMarginBoxDependent( Visual child )
		{
			return LayoutDependent.Yes;
		}
	}
}

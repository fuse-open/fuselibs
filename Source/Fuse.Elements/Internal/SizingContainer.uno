using Uno;
using Fuse;
using Fuse.Elements;

namespace Fuse.Internal
{
	internal class SizingContainer
	{
		public StretchMode stretchMode = StretchMode.Uniform;
		public StretchDirection stretchDirection = StretchDirection.Both;
		public Alignment align = Alignment.Center;
		public StretchSizing stretchSizing = StretchSizing.Natural;

		public bool SetStretchMode( StretchMode mode )
		{
			if (mode == stretchMode)
				return false;
			stretchMode = mode;
			return true;
		}

		public bool SetStretchDirection( StretchDirection dir )
		{
			if (dir == stretchDirection)
				return false;
			stretchDirection = dir;
			return true;
		}

		public bool SetAlignment( Alignment a )
		{
			if (a == align)
				return false;
			align = a;
			return true;
		}

		public bool SetStretchSizing( StretchSizing ss )
		{
			if (ss == stretchSizing)
				return false;
			stretchSizing = ss;
			return true;
		}

		//set prior to calling CalcSize
		public float4 padding;
		public float absoluteZoom = 1;
		public bool snapToPixels;

		float PaddingWidth { get { return padding[0] + padding[2]; } }
		float PaddingHeight { get { return padding[1] + padding[3]; } }

		public float2 CalcScale( float2 availableSize, float2 desiredSize )
		{
			return CalcScale( availableSize, desiredSize, false, false );
		}

		public float2 CalcContentSize( float2 size, int2 pixelSize )
		{
			switch (stretchMode)
			{
				case StretchMode.PixelPrecise:
				{
					if (pixelSize.X == 0 || pixelSize.Y == 0)
						return float2(0);
					return float2(pixelSize.X,pixelSize.Y) / absoluteZoom;
				}

				case StretchMode.PointPrefer:
				{
					if (pixelSize.X == 0 || pixelSize.Y == 0)
						return float2(0);

					var exact = float2(pixelSize.X,pixelSize.Y) / absoluteZoom;
					var scale = size / exact;
					if (scale.X  > 0.75 && scale.X < 1.5)
						return exact;

					/* em: I don't see value in this unless you turned off interpolation on drawing as well
					//try an integer multiple
					var iScale = (int)(Math.Floor(scale.X + 0.5f));
					var near = float2(pixelSize.X,pixelSize.Y) * iScale / absoluteZoom;
					scale = size/exact - iScale;
					if ( scale.X  > -0.25f && scale.X < 0.5f)
						return near;
					*/
					break;
				}

				default:
					break;
			}

			if (!snapToPixels)
				return size;
			return SnapSize(size);
		}

		float2 SnapSize( float2 sz )
		{
			return Math.Floor(sz * absoluteZoom + 0.5f) / absoluteZoom;
		}

		float2 CalcScale( float2 availableSize, float2 desiredSize,
			bool autoWidth, bool autoHeight )
		{
			var d = availableSize;
			d.X -= PaddingWidth;
			d.Y -= PaddingHeight;

			var scale = float2(1);
			const float zeroTolerance = 1e-05f;

			if (autoWidth && autoHeight && !(stretchMode == StretchMode.PointPrecise ||
				stretchMode == StretchMode.PixelPrecise ||
				stretchMode == StretchMode.PointPrefer) )
			{
				if (stretchSizing == StretchSizing.Zero)
					scale = float2(0);
				else
					scale = float2(1);
			}
			else
			{
				//in the < zeroTolerance case the result is actually infinity, but that would produce odd results
				//we use 0 instead, which will result in nothing drawn in most cases. Some cases below however
				//can deal with infinity and have their own logic.
				var zeroX = desiredSize.X < zeroTolerance;
				var zeroY = desiredSize.Y < zeroTolerance;
				float2 s = float2(
					zeroX ? 0f : d.X / desiredSize.X,
					zeroY ? 0f : d.Y / desiredSize.Y
					);
				switch( stretchMode )
				{
					case StretchMode.PointPrecise:
					case StretchMode.PixelPrecise:
					case StretchMode.PointPrefer:
						scale = float2(1);
						break;

					case StretchMode.Scale9:
					case StretchMode.Fill:
					{
						scale = autoWidth ? float2(s.Y) :
							autoHeight ? float2(s.X) :
							s;
						break;
					}

					case StretchMode.Uniform:
					{
						var sm = autoWidth ? s.Y :
							autoHeight ? s.X :
							//as `Min` is used below, and zeroX/Y imply infinite scale, we can special case here to get correct values
							zeroX ? s.Y :
							zeroY ? s.X :
							Math.Min( s.X, s.Y );
						scale = float2(sm);
						break;
					}

					case StretchMode.UniformToFill:
					{
						var sm = autoWidth ? s.Y :
							autoHeight ? s.X :
							Math.Max( s.X, s.Y );
						scale = float2(sm);
						break;
					}
				}
			}

			//limit direction of stretching
			//TODO: if the stretching mode is uniform then both should be limited the same
			switch( stretchDirection )
			{
				case StretchDirection.Both:
					break;

				case StretchDirection.DownOnly:
					scale.X = Math.Min( scale.X, 1 );
					scale.Y = Math.Min( scale.Y, 1 );
					break;

				case StretchDirection.UpOnly:
					scale.X = Math.Max( 1, scale.X );
					scale.Y = Math.Max( 1, scale.Y );
					break;
			}

			if (snapToPixels && desiredSize.X > zeroTolerance && desiredSize.Y > zeroTolerance)
				scale = SnapSize( scale * desiredSize ) / desiredSize;
			return scale;
		}

		public float2 CalcOrigin( float2 availableSize, float2 contentActualSize )
		{
			var origin = float2(0);
			switch ( AlignmentHelpers.GetHorizontalAlign(align) )
			{
				case Alignment.Default: //may be set for clarity if used with Fill modes
				case Alignment.Left:
					origin.X = padding[0];
					break;

				case Alignment.HorizontalCenter:
					origin.X = (availableSize.X - padding[0] - padding[2]) / 2
						- contentActualSize.X/2 + padding[0];
					break;

				case Alignment.Right:
					origin.X = availableSize.X - padding[2] - contentActualSize.X;
					break;
			}

			switch( AlignmentHelpers.GetVerticalAlign(align) )
			{
				case Alignment.Default:
				case Alignment.Top:
					origin.Y = padding[1];
					break;

				case Alignment.VerticalCenter:
					origin.Y = (availableSize.Y - padding[1] - padding[3]) / 2
						- contentActualSize.Y/2 + padding[1];
					break;

				case Alignment.Bottom:
					origin.Y = availableSize.Y - padding[3] - contentActualSize.Y;
					break;
			}

			if (snapToPixels)
				origin = SnapSize(origin);
			return origin;
		}

		public float4 CalcClip( float2 availableSize, ref float2 origin, ref float2 contentActualSize )
		{
			//cases where everything is outside clip region
			if (origin.X > availableSize.X ||
				origin.X + contentActualSize.X < 0 ||
				origin.Y > availableSize.Y ||
				origin.Y + contentActualSize.Y < 0)
			{
				origin = float2(0,0);
				contentActualSize = float2(0);
				return float4(0,0,1,1);
			}

			float2 tl = Math.Max( float2(0), (padding.XY-origin) / contentActualSize );
			float2 br = Math.Min( float2(1), (availableSize - origin - padding.ZW) / contentActualSize );

			var dx = padding.X - origin.X;
			if (dx > 0)
			{
				contentActualSize.X -= dx;
				origin.X = padding.X;
			}

			dx = origin.X + contentActualSize.X - availableSize.X + padding.Z;
			if (dx > 0)
			{
				contentActualSize.X -= dx;
			}

			var dy = padding.Y - origin.Y;
			if (dy > 0)
			{
				contentActualSize.Y -= dy;
				origin.Y = padding.Y;
			}

			dy = origin.Y + contentActualSize.Y - availableSize.Y + padding.W;
			if (dy > 0)
			{
				contentActualSize.Y -= dy;
			}

			return float4( tl.X, tl.Y, br.X, br.Y );
		}

		public float2 ExpandFillSize( float2 size, LayoutParams lp )
		{
			bool autoWidth = !lp.HasX;
			bool autoHeight = !lp.HasY;
			var scale = CalcScale( lp.Size, size, autoWidth, autoHeight );
			var res = scale * size;

			//the order here matches the applicatin order in BoxSizing (explicit -> Max -> Min)
			bool recalc = false;
			if (lp.HasMaxX && res.X > lp.MaxX)
			{
				res.X = lp.MaxX;
				recalc = true;
				autoWidth = false;
			}
			if (lp.HasMaxY && res.Y > lp.MaxY)
			{
				res.Y = lp.MaxY;
				recalc = true;
				autoHeight = false;
			}
			if (lp.HasMinX && res.X < lp.MinX)
			{
				res.X = lp.MinX;
				recalc = true;
				autoWidth = false;
			}
			if (lp.HasMinY && res.Y < lp.MinY)
			{
				res.Y = lp.MinY;
				recalc = true;
				autoHeight = false;
			}
			if (recalc)
			{
				scale = CalcScale( res, size, autoWidth, autoHeight);
				res = scale * size;
			}

			return res;
		}
	}

}

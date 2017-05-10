using Uno;

namespace Fuse.Controls.Graphics
{
	public abstract class Visual: Fuse.Visual
	{
		protected float2 ActualSize { get; protected set; }

		float2 _position;

		protected override float2 OnArrangeMarginBox(float2 position, LayoutParams lp)
		{
			//if size is available we stretch to fill the available size
			var sz = lp.Size;
			if (!lp.HasSize)
			{
				var rsz = GetMarginSize(lp);
				if (!lp.HasX)
					sz.X = rsz.X;
				if (!lp.HasY)
					sz.Y = rsz.Y;
			}

			_position = position;
			ActualSize = sz;
			InvalidateLocalTransform();	
			return ActualSize;
		}

		protected override void PrependImplicitTransform(FastMatrix m)
		{
			m.PrependTranslation(float3(_position, 0));
		}

		public bool IsPointInside(float2 localPoint)
		{
			return !(localPoint.X < 0 || localPoint.Y < 0 || localPoint.X > ActualSize.X || localPoint.Y > ActualSize.Y);
		}

		public override VisualBounds LocalRenderBounds
		{
			get { return VisualBounds.Rect(float2(0),ActualSize); }
		}
	}
}

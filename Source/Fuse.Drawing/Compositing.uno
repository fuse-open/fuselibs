using Uno;
using Uno.Graphics;

namespace Fuse.Drawing
{
	block AlphaCompositing
	{
		BlendEnabled: true;
		BlendSrcRgb: BlendOperand.SrcAlpha;
		BlendDstRgb: BlendOperand.OneMinusSrcAlpha;

		BlendSrcAlpha: BlendOperand.One;
		BlendDstAlpha: BlendOperand.OneMinusSrcAlpha;
	}

	block PreMultipliedAlphaCompositing
	{
		BlendEnabled: true;
		BlendSrcRgb: BlendOperand.One;
		BlendDstRgb: BlendOperand.OneMinusSrcAlpha;

		BlendSrcAlpha: BlendOperand.OneMinusDstAlpha;
		BlendDstAlpha: BlendOperand.One;
	}
}
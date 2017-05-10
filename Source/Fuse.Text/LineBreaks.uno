using Fuse.Text.Implementation;

namespace Fuse.Text
{
	static class LineBreaks
	{
		public static BitArray Get(Substring text)
		{
			if defined(USE_ICU)
				return UBrk.GetSoftLineBreaks(text);
			else if defined(Android)
				return JavaLineBreaks.GetSoftLineBreaks(text);
			else build_error;
		}
	}
}

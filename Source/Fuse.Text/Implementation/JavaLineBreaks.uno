using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Text.Implementation
{
	[ForeignInclude(Language.Java, "java.nio.ByteBuffer")]
	[ForeignInclude(Language.Java, "java.text.BreakIterator")]
	static extern(Android) class JavaLineBreaks
	{
		public static BitArray GetSoftLineBreaks(Substring text)
		{
			var result = new BitArray(text.Length + 1);
			CopyLineBreaks(text.ToString(), DirectBufferFromUnoByteBuffer(result.Data));
			return result;
		}

		[Foreign(Language.Java)]
		static void CopyLineBreaks(string text, Java.Object outByteBufferHandle)
		@{
			ByteBuffer outByteBuffer = (ByteBuffer)outByteBufferHandle;
			BreakIterator bi = BreakIterator.getLineInstance();
			bi.setText(text);

			final int bytesize = 8;

			int boundary = bi.first();
			while (boundary != BreakIterator.DONE)
			{
				int i = boundary / bytesize;
				byte mask = (byte)(1 << (boundary % bytesize));
				outByteBuffer.put(i, (byte)(outByteBuffer.get(i) | mask));
				boundary = bi.next();
			}
		@}

		static Java.Object DirectBufferFromUnoByteBuffer(byte[] byteArray)
		{
			return Android.Base.Wrappers.JWrapper.Wrap(Android.Base.Types.ByteBuffer.NewDirectByteBuffer(byteArray));
		}
	}
}

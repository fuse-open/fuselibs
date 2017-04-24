using Uno;
using Fuse.Scripting;
using Uno.Text;

namespace FuseJS
{
	internal static class Latin1Helpers
	{
		public static string DecodeLatin1(string base64Str)
		{
			var bytes = Uno.Text.Base64.GetBytes(base64Str);
			var len = bytes.Length;
			var chars = new char[len];
			for (int i = 0; i < len; i++)
			{
				chars[i] = (char)bytes[i];
			}
			return new String(chars);
		}


		public static string EncodeLatin1(string str)
		{
			// Length of string will be the same as length of byte array
			var bytes = new byte[str.Length];
			var len = str.Length;
			for (int i = 0; i < len; i++)
			{
				var c = (int)str[i];
				// Unicode points 0x00-0xff is the Latin-1 range, when outside of this range
				// an exception must be thrown.
				if (c > 0xff)
				{
					throw new Error("The string to be encoded contains characters outside of the Latin1 range.");
				}

				bytes[i] = (byte)c;
			}

			return Uno.Text.Base64.GetString(bytes);
		}
	}
}

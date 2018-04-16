using Uno.Text;
using Uno.Net.Http;

namespace Fuse
{
	internal static class PhoneUriHelper
	{
		public static string PhoneNumberToUri(string phoneNumber)
		{
			var builder = new StringBuilder();
			builder.Append("tel:");
			builder.Append(Uri.EscapeDataString(phoneNumber));
			return builder.ToString();
		}
	}
}

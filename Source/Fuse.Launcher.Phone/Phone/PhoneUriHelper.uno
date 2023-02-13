using Uno.Text;
using Uno.Net.Http;

namespace Fuse
{
	internal static class PhoneUriHelper
	{
		public static string PhoneNumberToTelUri(string phoneNumber)
		{
			var builder = new StringBuilder();
			builder.Append("tel:");
			builder.Append(Uri.EscapeDataString(phoneNumber));
			return builder.ToString();
		}

		public static string PhoneNumberToSmsUri(string phoneNumber, string body)
		{
			var builder = new StringBuilder();
			builder.Append("sms:");
			builder.Append(Uri.EscapeDataString(phoneNumber));

			if (!string.IsNullOrEmpty(body))
			{
				builder.Append("?body=");
				builder.Append(Uri.EscapeDataString(body));
			}

			return builder.ToString();
		}
	}
}

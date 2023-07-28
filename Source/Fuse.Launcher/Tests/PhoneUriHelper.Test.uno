using Uno;
using Uno.Testing;
using Fuse;
using FuseTest;

namespace Fuse.LauncherTest
{
	public class PhoneUriHelperTest : TestBase
	{
		[Test]
		public void PhoneNumberToTelUri_encodes_whitespace_correctly()
		{
			var phoneUri = PhoneUriHelper.PhoneNumberToTelUri("123 33 321");
			Assert.AreEqual("tel:123%2033%20321", phoneUri);
		}

		[Test]
		public void PhoneNumberToSmsUri_encodes_whitespace_correctly()
		{
			var phoneUri = PhoneUriHelper.PhoneNumberToSmsUri("123 33 321", "hi");
			Assert.AreEqual("sms:123%2033%20321?body=hi", phoneUri);
		}
	}
}

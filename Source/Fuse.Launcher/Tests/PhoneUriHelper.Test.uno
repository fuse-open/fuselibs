using Uno;
using Uno.Testing;
using Fuse;
using FuseTest;

namespace Fuse.LauncherTest
{
	public class PhoneUriHelperTest : TestBase
	{
		[Test]
		public void PhoneNumberToUri_encodes_whitespace_correctly()
		{
			var phoneUri = PhoneUriHelper.PhoneNumberToUri("123 33 321");
			Assert.AreEqual("tel:123%2033%20321", phoneUri);
		}
	}
}

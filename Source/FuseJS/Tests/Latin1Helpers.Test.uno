using Uno;
using Uno.Testing;
using Fuse.Scripting;

namespace FuseJS.Test
{
	public class Latin1HelpersTest
	{
		[Test]
		public void DecodeLatin1_given_valid_base64_encoded_arg_decodes_string()
		{
			Assert.AreEqual("js gravy", Latin1Helpers.DecodeLatin1("anMgZ3Jhdnk="));
			Assert.AreEqual("æøå", Latin1Helpers.DecodeLatin1("5vjl"));
		}


		[Test]
		public void EncodeLatin1_given_valid_Latin1_string_encodes_to_base64()
		{
			Assert.AreEqual("anMgZ3Jhdnk=", Latin1Helpers.EncodeLatin1("js gravy"));
			Assert.AreEqual("5vjl", Latin1Helpers.EncodeLatin1("æøå"));
		}


		[Test]
		public void EncodeLatin1_given_string_with_invalid_Latin1_characters_throws_exception()
		{
			var ex = Assert.Throws<Error>(EncodeInvalidLatin1String);
			Assert.AreEqual("The string to be encoded contains characters outside of the Latin1 range.", ex.Message);
		}


		private static void EncodeInvalidLatin1String()
		{
			Latin1Helpers.EncodeLatin1("(｡◕‿‿◕｡)");
		}
	}
}

using Uno;
using Uno.UX;
using Fuse.Scripting;
using Uno.Text;
using Uno.Collections;

namespace FuseJS
{
    /**
        @scriptmodule FuseJS/Base64
		
		Allows you to encode and decode strings from Base64.
		
		This is useful when passing string to places where some characters are not allowed.
		
		This example demonstrates simple use of the `Base64` module. The code prints the input string, and the computed Base64 string.
		
			var Base64 = require("FuseJS/Base64");
			var string = "Hello, world!";
			console.log(string); //LOG: Hello, world!
			console.log(Base64.encodeAscii(string)); //LOG: SGVsbG8sIHdvcmxkIQ==
		
    */
	[UXGlobalModule]
	public sealed class Base64 : NativeModule
	{
		static readonly Base64 _instance;

		public Base64()
		{
			if(_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "FuseJS/Base64");
			AddMember(new NativeFunction("encodeAscii", (NativeCallback)EncodeAscii));
			AddMember(new NativeFunction("decodeAscii", (NativeCallback)DecodeAscii));
			AddMember(new NativeFunction("encodeUtf8", (NativeCallback)EncodeUtf8));
			AddMember(new NativeFunction("decodeUtf8", (NativeCallback)DecodeUtf8));
			AddMember(new NativeFunction("encodeLatin1", (NativeCallback)EncodeLatin1));
			AddMember(new NativeFunction("decodeLatin1", (NativeCallback)DecodeLatin1));
			AddMember(new NativeFunction("encodeBuffer", (NativeCallback)EncodeBuffer));
			AddMember(new NativeFunction("decodeBuffer", (NativeCallback)DecodeBuffer));
		}


		/** @scriptmethod decodeBuffer(base64String)
			Decodes the given base64 string to an ArrayBuffer.

				var Base64 = require("FuseJS/Base64");
				var buf = Base64.decodeBuffer("NxMAAA==");
				var view = new Int32Array(data);
				// Should print 0x1337
				console.log("0x" + view[0].toString(16));

			@param base64String (String) base64 encoded string
			@return (ArrayBuffer) Decoded ArrayBuffer
		**/

		object DecodeBuffer(Context context, object[] args)
		{
			var base64Str = ((IEnumerable<object>)args).FirstOrDefault() as string;
			if (base64Str == null)
				throw new Error("Requires a base-64 encoded string as first argument");

			return Uno.Text.Base64.GetBytes(base64Str);
		}

		/** @scriptmethod encodeBuffer(arrayBuffer)
			Encodes given array buffer to base64.

				var Base64 = require("FuseJS/Base64");

				var data = new ArrayBuffer(4);
				var view = new Int32Array(data);
				view[0] = 0x1337;

				console.log(Base64.encodeBuffer(data));

			@param arrayBuffer (ArrayBuffer) The ArrayBuffer to encode
			@return (String) A base64 encoded string
		**/
		object EncodeBuffer(Context context, object[] args)
		{
			var buffer = ((IEnumerable<object>)args).FirstOrDefault() as byte[];
			if (buffer == null)
				throw new Error("Requires an ArrayBuffer as the first argument.");

			return Uno.Text.Base64.GetString(buffer);
		}

		/** @scriptmethod decodeLatin1(stringToDecode)
		    Decodes the given base64 Latin-1 encoded bytes to a string.

				var Base64 = require("FuseJS/Base64");
				// Prints "hello world"
				console.log(Base64.decodeLatin1("aGVsbG8gd29ybGQ="));

			@param stringToDecode (String) Base64 encoded string
			@return (String) Decoded string
		**/
		object DecodeLatin1(Context context, object[] args)
		{
			var base64Str = ((IEnumerable<object>)args).FirstOrDefault() as string;
			if (base64Str == null)
				throw new Error("Requires a base-64 encoded Latin-1 string as argument");

			return Latin1Helpers.DecodeLatin1(base64Str);
		}

		/** @scriptmethod encodeLatin1(stringToEncode)
		    Encodes the given string to a Latin-1 base64 string.

				var Base64 = require("FuseJS/Base64");
				// Prints "aGVsbG8gd29ybGQ="
				console.log(Base64.encodeLatin1("hello world"));

			@param stringToEncode (String) String to encode
			@return (String) Encoded string
		**/
		object EncodeLatin1(Context context, object[] args)
		{
			if (args.Length < 1)
				throw new Error("Requires 1 argument");

			// btoa (on Chrome at least) accepts non-string arguments, which get converted.
			// Lets keep the same behavior.
			var str = args[0] == null ? "null" : args[0].ToString();

			return Latin1Helpers.EncodeLatin1(str);
		}

		/** @scriptmethod encodeAscii(value)

			Encodes the given ASCII value to base64 string representation
			
				var Base64 = require("FuseJS/Base64");
				console.log(Base64.encodeAscii("Hello, world!")); //LOG: SGVsbG8sIHdvcmxkIQ==

			@param value (String) Ascii
			@return (String) Base64
		*/
		object EncodeAscii(Fuse.Scripting.Context context, object[] args)
		{
			if(args.Length > 0)
			{
				var str = args[0] as string;
				if(str != null)
					return Uno.Text.Base64.GetString(Ascii.GetBytes(str));
			}
			return null;
		}

		/** @scriptmethod decodeAscii(value)

			Decodes the given base64 value to an ASCII string representation

				var Base64 = require("FuseJS/Base64");
				console.log(Base64.decodeAscii("SGVsbG8sIHdvcmxkIQ==")); //LOG: Hello, world!

			@param value (String) Base64
			@return (String) Ascii
		*/
		object DecodeAscii(Fuse.Scripting.Context context, object[] args)
		{
			if(args.Length > 0)
			{
				var str = args[0] as string;
				if(str != null)
					return Ascii.GetString(Uno.Text.Base64.GetBytes(str));
			}
			return null;
		}

		/** @scriptmethod encodeUtf8(value)

			Encodes the given UTF8 value to a base64 string representation

				var Base64 = require("FuseJS/Base64");
				console.log(Base64.encodeUtf8("Foo © bar")); //LOG: Rm9vIMKpIGJhcg==

			@param value (String) Utf8
			@return (String) Base64
		*/
		object EncodeUtf8(Fuse.Scripting.Context context, object[] args)
		{
			if(args.Length > 0)
			{
				var str = args[0] as string;
				if(str != null)
					return Uno.Text.Base64.GetString(Utf8.GetBytes(str));
			}
			return null;
		}

		/** @scriptmethod decodeUtf8(value)
			
			Decodes the given base64 value to an UTF8 string representation

				var Base64 = require("FuseJS/Base64");
				console.log(Base64.encodeUtf8("Rm9vIMKpIGJhcg==")); //LOG: Foo © bar

			@param value (String) Base64
			@return (String) Utf8
		*/
		object DecodeUtf8(Fuse.Scripting.Context context, object[] args)
		{
			if(args.Length > 0)
			{
				var str = args[0] as string;
				if(str != null)
					return Utf8.GetString(Uno.Text.Base64.GetBytes(str));
			}
			return null;
		}
	}
}
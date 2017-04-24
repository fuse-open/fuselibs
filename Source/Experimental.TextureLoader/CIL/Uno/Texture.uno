using Uno.Compiler.ExportTargetInterop;

namespace Uno.Native.Textures
{
	[DotNetType("Uno.Native.Textures.TextureFileFormat")]
	extern(DOTNET) public enum TextureFileFormat
	{
		Unknown,
		Png,
		Jpeg,
		Ktx,
	}

	[DotNetType("Uno.Native.Textures.TextureType")]
	extern(DOTNET) public enum TextureType
	{
		Texture2D,
		Texture3D,
		TextureCube,
	}

	[DotNetType("Uno.Native.Textures.PixelFormat")]
	extern(DOTNET) public enum PixelFormat
	{
		Unspecified = 0,

		R_8_Int = 1,
		RG_8_8_Int = 2,
		RGB_8_8_8_Int = 3,
		RGBA_8_8_8_8_Int = 4,

		R_8_UInt = 5,
		RG_8_8_UInt = 6,
		RGB_8_8_8_UInt = 7,
		RGBA_8_8_8_8_UInt = 8,

		R_8_Int_Normalize = 9,
		RG_8_8_Int_Normalize = 10,
		RGB_8_8_8_Int_Normalize = 11,
		RGBA_8_8_8_8_Int_Normalize = 12,

		R_8_UInt_Normalize = 13,
		RG_8_8_UInt_Normalize = 14,
		RGB_8_8_8_UInt_Normalize = 15,
		RGBA_8_8_8_8_UInt_Normalize = 16,

		R_8_Typeless = 17,
		RG_8_8_Typeless = 18,
		RGB_8_8_8_Typeless = 19,
		RGBA_8_8_8_8_Typeless = 20,

		A_8_UInt_Normalize = 21,
		L_8_UInt_Normalize = 22,
		LA_8_8_UInt_Normalize = 23,

		R_16_Int = 24,
		RG_16_16_Int = 25,
		RGB_16_16_16_Int = 26,
		RGBA_16_16_16_16_Int = 27,

		R_16_Int_Normalize = 28,
		RG_16_16_Int_Normalize = 29,
		RGB_16_16_16_Int_Normalize = 30,
		RGBA_16_16_16_16_Int_Normalize = 31,

		R_16_UInt = 32,
		RG_16_16_UInt = 33,
		RGB_16_16_16_UInt = 34,
		RGBA_16_16_16_16_UInt = 35,

		R_16_UInt_Normalize = 36,
		RG_16_16_UInt_Normalize = 37,
		RGB_16_16_16_UInt_Normalize = 38,
		RGBA_16_16_16_16_UInt_Normalize = 39,

		R_16_Float = 40,
		RG_16_16_Float = 41,
		RGB_16_16_16_Float = 42,
		RGBA_16_16_16_16_Float = 43,

		R_16_Typeless = 44,
		RG_16_16_Typeless = 45,
		RGB_16_16_16_Typeless = 46,
		RGBA_16_16_16_16_Typeless = 47,

		R_32_Int = 48,
		RG_32_32_Int = 49,
		RGB_32_32_32_Int = 50,
		RGBA_32_32_32_32_Int = 51,

		R_32_UInt = 52,
		RG_32_32_UInt = 53,
		RGB_32_32_32_UInt = 54,
		RGBA_32_32_32_32_UInt = 55,

		R_32_Float = 56,
		RG_32_32_Float = 57,
		RGB_32_32_32_Float = 58,
		RGBA_32_32_32_32_Float = 59,

		R_32_Typeless = 60,
		RG_32_32_Typeless = 61,
		RGB_32_32_32_Typeless = 62,
		RGBA_32_32_32_32_Typeless = 63,

		// Compressed formats
		CompressedRGB_BC1 = 200,
		CompressedRGB_BC2 = 201,
		CompressedRGB_BC3 = 202,
		CompressedRGB_BC4 = 203,
		CompressedRGB_BC5 = 204,
		CompressedRGB_ETC1 = 205,
		CompressedRGB_PVRTC_4BPP = 206,
		CompressedRGB_PVRTC_2BPP = 207,
		CompressedRGBA_PVRTC_4BPP = 208,
		CompressedRGBA_PVRTC_2BPP = 209,

		// Depth/Stencil formats
		D_32_Float = 500,
		DSX_32_8_24_Float_UInt_Typeless = 501,
		DS_24_8_UInt_Normalize_UInt = 502,

		D_16_UNorm = 503,
		R_16_UNorm = 504
	}

	[DotNetType("Uno.Native.Textures.Texture")]
	extern(DOTNET) public class Texture : Uno.IDisposable
	{
		public extern int Width { get; }
		public extern int Height { get; }
		public extern int Depth { get; }
		public extern int FaceCount { get; }
		public extern int MipCount { get; }

		public extern TextureFileFormat FileFormat { get; }
		public extern TextureType TextureType { get; }
		public extern PixelFormat PixelFormat { get; }

		public extern string Filename { get; }

		public extern Texture(string filename);
		public extern Texture(string filename, byte[] bytes);
		public extern Texture(string filename, Uno.IO.Stream stream);

		public extern void Convert2DToCube();
		// public extern void ConvertCubeTo2D(TextureCube2DMode mode);
		public extern byte[] ReadData(int faceIndex = 0, int mipIndex = 0);
		public extern void SaveAsPng(string dstFilename, int faceIndex = 0, int mipIndex = 0);
		public extern void Compress(string dstFilename, PixelFormat format, bool generateMipMaps = true);
		public extern void Dispose();
	}
}

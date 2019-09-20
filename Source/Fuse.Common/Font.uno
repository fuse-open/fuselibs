using Uno;
using Uno.IO;
using Uno.UX;
using Uno.Collections;
using Fuse.Internal;
using Fuse.Resources;

namespace Fuse
{
	/** Represents a specific typeface. 

		Global resource fonts can be specified directly on @Text and @TextInput objects:

			<Text Font="PlatformDefault" />

		Or inline based on an `.otf` or `.ttf` file:

			<Text Value="Hello!">
				<Font File="arial.ttf" />
			</Text>

		To create a global resource font from a file, use the `ux:Global` attribute:

			<Font File="arial.ttf" ux:Global="MyDefaultFont" />
			<Text Font="MyDefaultFont" />
	*/
	public class Font
	{
		internal readonly List<FontFaceDescriptor> Descriptors;
		[UXContent]
		internal FileSource FileSource
		{
			get
			{
				return Descriptors[0].FileSource;
			}
		}

		[UXConstructor]
		public Font([UXParameter("File")] FileSource file)
			: this(Internal.SystemFont.GetFallback(file))
		{
		}

		internal Font(List<FontFaceDescriptor> descriptors)
		{
			if (descriptors == null)
				throw new ArgumentNullException(nameof(descriptors));

			if (descriptors.Count < 1)
				throw new Exception("font contains no descriptors!");

			Descriptors = descriptors;
		}

		static Font _fallback;

		[UXGlobalResource]
		/** The default font for regular text in the current platform. */
		public static Font PlatformDefault
		{
			get
			{
				if (_fallback == null)
					_fallback = new Font(Internal.SystemFont.Default);
				return _fallback;
			}
		}

		/** The default font size for regular text in the current platform. */
		public static float PlatformDefaultSize
		{
			get
			{
				// TODO: implement platform-specific retrieval of default size
				return 16;
			}
		}

		/** The default text color for regular text in the current platform. */
		public static float4 PlatformDefaultTextColor
		{
			get
			{
				// TODO: implement platform-specific retrieval of default color

				return float4(82.0f/255.0f,82.0f/255.0f,82.0f/255.0f,1.0f);
			}
		}

		[UXGlobalResource]
		extern (Android) public static readonly Font UltraLight = new SystemFont("sans-serif-thin", SystemFont.Style.Normal, SystemFont.Weight.Thin);

		[UXGlobalResource]
		extern (Android) public static readonly Font Thin = new SystemFont("sans-serif-thin", SystemFont.Style.Normal, SystemFont.Weight.Thin);

		[UXGlobalResource]
		extern (Android) public static readonly Font Light = new SystemFont("sans-serif-light", SystemFont.Style.Normal, SystemFont.Weight.Light);

		[UXGlobalResource]
		extern (Android) public static readonly Font Regular = new SystemFont("sans-serif");

		[UXGlobalResource]
		extern (Android) public static readonly Font Medium = new SystemFont("sans-serif", SystemFont.Style.Normal, SystemFont.Weight.Medium);

		[UXGlobalResource]
		extern (Android) public static readonly Font Semibold = new SystemFont("sans-serif", SystemFont.Style.Normal, SystemFont.Weight.Bold);

		[UXGlobalResource]
		extern (Android) public static readonly Font Bold = new SystemFont("sans-serif", SystemFont.Style.Normal, SystemFont.Weight.Bold);

		[UXGlobalResource]
		extern (Android) public static readonly Font Heavy = new SystemFont("sans-serif", SystemFont.Style.Normal, SystemFont.Weight.Bold);

		[UXGlobalResource]
		extern (Android) public static readonly Font Black = new SystemFont("sans-serif", SystemFont.Style.Normal, SystemFont.Weight.Bold);

		[UXGlobalResource]
		extern (Android) public static readonly Font UltraLightItalic = new SystemFont("sans-serif-thin", SystemFont.Style.Italic, SystemFont.Weight.Thin);

		[UXGlobalResource]
		extern (Android) public static readonly Font ThinItalic = new SystemFont("sans-serif-thin", SystemFont.Style.Italic, SystemFont.Weight.Thin);

		[UXGlobalResource]
		extern (Android) public static readonly Font LightItalic = new SystemFont("sans-serif-light", SystemFont.Style.Italic, SystemFont.Weight.Light);

		[UXGlobalResource]
		extern (Android) public static readonly Font Italic = new SystemFont("sans-serif", SystemFont.Style.Italic);

		[UXGlobalResource]
		extern (Android) public static readonly Font MediumItalic = new SystemFont("sans-serif", SystemFont.Style.Italic, SystemFont.Weight.Medium);

		[UXGlobalResource]
		extern (Android) public static readonly Font SemiboldItalic = new SystemFont("sans-serif", SystemFont.Style.Italic, SystemFont.Weight.Bold);

		[UXGlobalResource]
		extern (Android) public static readonly Font BoldItalic = new SystemFont("sans-serif", SystemFont.Style.Italic, SystemFont.Weight.Bold);

		[UXGlobalResource]
		extern (Android) public static readonly Font HeavyItalic = new SystemFont("sans-serif", SystemFont.Style.Italic, SystemFont.Weight.Bold);

		[UXGlobalResource]
		extern (Android) public static readonly Font BlackItalic = new SystemFont("sans-serif", SystemFont.Style.Italic, SystemFont.Weight.Bold);



		[UXGlobalResource]
		extern (iOS) public static readonly Font UltraLight = new SystemFont(Internal.iOSSystemFont.DefaultFontName, SystemFont.Style.Normal, SystemFont.Weight.UltraLight);

		[UXGlobalResource]
		extern (iOS) public static readonly Font Thin = new SystemFont(Internal.iOSSystemFont.DefaultFontName, SystemFont.Style.Normal, SystemFont.Weight.Thin);

		[UXGlobalResource]
		extern (iOS) public static readonly Font Light = new SystemFont(Internal.iOSSystemFont.DefaultFontName, SystemFont.Style.Normal, SystemFont.Weight.Light);

		[UXGlobalResource]
		extern (iOS) public static readonly Font Regular = new SystemFont(Internal.iOSSystemFont.DefaultFontName);

		[UXGlobalResource]
		extern (iOS) public static readonly Font Normal = new SystemFont(Internal.iOSSystemFont.DefaultFontName);

		[UXGlobalResource]
		extern (iOS) public static readonly Font Medium = new SystemFont(Internal.iOSSystemFont.DefaultFontName, SystemFont.Style.Normal, SystemFont.Weight.Medium);

		[UXGlobalResource]
		extern (iOS) public static readonly Font Semibold = new SystemFont(Internal.iOSSystemFont.DefaultFontName, SystemFont.Style.Normal, SystemFont.Weight.Semibold);

		[UXGlobalResource]
		extern (iOS) public static readonly Font Bold = new SystemFont(Internal.iOSSystemFont.DefaultFontName, SystemFont.Style.Normal, SystemFont.Weight.Bold);
		
		[UXGlobalResource]
		extern (iOS) public static readonly Font Heavy = new SystemFont(Internal.iOSSystemFont.DefaultFontName, SystemFont.Style.Normal, SystemFont.Weight.Heavy);
		
		[UXGlobalResource]
		extern (iOS) public static readonly Font Black = new SystemFont(Internal.iOSSystemFont.DefaultFontName, SystemFont.Style.Normal, SystemFont.Weight.Black);
		
		[UXGlobalResource]
		extern (iOS) public static readonly Font UltraLightItalic = new SystemFont(Internal.iOSSystemFont.DefaultFontName, SystemFont.Style.Italic, SystemFont.Weight.UltraLight);

		[UXGlobalResource]
		extern (iOS) public static readonly Font ThinItalic = new SystemFont(Internal.iOSSystemFont.DefaultFontName, SystemFont.Style.Italic, SystemFont.Weight.Thin);

		[UXGlobalResource]
		extern (iOS) public static readonly Font LightItalic = new SystemFont(Internal.iOSSystemFont.DefaultFontName, SystemFont.Style.Italic, SystemFont.Weight.Light);

		[UXGlobalResource]
		extern (iOS) public static readonly Font Italic = new SystemFont(Internal.iOSSystemFont.DefaultFontName, SystemFont.Style.Italic);

		[UXGlobalResource]
		extern (iOS) public static readonly Font MediumItalic = new SystemFont(Internal.iOSSystemFont.DefaultFontName, SystemFont.Style.Italic, SystemFont.Weight.Medium);

		[UXGlobalResource]
		extern (iOS) public static readonly Font SemiboldItalic = new SystemFont(Internal.iOSSystemFont.DefaultFontName, SystemFont.Style.Italic, SystemFont.Weight.Semibold);

		[UXGlobalResource]
		extern (iOS) public static readonly Font BoldItalic = new SystemFont(Internal.iOSSystemFont.DefaultFontName, SystemFont.Style.Italic, SystemFont.Weight.Bold);

		[UXGlobalResource]
		extern (iOS) public static readonly Font HeavyItalic = new SystemFont(Internal.iOSSystemFont.DefaultFontName, SystemFont.Style.Italic, SystemFont.Weight.Heavy);

		[UXGlobalResource]
		extern (iOS) public static readonly Font BlackItalic = new SystemFont(Internal.iOSSystemFont.DefaultFontName, SystemFont.Style.Italic, SystemFont.Weight.Black);




		[UXGlobalResource]
		/** The default font of the system, in it's thin weight typeface. */
		extern (!iOS && !Android) public static readonly Font UltraLight = new Font(import("Internal/DesktopFonts/Roboto-Thin.ttf"));

		[UXGlobalResource]
		/** The default font of the system, in it's thin weight typeface. */
		extern (!iOS && !Android) public static readonly Font Thin = new Font(import("Internal/DesktopFonts/Roboto-Thin.ttf"));

		[UXGlobalResource]
		/** The default font of the system, in it's light weight typeface. */
		extern (!iOS && !Android) public static readonly Font Light = new Font(import("Internal/DesktopFonts/Roboto-Light.ttf"));

		[UXGlobalResource]
		/** The default font of the system, in it's regular weight typeface. */
		extern (!iOS && !Android) public static readonly Font Regular = new Font(import("Internal/DesktopFonts/Roboto-Regular.ttf"));

		[UXGlobalResource]
		/** The default font of the system, in it's medium typeface. */
		extern (!iOS && !Android) public static readonly Font Medium = new Font(import("Internal/DesktopFonts/Roboto-Medium.ttf"));

		[UXGlobalResource]
		/** The default font of the system, in it's bold typeface. */
		extern (!iOS && !Android) public static readonly Font Semibold = new Font(import("Internal/DesktopFonts/Roboto-Bold.ttf"));

		[UXGlobalResource]
		/** The default font of the system, in it's bold typeface. */
		extern (!iOS && !Android) public static readonly Font Bold = new Font(import("Internal/DesktopFonts/Roboto-Bold.ttf"));

		[UXGlobalResource]
		/** The default font of the system, in it's bold typeface. */
		extern (!iOS && !Android) public static readonly Font Heavy = new Font(import("Internal/DesktopFonts/Roboto-Bold.ttf"));

		[UXGlobalResource]
		/** The default font of the system, in it's bold typeface. */
		extern (!iOS && !Android) public static readonly Font Black = new Font(import("Internal/DesktopFonts/Roboto-Bold.ttf"));

		[UXGlobalResource]
		/** The default font of the system, in it's thin weight typeface. */
		extern (!iOS && !Android) public static readonly Font UltraLightItalic = new Font(import("Internal/DesktopFonts/Roboto-ThinItalic.ttf"));

		[UXGlobalResource]
		/** The default font of the system, in it's thin weight typeface. */
		extern (!iOS && !Android) public static readonly Font ThinItalic = new Font(import("Internal/DesktopFonts/Roboto-ThinItalic.ttf"));

		[UXGlobalResource]
		/** The default font of the system, in it's light weight italic typeface. */
		extern (!iOS && !Android) public static readonly Font LightItalic = new Font(import("Internal/DesktopFonts/Roboto-LightItalic.ttf"));

		[UXGlobalResource]
		/** The default font of the system, in it's regular weight, italic typeface. */
		extern (!iOS && !Android) public static readonly Font Italic = new Font(import("Internal/DesktopFonts/Roboto-Italic.ttf"));

		[UXGlobalResource]
		/** The default font of the system, in it's medium and italic typeface. */
		extern (!iOS && !Android) public static readonly Font MediumItalic = new Font(import("Internal/DesktopFonts/Roboto-MediumItalic.ttf"));

		[UXGlobalResource]
		/** The default font of the system, in it's bold and italic typeface. */
		extern (!iOS && !Android) public static readonly Font SemiboldItalic = new Font(import("Internal/DesktopFonts/Roboto-BoldItalic.ttf"));

		[UXGlobalResource]
		/** The default font of the system, in it's bold and italic typeface. */
		extern (!iOS && !Android) public static readonly Font BoldItalic = new Font(import("Internal/DesktopFonts/Roboto-BoldItalic.ttf"));

		[UXGlobalResource]
		/** The default font of the system, in it's bold and italic typeface. */
		extern (!iOS && !Android) public static readonly Font HeavyItalic = new Font(import("Internal/DesktopFonts/Roboto-BoldItalic.ttf"));

		[UXGlobalResource]
		/** The default font of the system, in it's bold and italic typeface. */
		extern (!iOS && !Android) public static readonly Font BlackItalic = new Font(import("Internal/DesktopFonts/Roboto-BoldItalic.ttf"));
	}
}

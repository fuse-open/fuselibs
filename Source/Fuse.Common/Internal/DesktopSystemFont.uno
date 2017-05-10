using Fuse.Resources;
using Uno.Collections;
using Uno.UX;
using Uno.IO;

namespace Fuse.Internal
{
	extern(!iOS && !Android) static class DesktopSystemFont
	{
		static List<FontFaceDescriptor> _default;
		public static List<FontFaceDescriptor> Default
		{
			get
			{
				if (_default == null)
					_default = GetFallback(import BundleFile("DesktopFonts/Roboto-Regular.ttf"));
				return _default;
			}
		}

		public static List<FontFaceDescriptor> GetFallback(FileSource file)
		{
			List<FontFaceDescriptor> result = new List<FontFaceDescriptor>();
			result.Add(new FontFaceDescriptor(file, 0));
			result.AddRange(_fallbacks);
			return result;
		}

		static FontFaceDescriptor[] _fallbacks = new FontFaceDescriptor[]
		{
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoNaskhArabic-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoNaskhArabic-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoNaskhArabic-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansEthiopic-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansHebrew-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansThai-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansArmenian-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansGeorgian-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansDevanagari-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansGujarati-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansGurmukhi-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansTamil-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansMalayalam-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansBengali-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansTelugu-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansKannada-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansOriya-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansSinhala-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansKhmer-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansLao-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansMyanmar-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansThaana-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansCham-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansBalinese-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansBamum-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansBatak-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansBuginese-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansBuhid-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansCanadianAboriginal-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansCherokee-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansCoptic-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansGlagolitic-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansHanunoo-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansJavanese-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansKayahLi-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansLepcha-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansLimbu-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansLisu-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansMandaic-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansMeeteiMayek-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansNewTaiLue-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansNKo-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansOlChiki-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansRejang-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansSaurashtra-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansSundanese-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansSylotiNagri-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansSyriacEstrangela-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansTagbanwa-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansTaiTham-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansTaiViet-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansTibetan-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansTifinagh-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansVai-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansYi-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansSymbols-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansCJK-Regular.ttc"), 2),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansCJK-Regular.ttc"), 3),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansCJK-Regular.ttc"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansCJK-Regular.ttc"), 1),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoColorEmoji.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansTaiLe-Regular.ttf"), 0),
			new FontFaceDescriptor(import BundleFile("DesktopFonts/NotoSansMongolian-Regular.ttf"), 0),
		};
	}
}

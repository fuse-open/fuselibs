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
					_default = GetFallback(import("DesktopFonts/Roboto-Regular.ttf"));
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
			new FontFaceDescriptor(import("DesktopFonts/NotoNaskhArabic-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoNaskhArabic-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoNaskhArabic-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansEthiopic-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansHebrew-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansThai-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansArmenian-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansGeorgian-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansDevanagari-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansGujarati-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansGurmukhi-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansTamil-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansMalayalam-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansBengali-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansTelugu-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansKannada-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansOriya-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansSinhala-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansKhmer-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansLao-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansMyanmar-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansThaana-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansCham-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansBalinese-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansBamum-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansBatak-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansBuginese-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansBuhid-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansCanadianAboriginal-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansCherokee-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansCoptic-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansGlagolitic-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansHanunoo-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansJavanese-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansKayahLi-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansLepcha-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansLimbu-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansLisu-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansMandaic-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansMeeteiMayek-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansNewTaiLue-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansNKo-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansOlChiki-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansRejang-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansSaurashtra-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansSundanese-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansSylotiNagri-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansSyriacEstrangela-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansTagbanwa-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansTaiTham-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansTaiViet-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansTibetan-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansTifinagh-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansVai-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansYi-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansSymbols-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansCJK-Regular.ttc"), 2),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansCJK-Regular.ttc"), 3),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansCJK-Regular.ttc"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansCJK-Regular.ttc"), 1),
			new FontFaceDescriptor(import("DesktopFonts/NotoColorEmoji.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansTaiLe-Regular.ttf"), 0),
			new FontFaceDescriptor(import("DesktopFonts/NotoSansMongolian-Regular.ttf"), 0),
		};
	}
}

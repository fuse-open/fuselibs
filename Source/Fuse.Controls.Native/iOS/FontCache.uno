using Fuse.Internal;
using Fuse.Resources;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.UX;
using Uno;

namespace Fuse.Controls.Native.iOS
{
	[Require("Xcode.Framework", "CoreText")]
	[ForeignInclude(Language.ObjC, "UIKit/UIKit.h")]
	[ForeignInclude(Language.ObjC, "CoreText/CoreText.h")]
	[ForeignInclude(Language.ObjC, "CoreFoundation/CoreFoundation.h")]
	extern(iOS) static class FontCache
	{
		static Dictionary<FontFaceDescriptor, Dictionary<float, ObjC.Object>> _cache
			= new Dictionary<FontFaceDescriptor, Dictionary<float, ObjC.Object>>();

		public static ObjC.Object Get(FontFaceDescriptor descriptor, float size)
		{
			Dictionary<float, ObjC.Object> sizeDict;
			if (_cache.TryGetValue(descriptor, out sizeDict))
			{
				ObjC.Object result;
				if (sizeDict.TryGetValue(size, out result))
				{
					return result;
				}
			}
			else
			{
				sizeDict = new Dictionary<float, ObjC.Object>();
				_cache[descriptor] = sizeDict;
			}

			ObjC.Object uifont;
			var path = GetOptionalPath(descriptor.FileSource);
			if (path != null)
			{
				if (descriptor.IsCustomFont) 
				{
					var uifontdescriptor
					= iOSSystemFont.GetMatchingUIFontDescriptor(
						path,
						descriptor.Index,
						descriptor.Match);
					uifont = UIFontWithDescriptorAndSize(uifontdescriptor, size);
				} 
				else 
				{
					var uifontdescriptor
					= iOSSystemFont.GetMatchingSystemFontDescriptor(
						descriptor.FontStyle,
						descriptor.FontWeight,
						descriptor.FontDesign,
						descriptor.FontSize
					);
					uifont = UIFontWithDescriptorAndSize(uifontdescriptor, size);
				}
			}
			else
			{
				path = Uno.IO.Directory.GetUserDirectory(Uno.IO.UserDirectory.Data) + "/tempFont" + descriptor.FileSource.GetHashCode();
				Uno.IO.File.WriteAllBytes(path, descriptor.FileSource.ReadAllBytes());

				var uifontdescriptor
					= iOSSystemFont.GetMatchingUIFontDescriptor(
						path,
						descriptor.Index,
						descriptor.Match);
				uifont = UIFontWithDescriptorAndSize(uifontdescriptor, size);

				Uno.IO.File.Delete(path);
			}
			sizeDict[size] = uifont;
			return uifont;
		}

		static string GetOptionalPath(FileSource fileSource)
		{
			if (fileSource is SystemFileSource)
			{
				return fileSource.Name;
			}
			else if (fileSource is BundleFileSource)
			{
				var bundleFile = ((BundleFileSource)fileSource).BundleFile;
				return BundleFilePath("data/" + bundleFile.BundlePath);
			}
			return null;
		}

		[Foreign(Language.ObjC)]
		static string BundleFilePath(string resource)
		@{
			return [[NSBundle bundleForClass:[StrongUnoObject class]] pathForResource:resource ofType:nil];
		@}

		[Foreign(Language.ObjC)]
		static ObjC.Object UIFontWithDescriptorAndSize(ObjC.Object descriptor, float size)
		@{
			return [::UIFont fontWithDescriptor:(::UIFontDescriptor*)descriptor size:size];
		@}
	}
}

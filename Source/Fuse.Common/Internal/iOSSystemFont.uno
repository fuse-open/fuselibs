using Fuse.Resources;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.IO;
using Uno.UX;
using Uno;

namespace Fuse.Internal
{
	[ForeignInclude(Language.ObjC, "CoreText/CoreText.h")]
	[Require("Xcode.Framework", "CoreText")]
	extern(iOS) static class iOSSystemFont
	{
		static HashSet<string> _families;
		static Dictionary<string, string> _fontPaths;
		static readonly string[] _weightNames = new string[]
			{ "UltraLight", "Thin", "Light", "Regular", "Medium", "SemiBold", "Bold", "Heavy", "Black" };

		public static List<FontFaceDescriptor> Default
		{
			get
			{
				var descriptor = GetDefaultUIFontDescriptor();
				var descriptors = GetFallbackUIFontDescriptors(descriptor);
				var fontNames = GetFontNamesFromUIFontDescriptors(descriptors);
				return GetDescriptorsFromFontNames(fontNames);
			}
		}

		internal static string DefaultFontName
		{
			get { return GetDefaultFontFamily(); }
		}

		public static HashSet<string> Families
		{
			get
			{
				EnsureFontPathsAdded();
				return _families;
			}
		}

		public static List<FontFaceDescriptor> GetFallback(FileSource file)
		{
			var result = new List<FontFaceDescriptor>();
			result.Add(new FontFaceDescriptor(file, 0));
			result.AddRange(Get(null, Fuse.SystemFont.Style.Normal, Fuse.SystemFont.Weight.Normal));
			return result;
		}

		public static List<FontFaceDescriptor> Get(string family, Fuse.SystemFont.Style style, Fuse.SystemFont.Weight weight)
		{
			var weightIndex = Math.Clamp((int)weight, 0, _weightNames.Length - 1);
			var descriptor = GetMatchingFontDescriptor(family, style == Fuse.SystemFont.Style.Italic, _weightNames[weightIndex]);
			if (descriptor == null)
			{
				return Default;
			}
			else
			{
				var descriptors = GetFallbackUIFontDescriptors(descriptor);
				var fontNames = GetFontNamesFromUIFontDescriptors(descriptors);
				return GetDescriptorsFromFontNames(fontNames);
			}
		}

		static List<FontFaceDescriptor> GetDescriptorsFromFontNames(string[] fontNames)
		{
			var result = new List<FontFaceDescriptor>();
			foreach (var fontName in fontNames)
			{
				string path = null;
				if (fontName != null && FontPaths.TryGetValue(fontName, out path) && File.Exists(path))
				{
					result.Add(new FontFaceDescriptor(new SystemFileSource(path), GetFontNameStyles(fontName)));
				}
			}
			return result;
		}

		// A big hack
		static IEnumerable<string> GetFontNameStyles(string fontName)
		{
			var result = new List<string>();
			// A typical fontName is "HelveticaNeue-BoldItalic".
			// We're interested in the stuff after the dash.
			var dash = fontName.LastIndexOf('-');
			if (dash < 0)
				return result;
			int start = dash + 1;
			// We extract the names starting with an uppercase letter from
			// the part after the "-" and check that the style string
			// contains them.
			for (int i = start; i <= fontName.Length; ++i)
			{
				if (i == fontName.Length || char.IsUpper(fontName[i]) || char.IsDigit(fontName[i]))
				{
					// Some fonts names have stuff like "P2", "M3" in them.
					// That info appears to be metadata to do with font
					// defaults, but for face selection we just ignore
					// it.
					if (i > start + 1)
					{
						var substr = fontName.Substring(start, i - start);
						// Skip "Roman" because it isn't in the style
						// string, but is sometimes used for the plain
						// version of a face
						if (substr != "Roman")
							result.Add(substr);
					}
					start = i;
				}
			}
			return result;
		}

		static string[] GetFontNamesFromUIFontDescriptors(ObjC.Object[] descriptors)
		{
			var result = new string[descriptors.Length];
			for (int i = 0; i < descriptors.Length; ++i)
			{
				result[i] = GetDescriptorFontName(descriptors[i]);
			}
			return result;
		}

		[Foreign(Language.ObjC)]
		static string GetDescriptorFontName(ObjC.Object descriptor)
		@{
			return ((UIFontDescriptor*)descriptor).fontAttributes[UIFontDescriptorNameAttribute];
		@}

		[Foreign(Language.ObjC)]
		static string GetDefaultFontFamily()
		@{
			return [UIFont systemFontOfSize: 12].familyName;
		@}

		[Foreign(Language.ObjC)]
		static ObjC.Object GetDefaultUIFontDescriptor()
		@{
			// We can't use UIFontDescriptor
			// preferredFontDescriptorWithTextStyle: here because
			// it gives family names starting with ".Apple" that
			// are not included in the plists -- they're probably
			// special-cased somewhere internally.
			NSDictionary* attributes
				= \@{ UIFontDescriptorFamilyAttribute: [UIFont systemFontOfSize: 12].familyName };
			return [UIFontDescriptor fontDescriptorWithFontAttributes: attributes];
		@}

		[Foreign(Language.ObjC)]
		static ObjC.Object GetMatchingFontDescriptor(string family, bool isItalic, string weight)
		@{
			NSMutableDictionary* attributes = [\@{ UIFontDescriptorFaceAttribute: weight } mutableCopy];
			if (family != nil)
			{
				[attributes setObject:family forKey:UIFontDescriptorFamilyAttribute];
			}

			NSSet* mandatory = [NSSet setWithArray:attributes.allKeys];
			UIFontDescriptor* descriptor = [UIFontDescriptor fontDescriptorWithFontAttributes: attributes];
			descriptor = [descriptor fontDescriptorWithSymbolicTraits:
				[descriptor symbolicTraits] | (isItalic ? UIFontDescriptorTraitItalic : 0)];

			return descriptor;
		@}

		[Foreign(Language.ObjC)]
		static ObjC.Object[] GetFallbackUIFontDescriptors(ObjC.Object rawDescriptor)
		@{
			UIFontDescriptor* descriptor = (UIFontDescriptor*)rawDescriptor;

			NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
			NSArray* languages = [userDefaults stringArrayForKey: @"AppleLanguages"];

			CTFontRef font = CTFontCreateWithFontDescriptor((__bridge CTFontDescriptorRef)descriptor, 12.0, 0);
			CFArrayRef cascadeList = font
				? CTFontCopyDefaultCascadeListForLanguages(font, (CFArrayRef)languages)
				: nullptr;

			int count = cascadeList ? (int)CFArrayGetCount(cascadeList) : 0;
			id<UnoArray> result = @{ObjC.Object[]:New(count + 1)};
			// Includes the argument descriptor for convenience
			@{ObjC.Object[]:Of(result).Set(0, descriptor)};
			for (int i = 0; i < count; ++i)
			{
				CTFontDescriptorRef cascadeDescriptor
					= (CTFontDescriptorRef)CFArrayGetValueAtIndex(cascadeList, (CFIndex)i);
				UIFontDescriptor* uiCascadeDescriptor = (__bridge UIFontDescriptor*)cascadeDescriptor;
				@{ObjC.Object[]:Of(result).Set(i + 1, uiCascadeDescriptor)};
			}

			CFRelease(cascadeList);
			CFRelease(font);
			return result;
		@}

		static Dictionary<string, string> FontPaths
		{
			get
			{
				EnsureFontPathsAdded();
				return _fontPaths;
			}
		}

		static void EnsureFontPathsAdded()
		{
			if (_fontPaths == null)
			{
				_families = new HashSet<string>();
				_fontPaths = new Dictionary<string, string>();
				AddFontPaths();
			}
		}

		[Foreign(Language.ObjC)]
		static void AddFontPaths()
		@{
			NSFileManager* fileManager = [NSFileManager defaultManager];

			NSString* prefix = @"/System/Library/Fonts";
			BOOL isDirectory = NO;
			if ([fileManager fileExistsAtPath:prefix isDirectory:&isDirectory] && isDirectory)
			{
				NSArray *files
					= [fileManager contentsOfDirectoryAtPath:prefix error:NULL];
				NSArray* plists
					= [files filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"self ENDSWITH '.plist'"]];

				__block bool added = false;

				for (NSString* file in plists)
				{
					NSDictionary* plist = [NSDictionary dictionaryWithContentsOfFile:[prefix stringByAppendingPathComponent:file]];
					[plist[@"Names"] enumerateKeysAndObjectsUsingBlock: ^ (id key, id obj, BOOL* stop)
					{
						@{AddFontPath(string, string):Call(key, obj)};
						added = true;
					}];
					for (NSString* key in plist[@"TraitMappings"])
					{
						@{AddFamily(string):Call(key)};
					}
				}

				if (added)
				{
					return;
				}
			}

			// Slow path: No plist found --- some versions of iOS
			// don't seem to have them: Look at all the font files
			// in the fonts directory instead.
			NSURL* directory = [NSURL fileURLWithPath:prefix];
			NSArray* keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];

			NSDirectoryEnumerator* enumerator = [fileManager
				enumeratorAtURL:directory
				includingPropertiesForKeys:keys
				options:0
				errorHandler:^ (NSURL* url, NSError* error)
				{
					return YES; // Enumeration should continue
				}];

			NSArray* fontExtensions = @[@"ttf", @"ttc", @"dfont", @"otf"];

			for (NSURL* url in enumerator)
			{
				NSError* error;
				NSNumber* isDirectory = nil;
				if (![url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error])
				{
					// error
				}
				else if (![isDirectory boolValue] && [fontExtensions indexOfObject:[url pathExtension]] != NSNotFound)
				@autoreleasepool
				{
					NSArray* descriptors =
						(__bridge NSArray*)CTFontManagerCreateFontDescriptorsFromURL((__bridge CFURLRef)url);
					if (descriptors != NULL)
					{
						for (UIFontDescriptor* descriptor in descriptors)
						{
							NSString* name = [descriptor objectForKey:UIFontDescriptorNameAttribute];
							NSString* path = [url path];
							@{AddFontPath(string, string):Call(name, path)};
							NSString* family = [descriptor objectForKey:UIFontDescriptorFamilyAttribute];
							@{AddFamily(string):Call(family)};
						}
					}
				}
			}
		@}

		static void AddFontPath(string name, string path)
		{
			if (!_fontPaths.ContainsKey(name))
			{
				_fontPaths[name] = path;
			}
		}

		static void AddFamily(string name)
		{
			var lowerName = name.ToLower();
			if (!_families.Contains(lowerName))
			{
				_families.Add(lowerName);
			}
		}

		public static ObjC.Object GetMatchingUIFontDescriptor(string fileName, int index, Predicate<string> stylePredicate)
		{
			var descriptors = GetDescriptors(fileName);
			if (index >= 0)
				return descriptors[index];
			foreach (var descriptor in descriptors)
			{
				if (stylePredicate(GetStyleName(descriptor)))
				{
					return descriptor;
				}
			}
			throw new Exception("iOSSystemFont: No matching style in " + fileName);
		}

		[Foreign(Language.ObjC)]
		static ObjC.Object[] GetDescriptors(string fileName)
		@{
			NSURL* url = [NSURL fileURLWithPath:fileName];
			CFArrayRef arr = CTFontManagerCreateFontDescriptorsFromURL((__bridge CFURLRef)url);
			NSArray* descriptors = (__bridge NSArray*)arr;

			id<UnoArray> result = @{ObjC.Object[]:New((@{int})[descriptors count])};
			{
				int i = 0;
				for (UIFontDescriptor* descriptor in descriptors)
				{
					@{ObjC.Object[]:Of(result).Set(i, descriptor)};
					++i;
				}
			}

			CFRelease(arr);

			return result;
		@}

		static string GetStyleName(ObjC.Object descriptor)
		{
			var psname = GetPostscriptName(descriptor);
			var i = psname.IndexOf('-');
			return i < 0
				? ""
				: psname.Substring(i + 1);
		}

		[Foreign(Language.ObjC)]
		static string GetPostscriptName(ObjC.Object descriptor)
		@{
			return [(UIFontDescriptor*)descriptor postscriptName];
		@}
	}
}

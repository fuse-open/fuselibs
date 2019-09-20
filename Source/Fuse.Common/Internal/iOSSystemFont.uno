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
			{ "UltraLight", "Thin", "Light", "Regular", "Medium", "Semibold", "Bold", "Heavy", "Black" };

		public static List<FontFaceDescriptor> Default
		{
			get
			{
				if (Fuse.iOSDevice.OperatingSystemVersion.Major >= 13) 
				{
					var path = "/System/Library/Fonts/Core/AppleSystemUIFont";
					var fontName = ".AppleSystemUIFont";

					var ffd = new FontFaceDescriptor(new SystemFileSource(path), GetFontNameStyles(fontName));
					ffd.SetFontAttributes(Fuse.SystemFont.Style.Normal,Fuse.SystemFont.Weight.Normal,Fuse.SystemFont.Design.Default, 16, false);
					var result = new List<FontFaceDescriptor>();
					result.Add(ffd);
					return result;
				} 
				else 
				{
					var descriptor = GetDefaultUIFontDescriptor();
					var descriptors = GetFallbackUIFontDescriptors(descriptor);
					var fontNames = GetFontNamesFromUIFontDescriptors(descriptors);
					return GetDescriptorsFromFontNames(fontNames);
				}
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
			if (Fuse.iOSDevice.OperatingSystemVersion.Major >= 13) 
			{ //system font for iOS 13

				//satisfy custom font structure
				var path = "/System/Library/Fonts/Core/AppleSystemUIFont-" + style + weight;
				var fontName = ".AppleSystemUIFont-" + style + "-" + weight;

				var ffd = new FontFaceDescriptor(new SystemFileSource(path), GetFontNameStyles(fontName));
				ffd.SetFontAttributes(style,weight,Fuse.SystemFont.Design.Default, 16, false);
				var result = new List<FontFaceDescriptor>();
				result.Add(ffd);
				return result;
			} 
			else 
			{ //normal custom font
			
				var weightIndex = Math.Clamp((int)weight, 0, _weightNames.Length - 1);
				var descriptor = GetMatchingFontDescriptor(family, style == Fuse.SystemFont.Style.Italic, _weightNames[weightIndex]);
				if (descriptor == null)
				{
					descriptor = GetDefaultFontDescriptor(_weightNames[weightIndex], (style == Fuse.SystemFont.Style.Italic));
				}
				descriptor = GetFallbackUIFontDescriptorsWeight(descriptor, family, _weightNames[weightIndex], (style == Fuse.SystemFont.Style.Italic));
				var descriptors = GetFallbackUIFontDescriptors(descriptor);
				var fontNames = GetFontNamesFromUIFontDescriptors(descriptors);

				return GetDescriptorsFromFontNames(fontNames);
			}
		}

		static ObjC.Object GetFallbackUIFontDescriptorsWeight(ObjC.Object descriptor, string family, string weightName, bool isItalic) 
		{
			var fontName = (!isItalic) ? GetDescriptorFontName(descriptor) : GetDescriptorName(descriptor);
			if (weightName == "UltraLight" && isItalic == false && (DoesFontWeightExist(family, fontName, weightName) == false))
				descriptor = GetMatchingFontDescriptor(family, isItalic, "Light");
			else if (weightName == "Thin" && isItalic == false && (DoesFontWeightExist(family, fontName, weightName) == false))
				descriptor = GetMatchingFontDescriptor(family, isItalic, "Light");
			else if (weightName == "Light" && isItalic == false && (DoesFontWeightExist(family, fontName, weightName) == false))
				descriptor = GetMatchingFontDescriptor(family, isItalic, "Regular");
			else if (weightName == "Medium" && isItalic == false && (DoesFontWeightExist(family, fontName, weightName) == false))
				descriptor = GetMatchingFontDescriptor(family, isItalic, "Regular");
			else if (weightName == "Semibold" && isItalic == false && (DoesFontWeightExist(family, fontName, weightName) == false))
				descriptor = GetMatchingFontDescriptor(family, isItalic, "Bold");
			else if (weightName == "Heavy" && isItalic == false && (DoesFontWeightExist(family, fontName, weightName) == false))
				descriptor = GetMatchingFontDescriptor(family, isItalic, "Bold");
			else if (weightName == "Black" && isItalic == false && (DoesFontWeightExist(family, fontName, weightName) == false))
				descriptor = GetMatchingFontDescriptor(family, isItalic, "Bold");
			else if (weightName == "UltraLight" && isItalic && (DoesFontWeightExist(family, fontName, weightName) == false))
				descriptor = GetMatchingFontDescriptor(family, isItalic, "Light");
			else if (weightName == "Thin" && isItalic && (DoesFontWeightExist(family, fontName, weightName) == false))
				descriptor = GetMatchingFontDescriptor(family, isItalic, "Light");
			else if (weightName == "Light" && isItalic && (DoesFontWeightExist(family, fontName, weightName) == false))
				descriptor = GetMatchingFontDescriptor(family, isItalic, "Regular");
			else if (weightName == "Medium" && isItalic && (DoesFontWeightExist(family, fontName, weightName) == false))
				descriptor = GetMatchingFontDescriptor(family, isItalic, "Regular");
			else if (weightName == "Semibold" && isItalic && (DoesFontWeightExist(family, fontName, weightName) == false))
				descriptor = GetMatchingFontDescriptor(family, isItalic, "Bold");
			else if (weightName == "Heavy" && isItalic && (DoesFontWeightExist(family, fontName, weightName) == false))
				descriptor = GetMatchingFontDescriptor(family, isItalic, "Bold");
			else if (weightName == "Black" && isItalic && (DoesFontWeightExist(family, fontName, weightName) == false))
				descriptor = GetMatchingFontDescriptor(family, isItalic, "Bold");
			return descriptor;
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
				result[i] = GetDescriptorName(descriptors[i]);
			}
			return result;
		}

		[Foreign(Language.ObjC)]
		static string GetDescriptorFontName(ObjC.Object descriptor)
		@{
			return ([UIFont fontWithDescriptor: ((UIFontDescriptor*)descriptor) size: 16]).fontName;
		@}

		[Foreign(Language.ObjC)]
		static string GetDescriptorName(ObjC.Object descriptor)
		@{
			return ((UIFontDescriptor*)descriptor).fontAttributes[UIFontDescriptorNameAttribute];
		@}

		[Foreign(Language.ObjC)]
		static string GetDefaultFontFamily()
		@{
			return [UIFont systemFontOfSize: 16].familyName;
		@}

		[Foreign(Language.ObjC)]
		static ObjC.Object GetDefaultFontDescriptor(string weight, bool isItalic)
		@{
			NSDictionary* attributes
				= \@{ UIFontDescriptorFamilyAttribute: [UIFont systemFontOfSize: 16].familyName };
			UIFontDescriptor* descriptor = [UIFontDescriptor fontDescriptorWithFontAttributes: attributes];
			NSMutableDictionary* attributes2 = [\@{ UIFontDescriptorFaceAttribute: weight } mutableCopy];
			descriptor = [UIFontDescriptor fontDescriptorWithFontAttributes: attributes];
			descriptor = [descriptor fontDescriptorWithSymbolicTraits:
				[descriptor symbolicTraits] | (isItalic ? UIFontDescriptorTraitItalic : 0)];
			return descriptor;
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
				= \@{ UIFontDescriptorFamilyAttribute: [UIFont systemFontOfSize: 16].familyName };
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
		static bool DoesFontWeightExist(string family, string fontName, string weight)
		@{
			if (([fontName rangeOfString: weight options:NSCaseInsensitiveSearch].location == NSNotFound
				&& [family rangeOfString: weight options:NSCaseInsensitiveSearch].location == NSNotFound)
				|| fontName == NULL)
			{
			  return false;
			}
			else
			{
			  return true;
			}
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



		internal static ObjC.Object GetMatchingSystemFontDescriptor(Fuse.SystemFont.Style fontStyle, Fuse.SystemFont.Weight fontWeight, Fuse.SystemFont.Design fontDesign, int fontSize)
		{
			string selectedFontStyle = "normal";
			string selectedFontWeight = "normal";
			string selectedFontDesign = "default";

			switch (fontStyle) 
			{
				case Fuse.SystemFont.Style.Italic: selectedFontStyle = "italic";
					break;
			}

			switch (fontWeight) 
			{
				case Fuse.SystemFont.Weight.UltraLight: selectedFontWeight = "ultralight";
					break;
				case Fuse.SystemFont.Weight.Thin: selectedFontWeight = "thin";
					break;
				case Fuse.SystemFont.Weight.Light: selectedFontWeight = "light";
					break;
				case Fuse.SystemFont.Weight.Normal: selectedFontWeight = "normal";
					break;
				case Fuse.SystemFont.Weight.Medium: selectedFontWeight = "medium";
					break;
				case Fuse.SystemFont.Weight.Semibold: selectedFontWeight = "semibold";
					break;
				case Fuse.SystemFont.Weight.Bold: selectedFontWeight = "bold";
					break;
				case Fuse.SystemFont.Weight.Heavy: selectedFontWeight = "heavy";
					break;
				case Fuse.SystemFont.Weight.Black: selectedFontWeight = "black";
					break;
			}

			switch (fontDesign) 
			{
				case Fuse.SystemFont.Design.Default: selectedFontDesign = "default";
					break;
				case Fuse.SystemFont.Design.Monospaced: selectedFontDesign = "monospaced";
					break;
				case Fuse.SystemFont.Design.Rounded: selectedFontDesign = "rounded";
					break;
				case Fuse.SystemFont.Design.Serif: selectedFontDesign = "serif";
					break;
			}

			return getSystemFontDesign(selectedFontStyle, selectedFontWeight, selectedFontDesign, fontSize);
		}


		[Foreign(Language.ObjC)]
		static ObjC.Object getSystemFontDesign(string fontStyle, string fontWeight, string fontDesign, int fontSize)
		@{
			//weight
			UIFontWeight selectedWeight;
			if ([fontWeight isEqualToString:@"ultralight"])
				selectedWeight = UIFontWeightUltraLight;
			else if ([fontWeight isEqualToString:@"thin"])
				selectedWeight = UIFontWeightThin;
			else if ([fontWeight isEqualToString:@"light"])
				selectedWeight = UIFontWeightLight;
			else if ([fontWeight isEqualToString:@"normal"])
				selectedWeight = UIFontWeightRegular;
			else if ([fontWeight isEqualToString:@"regular"])
				selectedWeight = UIFontWeightRegular;
			else if ([fontWeight isEqualToString:@"medium"])
				selectedWeight = UIFontWeightMedium;
			else if ([fontWeight isEqualToString:@"semibold"])
				selectedWeight = UIFontWeightSemibold;
			else if ([fontWeight isEqualToString:@"bold"])
				selectedWeight = UIFontWeightBold;
			else if ([fontWeight isEqualToString:@"heavy"])
				selectedWeight = UIFontWeightHeavy;
			else if ([fontWeight isEqualToString:@"black"])
				selectedWeight = UIFontWeightBlack;

			//size & weight
			UIFontDescriptor* descriptor = [UIFont systemFontOfSize: fontSize weight:selectedWeight].fontDescriptor;

			//normal by default or italic
			if ([fontStyle isEqualToString:@"italic"]) {
				descriptor = [descriptor fontDescriptorWithSymbolicTraits:
					[descriptor symbolicTraits] | UIFontDescriptorTraitItalic];
			}

			//design
			#if defined(__IPHONE_13_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0
			UIFontDescriptorSystemDesign selectedDesign;
			if ([fontDesign isEqualToString:@"default"])
				selectedDesign = UIFontDescriptorSystemDesignDefault;
			else if ([fontDesign isEqualToString:@"monospaced"])
				selectedDesign = UIFontDescriptorSystemDesignMonospaced;
			else if ([fontDesign isEqualToString:@"rounded"])
				selectedDesign = UIFontDescriptorSystemDesignRounded;
			else if ([fontDesign isEqualToString:@"serif"])
				selectedDesign = UIFontDescriptorSystemDesignSerif;

			descriptor = [descriptor fontDescriptorWithDesign: selectedDesign];
			#endif

			return descriptor;
		@}

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

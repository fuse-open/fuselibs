using Fuse.Resources;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.IO;
using Uno.UX;
using Uno;

namespace Fuse.Internal
{
	[ForeignInclude(Language.Java, "com.fuse.android.graphics.FontListParser")]
	extern(Android) static class AndroidSystemFont
	{
		struct Family
		{
			public readonly string Name;
			public readonly string Language;
			public readonly string Variant;
			public readonly List<FontDescriptor> Fonts;

			public Family(string name, string language, string variant)
			{
				Name = name;
				Language = language;
				Variant = variant;
				Fonts = new List<FontDescriptor>();
			}
		}

		struct FontDescriptor
		{
			public readonly string FilePath;
			public readonly int Index;
			public readonly Fuse.SystemFont.Style Style;
			public readonly Fuse.SystemFont.Weight Weight;

			public FontDescriptor(string filePath, int index, Fuse.SystemFont.Style style, Fuse.SystemFont.Weight weight)
			{
				FilePath = filePath;
				Index = index;
				Style = style;
				Weight = weight;
			}
		}

		struct Alias
		{
			public readonly string To;
			public readonly Fuse.SystemFont.Weight Weight;

			public Alias(string to, Fuse.SystemFont.Weight weight)
			{
				To = to;
				Weight = weight;
			}
		}

		static List<Family> _families;
		static Dictionary<string, Alias> _aliases;

		static HashSet<string> _familyNames;

		static List<FontFaceDescriptor> _default;

		public static List<FontFaceDescriptor> Default
		{
			get
			{
				if (_default == null)
				{
					EnsureFontsAdded();
					if (_families.Count >= 1)
						_default = Get(_families[0].Name, Fuse.SystemFont.Style.Normal, Fuse.SystemFont.Weight.Normal);
				}
				return _default;
			}
		}

		public static HashSet<string> Families
		{
			get
			{
				EnsureFontsAdded();
				return _familyNames;
			}
		}

		public static List<FontFaceDescriptor> GetFallback(FileSource file)
		{
			var result = new List<FontFaceDescriptor>();
			result.Add(new FontFaceDescriptor(file, 0));
			result.AddRange(Get(null, Fuse.SystemFont.Style.Normal, Fuse.SystemFont.Weight.Normal));
			return result;
		}

		public static List<FontFaceDescriptor> Get(string familyName, Fuse.SystemFont.Style style, Fuse.SystemFont.Weight weight)
		{
			EnsureFontsAdded();
			if (familyName != null)
			{
				Alias alias;
				if (_aliases.TryGetValue(familyName, out alias))
				{
					// What to do with alias.Weight? It's ignored for now.
					return Get(alias.To, style, weight);
				}
			}
			var result = new List<FontFaceDescriptor>();
			bool realMatch = false;
			foreach (var family in _families)
			{
				if (familyName == null || family.Name == null || familyName == family.Name)
				{
					realMatch = realMatch || familyName == family.Name;

					var descriptor = Get(family, style, weight);
					if (descriptor != null)
						result.Add(descriptor);
				}
			}
			if (result.Count > 0 && (realMatch || style != Fuse.SystemFont.Style.Normal || weight != Fuse.SystemFont.Weight.Normal))
			{
				return result;
			}
			else
			{
				return Default;
			}
		}

		static FontFaceDescriptor Get(Family family, Fuse.SystemFont.Style style, Fuse.SystemFont.Weight weight)
		{
			var lowestDiff = int.MaxValue;
			var lowestIndex = -1;
			for (int i = 0; i < family.Fonts.Count; ++i)
			{
				var font = family.Fonts[i];
				if (File.Exists(font.FilePath))
				{
					var diff = 100 * Math.Abs((int)style - (int)font.Style) +
						Math.Abs((int)weight - (int)font.Weight);
					if (diff < lowestDiff)
					{
						lowestDiff = diff;
						lowestIndex = i;
						if (diff == 0)
							break;
					}
				}
			}
			if (lowestIndex >= 0)
			{
				var font = family.Fonts[lowestIndex];
				return new FontFaceDescriptor(new SystemFileSource(font.FilePath), font.Index);
			}
			return null;
		}

		static void EnsureFontsAdded()
		{
			if (_families == null)
			{
				_families = new List<Family>();
				_aliases = new Dictionary<string, Alias>();
				_familyNames = new HashSet<string>();
				AddFonts();
			}
		}

		[Foreign(Language.Java)]
		static void AddFonts()
		@{
			try
			{
				FontListParser.Config config = FontListParser.getFontConfig();
				for (FontListParser.Family family : config.families)
				{
					String firstFamilyName = family.names.size() > 0 ? family.names.get(0) : null;
					@{AddFamily(string, string, string):Call(firstFamilyName, family.lang, family.variant)};
					for (FontListParser.Font font : family.fonts)
					{
						@{AddFont(string, int, int, bool):Call(font.fontName, font.ttcIndex, font.weight, font.isItalic)};
					}
					for (int i = 1; i < family.names.size(); ++i)
					{
						String alias = family.names.get(i);
						@{AddAlias(string, string, int):Call(alias, firstFamilyName, FontListParser.NormalWeight)};
					}
				}
				for (FontListParser.Alias alias : config.aliases)
				{
					@{AddAlias(string, string, int):Call(alias.name, alias.toName, alias.weight)};
				}
				}
			catch (Exception e)
			{
				@{ThrowUno(string):Call(e.toString())};
			}
		@}

		static void ThrowUno(string message)
		{
			throw new Exception(message);
		}

		static void AddFamily(string name, string language, string variant)
		{
			var lowerName = name == null ? null : name.ToLower();
			_families.Add(new Family(lowerName, language, variant));
			if (lowerName != null && !_familyNames.Contains(lowerName))
			{
				_familyNames.Add(lowerName);
			}
		}

		static void AddFont(string path, int index, int weight, bool isItalic)
		{
			_families[_families.Count - 1].Fonts.Add(
				new FontDescriptor(
					path,
					index,
					isItalic ? Fuse.SystemFont.Style.Italic : Fuse.SystemFont.Style.Normal,
					ToWeight(weight)));
		}

		static Fuse.SystemFont.Weight ToWeight(int w) { return (Fuse.SystemFont.Weight)(w / 100 - 1); }

		static void AddAlias(string name, string to, int weight)
		{
			if (name != null && !_aliases.ContainsKey(name))
			{
				_aliases.Add(name, new Alias(to, ToWeight(weight)));
				if (!_familyNames.Contains(name))
					_familyNames.Add(name);
			}
		}
	}
}

using Uno.Collections;
using Uno.IO;
using Uno.UX;
using Uno;

namespace Fuse.Internal
{
	class FontFaceDescriptor
	{
		public readonly FileSource FileSource;
		public readonly int Index;
		public readonly IEnumerable<string> Styles;

		//iOS13+ - for default systemfont
		extern(IOS) internal bool IsCustomFont = true;
		extern(IOS) internal Fuse.SystemFont.Style FontStyle; //normal/italic
		extern(IOS) internal Fuse.SystemFont.Weight FontWeight; //thin/light/regular/bold/etc
		extern(IOS) internal Fuse.SystemFont.Design FontDesign; //default/monospaced/rounded/serif
		extern(IOS) internal int FontSize; //12/16/etc

		/** Create a `FontFaceDescriptor` that selects the face by matching the its string. */
		public FontFaceDescriptor(FileSource fileSource, IEnumerable<string> styles)
		{
			FileSource = fileSource;
			Index = -1;
			Styles = styles;
		}

		/** Create a `FontFaceDescriptor` that selects the face with index `index`. */
		public FontFaceDescriptor(FileSource fileSource, int index)
		{
			FileSource = fileSource;
			Index = index;
			Styles = new string[0];
		}

		public bool Match(string styleString)
		{
			return Styles.All(styleString.Contains);
		}

		public override bool Equals(object o)
		{
			var f = o as FontFaceDescriptor;
			return f != null &&
				FileSource.Name == f.FileSource.Name &&
				Index == f.Index &&
				Styles.SequenceEqual(f.Styles);
		}

		public override int GetHashCode()
		{
			int hash = 17;
			hash = hash * 23 + FileSource.Name.GetHashCode();
			hash = hash * 23 + Index.GetHashCode();
			foreach (var s in Styles)
			{
				hash = hash * 23 + s.GetHashCode();
			}
			return hash;
		}

		extern(IOS) internal void SetFontAttributes(Fuse.SystemFont.Style fontStyle, Fuse.SystemFont.Weight fontWeight, Fuse.SystemFont.Design fontDesign, int fontSize, bool isCustomFont)
		{
			FontStyle = fontStyle;
			FontWeight = fontWeight;
			FontDesign = fontDesign;
			FontSize = fontSize;
			IsCustomFont = isCustomFont;
		}
	}

	static class SystemFont
	{
		public static List<FontFaceDescriptor> Default
		{
			get
			{
				if defined(iOS) return iOSSystemFont.Default;
				else if defined(Android) return AndroidSystemFont.Default;
				else return DesktopSystemFont.Default;
			}
		}

		public static List<FontFaceDescriptor> Get(
			string family,
			Fuse.SystemFont.Style style = Fuse.SystemFont.Style.Normal,
			Fuse.SystemFont.Weight weight = Fuse.SystemFont.Weight.Normal)
		{
			if defined(iOS) return iOSSystemFont.Get(family == null ? null : family.ToLower(), style, weight);
			else if defined(Android) return AndroidSystemFont.Get(family == null ? null : family.ToLower(), style, weight);
			else return Default;
		}

		public static List<FontFaceDescriptor> GetFallback(FileSource file)
		{
			if defined(iOS) return iOSSystemFont.GetFallback(file);
			else if defined(Android) return AndroidSystemFont.GetFallback(file);
			else return DesktopSystemFont.GetFallback(file);
		}

		public static HashSet<string> Families
		{
			get
			{
				if defined(iOS) return iOSSystemFont.Families;
				else if defined(Android) return AndroidSystemFont.Families;
				else return new HashSet<string>();
			}
		}
	}
}

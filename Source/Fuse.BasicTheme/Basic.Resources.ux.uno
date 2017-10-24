using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse;
using Fuse.Elements;
using Fuse.Triggers;
using Fuse.Controls;

namespace Basic
{
	public enum ColorScheme
	{
		LightBlue,
		BlueGrey,
		Blue,
		Brown,
		Cyan,
		Amber,
		DeepOrange,
		DeepPurple,
		Green,
		Grey,
		Indigo,
		LightGreen,
		Lime,
		Orange,
		Pink,
		Purple,
		Red,
		Teal,
		Yellow,
	}

	public partial class Resources
	{
		static PropertyHandle _colorScheme = Properties.CreateHandle();

		[UXAttachedPropertySetter("Basic.ColorScheme")]
		public static void SetColorScheme(Control control, ColorScheme scheme)
		{
			var s = GetColorScheme(scheme);
			for (int i = 0; i < ColorCodes.Length; i++)
				control.SetResource(ColorCodes[i], Uno.Color.Parse(s[i]));
		}

        static string[] GetColorScheme(ColorScheme scheme)
        {
        	switch (scheme)
        	{
        		case ColorScheme.Amber: return Amber;
				case ColorScheme.BlueGrey: return BlueGrey;
				case ColorScheme.Blue: return Blue;
				case ColorScheme.Brown: return Brown;
				case ColorScheme.Cyan: return Cyan;
				case ColorScheme.DeepOrange: return DeepOrange;
				case ColorScheme.DeepPurple: return DeepPurple;
				case ColorScheme.Green: return Green;
				case ColorScheme.Grey: return Grey;
				case ColorScheme.Indigo: return Indigo;
				case ColorScheme.LightBlue: return LightBlue;
				case ColorScheme.LightGreen: return LightGreen;
				case ColorScheme.Lime: return Lime;
				case ColorScheme.Orange: return Orange;
				case ColorScheme.Pink: return Pink;
				case ColorScheme.Purple: return Purple;
				case ColorScheme.Red: return Red;
				case ColorScheme.Teal: return Teal;
				case ColorScheme.Yellow: return Yellow;
				default: throw new Exception("Invalid color scheme");
        	}
        }

        static string[] ColorCodes = new [] { "Basic.C50", "Basic.C100", "Basic.C200", "Basic.C300", "Basic.C400", "Basic.C500", "Basic.C600", "Basic.C700", "Basic.C800", "Basic.C900" };
		static string[] Red = new [] { "#FFEBEE", "#FFCDD2", "#EF9A9A", "#E57373", "#EF5350", "#F44336", "#E53935", "#D32F2F", "#C62828", "#B71C1C" };
		static string[] Pink = new [] { "#FCE4EC", "#F8BBD0", "#F48FB1", "#F06292", "#EC407A", "#E91E63", "#D81B60", "#C2185B", "#AD1457", "#880E4F" };
		static string[] Purple = new [] { "#F3E5F5", "#E1BEE7", "#CE93D8", "#BA68C8", "#AB47BC", "#9C27B0", "#8E24AA", "#7B1FA2", "#6A1B9A", "#4A148C" };
		static string[] DeepPurple = new [] { "#EDE7F6", "#D1C4E9", "#B39DDB", "#9575CD", "#7E57C2", "#673AB7", "#5E35B1", "#512DA8", "#4527A0", "#311B92" };
		static string[] Indigo = new [] { "#E8EAF6", "#C5CAE9", "#9FA8DA", "#7986CB", "#5C6BC0", "#3F51B5", "#3949AB", "#303F9F", "#283593", "#1A237E" };
		static string[] Blue = new [] { "#E3F2FD", "#BBDEFB", "#90CAF9", "#64B5F6", "#42A5F5", "#2196F3", "#1E88E5", "#1976D2", "#1565C0", "#0D47A1" };
		static string[] LightBlue = new [] { "#E1F5FE", "#B3E5FC", "#81D4FA", "#4FC3F7", "#29B6F6", "#03A9F4", "#039BE5", "#0288D1", "#0277BD", "#01579B" };
		static string[] Cyan = new [] { "#E0F7FA", "#B2EBF2", "#80DEEA", "#4DD0E1", "#26C6DA", "#00BCD4", "#00ACC1", "#0097A7", "#00838F", "#006064" };
		static string[] Teal = new [] { "#E0F2F1", "#B2DFDB", "#80CBC4", "#4DB6AC", "#26A69A", "#009688", "#00897B", "#00796B", "#00695C", "#004D40" };
		static string[] Green = new [] { "#E8F5E9", "#C8E6C9", "#A5D6A7", "#81C784", "#66BB6A", "#4CAF50", "#43A047", "#388E3C", "#2E7D32", "#1B5E20" };
		static string[] LightGreen = new [] { "#F1F8E9", "#DCEDC8", "#C5E1A5", "#AED581", "#9CCC65", "#8BC34A", "#7CB342", "#689F38", "#558B2F", "#33691E" };
		static string[] Lime = new [] { "#F9FBE7", "#F0F4C3", "#E6EE9C", "#DCE775", "#D4E157", "#CDDC39", "#C0CA33", "#AFB42B", "#9E9D24", "#827717" };
		static string[] Yellow = new [] { "#FFFDE7", "#FFF9C4", "#FFF59D", "#FFF176", "#FFEE58", "#FFEB3B", "#FDD835", "#FBC02D", "#F9A825", "#F57F17" };
		static string[] Amber = new [] { "#FFF8E1", "#FFECB3", "#FFE082", "#FFD54F", "#FFCA28", "#FFC107", "#FFB300", "#FFA000", "#FF8F00", "#FF6F00" };
		static string[] Orange = new [] { "#FFF3E0", "#FFE0B2", "#FFCC80", "#FFB74D", "#FFA726", "#FF9800", "#FB8C00", "#F57C00", "#EF6C00", "#E65100" };
		static string[] DeepOrange = new [] { "#FBE9E7", "#FFCCBC", "#FFAB91", "#FF8A65", "#FF7043", "#FF5722", "#F4511E", "#E64A19", "#D84315", "#BF360C" };
		static string[] Brown = new [] { "#EFEBE9", "#D7CCC8", "#BCAAA4", "#A1887F", "#8D6E63", "#795548", "#6D4C41", "#5D4037", "#4E342E", "#3E2723" };
		static string[] Grey = new [] { "#FAFAFA", "#F5F5F5", "#EEEEEE", "#E0E0E0", "#BDBDBD", "#9E9E9E", "#757575", "#616161", "#424242", "#212121" };
		static string[] BlueGrey = new [] { "#ECEFF1", "#CFD8DC", "#B0BEC5", "#90A4AE", "#78909C", "#607D8B", "#546E7A", "#455A64", "#37474F", "#263238" };
	}
}

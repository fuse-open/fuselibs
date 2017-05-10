using Uno.UX;

namespace Fuse.Drawing
{
	public static class Colors
	{
		[UXGlobalResource] public static readonly float4 Transparent = Uno.Color.FromRgba(0x00000000);
		[UXGlobalResource] public static readonly float4 Black = 	Uno.Color.FromRgba(0x000000FF);
		[UXGlobalResource] public static readonly float4 Silver = Uno.Color.FromRgba(0xC0C0C0FF);
		[UXGlobalResource] public static readonly float4 Gray = 	Uno.Color.FromRgba(0x808080FF);
		[UXGlobalResource] public static readonly float4 White = 	Uno.Color.FromRgba(0xFFFFFFFF);
		[UXGlobalResource] public static readonly float4 Maroon = Uno.Color.FromRgba(0x800000FF);
		[UXGlobalResource] public static readonly float4 Red = 	Uno.Color.FromRgba(0xFF0000FF);
		[UXGlobalResource] public static readonly float4 Purple = Uno.Color.FromRgba(0x800080FF);
		[UXGlobalResource] public static readonly float4 Fuchsia = Uno.Color.FromRgba(0xFF00FFFF);
		[UXGlobalResource] public static readonly float4 Green = 	Uno.Color.FromRgba(0x008000FF);
		[UXGlobalResource] public static readonly float4 Lime = 	Uno.Color.FromRgba(0x00FF00FF);
		[UXGlobalResource] public static readonly float4 Olive = 	Uno.Color.FromRgba(0x808000FF);
		[UXGlobalResource] public static readonly float4 Yellow = Uno.Color.FromRgba(0xFFFF00FF);
		[UXGlobalResource] public static readonly float4 Navy = 	Uno.Color.FromRgba(0x000080FF);
		[UXGlobalResource] public static readonly float4 Blue = 	Uno.Color.FromRgba(0x0000FFFF);
		[UXGlobalResource] public static readonly float4 Teal = 	Uno.Color.FromRgba(0x008080FF);
		[UXGlobalResource] public static readonly float4 Aqua = 	Uno.Color.FromRgba(0x00FFFFFF);
	}

	public static class Brushes
	{
		[UXGlobalResource] public static readonly StaticSolidColor Transparent = new StaticSolidColor(Colors.Black);
		[UXGlobalResource] public static readonly StaticSolidColor Black = new StaticSolidColor(Colors.Black);
		[UXGlobalResource] public static readonly StaticSolidColor Silver = new StaticSolidColor(Colors.Silver);
		[UXGlobalResource] public static readonly StaticSolidColor Gray = new StaticSolidColor(Colors.Gray);
		[UXGlobalResource] public static readonly StaticSolidColor White = new StaticSolidColor(Colors.White);
		[UXGlobalResource] public static readonly StaticSolidColor Maroon = new StaticSolidColor(Colors.Maroon);
		[UXGlobalResource] public static readonly StaticSolidColor Red = new StaticSolidColor(Colors.Red);
		[UXGlobalResource] public static readonly StaticSolidColor Purple = new StaticSolidColor(Colors.Purple);
		[UXGlobalResource] public static readonly StaticSolidColor Fuchsia = new StaticSolidColor(Colors.Fuchsia);
		[UXGlobalResource] public static readonly StaticSolidColor Green = new StaticSolidColor(Colors.Green);
		[UXGlobalResource] public static readonly StaticSolidColor Lime = new StaticSolidColor(Colors.Lime);
		[UXGlobalResource] public static readonly StaticSolidColor Olive = new StaticSolidColor(Colors.Olive);
		[UXGlobalResource] public static readonly StaticSolidColor Yellow = new StaticSolidColor(Colors.Yellow);
		[UXGlobalResource] public static readonly StaticSolidColor Navy = new StaticSolidColor(Colors.Navy);
		[UXGlobalResource] public static readonly StaticSolidColor Blue = new StaticSolidColor(Colors.Blue);
		[UXGlobalResource] public static readonly StaticSolidColor Teal = new StaticSolidColor(Colors.Teal);
		[UXGlobalResource] public static readonly StaticSolidColor Aqua = new StaticSolidColor(Colors.Aqua);
	}
}

using Uno.UX;
using Uno;

namespace Fuse
{
	/** A system-specific typeface from the target device.

	This allows us to get fonts available on the target system on Android and iOS.
	By using this we can save space by not bundling fonts that are known to be available on the target system with our app.

	Returns the default font if no matching font is found.

	## Example

	The following example shows how to use a bold font from the Baskerville font family:

		<SystemFont Family="Baskerville" Style="Normal" Weight="Bold" ux:Global="BaskervilleBold" />
		<Text Font="BaskervilleBold">Hello, world!</Text>

	Android typically uses abstract font families (e.g. `sans-serif`),
	whereas iOS uses concrete (e.g. `Helvetica Neue`), so it is often the case that
	we want to specify different font families that are depending on the target. To do this,
	we can use local resources:

		<Android>
			<SystemFont Family="monospace" Style="Normal" Weight="Normal" ux:Key="Monospace" />
		</Android>
		<iOS>
			<SystemFont Family="Courier" Style="Normal" Weight="Normal" ux:Key="Monospace" />
		</iOS>
		<Text Font="{Resource Monospace}">Hello, world!</Text>

	Note that this only works on iOS and Android, and that it is not guaranteed to
	be consistent across devices, OSes, or OS versions.

	*/
	public sealed class SystemFont : Font
	{
		public enum Weight
		{
			UltraLight,
			Thin,
			Light,
			Normal,
			Medium,
			Semibold,
			Bold,
			Heavy,
			Black,

			[Obsolete]
			SemiBold = Semibold
		}

		public enum Style
		{
			Normal,
			Italic,
		}

		public enum Design
		{
			Default,
			Monospaced,
			Rounded,
			Serif,
		}

		[UXConstructor]
		public SystemFont([UXParameter("Family")] string family, [UXParameter("Style")] Style style = Style.Normal, [UXParameter("Weight")] Weight weight = Weight.Normal)
			: base(Internal.SystemFont.Get(family, style, weight))
		{
		}
	}
}

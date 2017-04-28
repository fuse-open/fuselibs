
namespace Fuse.Controls
{
	public enum TextWrapping
	{
		NoWrap,
		Wrap
	}

	public enum TextAlignment
	{
		Left,
		Center,
		Right
	}

	public enum TextInputActionType
	{
		Primary,
	}

	public enum TextInputActionStyle
	{
		Default,
		Done,
		Next,
		Go,
		Search,
		Send,
	}

	public enum TextInputHint
	{
		Default = 0,
		Email = 1,
		URL = 2,
		Phone = 3,
		Integer = 4,
		Decimal = 5,
		Number = Integer
	}

	public enum AutoCorrectHint
	{
		Default = 0,
		Disabled = 1,
		Enabled = 2
	}

	public enum AutoCapitalizationHint
	{
		None = 0,
		Characters = 1,
		Words = 2,
		Sentences = 3
	}

	public enum TextTruncation
	{
		Standard,
		None
	}
}
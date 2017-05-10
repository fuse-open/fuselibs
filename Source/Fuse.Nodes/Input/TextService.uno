using Fuse.Scripting;

namespace Fuse.Input
{
	public static class TextService
	{
		static readonly TextEntered _textEntered = new TextEntered();

		public static VisualEvent<TextEnteredHandler, TextEnteredArgs> TextEntered { get { return _textEntered; } }

		internal static bool RaiseTextEntered(string text)
		{
			if (Focus.FocusedVisual != null)
			{
				var args = new TextEnteredArgs(text, Focus.FocusedVisual);
				TextEntered.RaiseWithBubble(args);
				return args.IsHandled;
			}

			return false;
		}

	}


	// --- TextEntered ---
	public class TextEnteredArgs: VisualEventArgs
	{
		public string Text { get; private set; }

		public TextEnteredArgs(string text, Visual visual): base(visual)
		{
			Text = text;
		}

		override void Serialize(IEventSerializer s)
		{
			s.AddString("text", Text);
		}
	}

	public delegate void TextEnteredHandler(object sender, TextEnteredArgs args);

	sealed class TextEntered: VisualEvent<TextEnteredHandler, TextEnteredArgs>
	{
		protected override void Invoke(TextEnteredHandler handler, object sender, TextEnteredArgs args)
		{
			handler(sender, args);
		}
	}
}
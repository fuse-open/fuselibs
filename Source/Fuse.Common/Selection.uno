using Uno;

namespace Fuse.Preview
{
	public static class SelectionManager
	{
		public static ISelection Selection { get; private set; }
		public static event EventHandler<EventArgs> SelectionChanged;

		public static void SetSelection(ISelection selection)
		{
			Selection = selection;
			var handler = SelectionChanged;
			if (handler != null)
				handler(null, EventArgs.Empty);
		}

		public static bool IsSelected(object obj)
		{
			if (Selection != null)
				return Selection.IsSelected(obj);
			return false;
		}
	}

	public interface ISelection
	{
		bool IsSelected(object obj);
		bool IsPropertySelected(object obj, string property);
	}
}

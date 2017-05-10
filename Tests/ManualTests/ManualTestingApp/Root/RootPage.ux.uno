using Uno;
using Uno.Collections;

using Fuse;

public partial class RootPage
{
	List<Visual> _prevRoot = new List<Visual>();
	void SwitchRoot(object s, object a)
	{	
		_prevRoot.Clear();
		
		var app = Fuse.App.Current;
		for (int i = 0; i < app.Children.Count; i++)
		{
			var v = app.Children[i] as Visual;
			if (v != null)
				_prevRoot.Add(v);
		}
		
		for (int i=0; i < _prevRoot.Count; ++i)
			app.Children.Remove(_prevRoot[i]);
		
		app.Children.Add(AltRoot);
	}
	
	void SwitchRootBack(object s, object a)
	{
		var app = Fuse.App.Current;
		app.Children.Remove(AltRoot);
		for (int i=0; i < _prevRoot.Count; ++i)
			app.Children.Add(_prevRoot[i]);
	}
}

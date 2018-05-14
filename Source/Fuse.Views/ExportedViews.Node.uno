using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse
{
	public class ExportedViews : Fuse.Node
	{
		static readonly List<Template> _templates = new List<Template>();

		[UXContent]
		public IList<Template> Templates
		{
			get { return _templates; }
		}

		public static Template FindTemplate(string key)
		{
			foreach(var t in _templates)
			{
				if (t.Key == key)
					return t;
			}
			return null;
		}
	}
}
using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Internal;

namespace Fuse
{
	public interface ITemplateSource
	{
		Template FindTemplate(string key);
	}
	
	struct TemplateSourceImpl
	{
		List<Template> _templates;
		
		public int Count { get { return _templates == null ? 0 : _templates.Count; } }
		public Template this[int index] { get { return _templates[index]; } }
		public List<Template> Templates
		{
			get
			{
				if (_templates == null)
					_templates = new List<Template>();
				return _templates;
			}
		}

		public Template FindTemplate(string key)
		{
			// Search backwards to allow key overrides
			for (int i = Count-1; i >= 0; --i )
			{
				var t = _templates[i];
				if (t.Key == key) return t;
			}
			return null;
		}
	}
	
	public partial class Visual
	{
		TemplateSourceImpl _templates;

		/** List of templates that will be used to populate this Visual.

			This list allows you to place nodes with a `ux:Template="key"` attribute inside a @Visual in UX Markup, 
			where `key` is the match key to be used when selecting a template.

			This list has many use cases. For example, when populating a view with data, the correct template can be 
			picked based on a field	in the data source:

				<StackPanel Items="{items}" MatchKey="type">
					<SmallProfile ux:Template="small_profile" />
					<BigProfile ux:Template="big_profile" />
				</StackPanel>

			The name of the template can also have a special significance in certain contexts, for example when dealing
			with native control wrappers:

				<Control ux:Class="MySlider">
					<MyWrappers.iOS.Slider ux:Template="iOSAppearance" />
					<MyWrappers.Android.Slider ux:Template="AndroidAppearance" />
					<MyWrappers.Graphics.Slider ux:Template="GraphicsAppearance" />
				</Control>
		*/
		[UXContent]
		public IList<Template> Templates { get { return _templates.Templates; } }
		public Template FindTemplate(string key) { return _templates.FindTemplate(key); }
	}
}
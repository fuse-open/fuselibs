using Uno;
using Uno.Collections;
using Uno.UX;

namespace Fuse
{
	public interface ITemplateObserver
	{
		void OnTemplatesChangedWileRooted();
	}

	public partial class Visual
	{
		RootableList<Template> _templates;

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
		public IList<Template> Templates 
		{ 
			get
			{
				if (_templates == null)
				{
					_templates = new RootableList<Template>();
					if (IsRootingCompleted)
						RootTemplates();
				}
				return _templates;
			}
		}

		void RootTemplates()
		{
			if (_templates != null)
				_templates.Subscribe(OnTemplatesChanged, OnTemplatesChanged);
		}
		
		void UnrootTemplates()
		{
			if (_templates != null)
				_templates.Unsubscribe();
		}
		
		void OnTemplatesChanged(Template t)
		{
			if (IsRootingCompleted)
			{
				for (var i = 0; i < Children.Count; i++)
				{
					var to = Children[i] as ITemplateObserver;
					if (to != null) to.OnTemplatesChangedWileRooted();
				}
			}
		}

		public Template FindTemplate(string key)
		{
			if (_templates == null) return null;

			// Search backwards to allow key overrides
			for (int i = _templates.Count; i --> 0; )
			{
				var t = _templates[i];
				if (t.Key == key) return t;
			}
			return null;
		}
	}
}
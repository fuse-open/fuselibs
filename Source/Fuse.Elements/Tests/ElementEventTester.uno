using Uno;
using Uno.Collections;

using Fuse;
using Fuse.Elements;

namespace FuseTest
{
	public class ElementEventsHelper
	{
		public int NumIsContextEnabledCalled { get; private set; }

		public ElementEventsHelper(Element elm)
		{
			BindEventHandlers(elm);
		}

		private void BindEventHandlers(Element elm)
		{
			elm.IsContextEnabledChanged += IsContextEnabledChanged;
		}

		//region Event Handlers

		private void IsContextEnabledChanged(object sender, EventArgs args)
		{
			NumIsContextEnabledCalled = NumIsContextEnabledCalled + 1;
		}

		//endregion Event Handlers
	}
}

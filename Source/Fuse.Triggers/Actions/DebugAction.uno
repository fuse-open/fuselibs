using Uno;
using Uno.Collections;
using Uno.UX;
using System;

namespace Fuse.Triggers.Actions
{
	/** Log a message, which is useful for debugging

		## Example

			<StackPanel Margin="20">
				<Button Margin="10" Text="Log 'Hello World!'">
					<Clicked>
						<DebugAction Message="Hello World!" />
					</Clicked>
				</Button>
			</StackPanel>
	*/
	public class DebugAction : TriggerAction
	{
		public string Message { get; set; }

		List<ITaggedDebugProperty> _props;

		[UXContent]
		public IList<ITaggedDebugProperty> Properties
		{
			get
			{
				if(_props == null) _props = new List<ITaggedDebugProperty>();
				return _props;
			}
		}

		protected override void Perform(Node target)
		{
			if defined(DEBUG)
			{
				if (Message != null)
					Uno.Diagnostics.Log.Debug(Message);

				if (_props != null)
				{
					foreach (ITaggedDebugProperty prop in _props)
					{
						Uno.Diagnostics.Log.Debug(prop.GetTag() + " = " + prop.GetStringValue());
					}
				}
			}
		}
	}
}

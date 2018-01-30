using Uno;
using Fuse;
using Fuse.Animations;

namespace Fuse.Triggers
{
	/**
		Animates when the parent element is removed

		This is very commonly used together with lists of items.

		#Example
		The following example contains a list, where every item plays a `RemovingAnimation` as they are removed:

			<JavaScript>
				var Observable = require('FuseJS/Observable');
				var list = Observable("Dog", "Cat", "Horse");
				function rm(data) {
					list.remove(data.data);
				}
				module.exports = {
					data: list,
					rm: rm
				};
			</JavaScript>
			<StackPanel>
				<Each Items="{data}" >
					<Panel>
						<Button Margin="10" Alignment="CenterRight" Text="Delete" Clicked="{rm}"/>
						<Rectangle Height="1" Alignment="Bottom">
							<Stroke Color="#DDD" />
						</Rectangle>
						<Text Margin="10" Value="data()" />
						<RemovingAnimation>
							<Move RelativeTo="Size" X="-1" Duration="0.4" Easing="CircularOut" />
						</RemovingAnimation>
					</Panel>
				</Each>
			</StackPanel>
	*/
	public class RemovingAnimation: Trigger, IBeginRemoveVisualListener
	{
		PendingRemoveVisual _args;

		void IBeginRemoveVisualListener.OnBeginRemoveVisual(PendingRemoveVisual pr)
		{
			if (_args != null)
			{
				Fuse.Diagnostics.InternalError( "Double removal of Visual", this );
				return;
			}
			
			_args = pr;
			_args.AddSubscriber();
			Activate(OnDone);	
		}

		void OnDone()
		{
			if (_args == null)
			{
				Fuse.Diagnostics.InternalError( "Unexpected done", this );
				return;
			}
			
			_args.RemoveSubscriber();
			_args = null;
		}

		protected override void OnUnrooted()
		{
			base.OnUnrooted();
			if (_args != null)
			{
				_args.RemoveSubscriber();
				_args = null;
			}
		}
	}
}

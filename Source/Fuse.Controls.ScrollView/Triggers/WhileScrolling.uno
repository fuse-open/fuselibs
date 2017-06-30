using Uno;
using Uno.Collections;
using Fuse;
using Fuse.Controls;
using Fuse.Triggers;
using Fuse.Elements;
using Fuse.Gestures;
using Uno.UX;

namespace Fuse.Triggers
{
	/**
		Active while the user is scrolling the parent @ScrollView.

			<ScrollView>
				<SolidColor ux:Name="scrollBg" Color="#2A2A2A"/>
				<StackPanel  ItemSpacing="15">
					<Each Count="30">
						<Rectangle  Width="200" Height="40" Color="#F0F1E7"/>
					</Each>
				</StackPanel>
				<WhileScrolling>
					<Change scrollBg.Color="#838383" Duration="0.5"/>
				</WhileScrolling>	
			</ScrollView>

		This example will change the @ScrollView background color while the user scrolls.
		The trigger will revert when the ScrollView stops, even if the user is still touching the screen.
	*/
	public class WhileScrolling : WhileTrigger
	{
		ScrollViewBase _scrollView;
		Element _parent;

		protected override void OnRooted()
		{
			base.OnRooted();
			_parent = Parent as Element;
			if (_parent == null)
			{
				Fuse.Diagnostics.UserError( "Parent must be an Element", this );
				return;
			}

			_scrollView = Parent.FindByType<ScrollViewBase>();
			if (_scrollView == null)
			{
				Fuse.Diagnostics.UserError( "WhileScrolling could not find a parent scrollable control.", this );
				return;
			}

			_scrollView.ScrollPositionChanged += OnScrollPositionChanged;
		}

		protected override void OnUnrooted()
		{

			if (_scrollView != null)
			{
				_scrollView.ScrollPositionChanged -= OnScrollPositionChanged;
			}
			_parent = null;
			_scrollView = null;
			base.OnUnrooted();
		}

		bool _isActive = false;
		int _prevFrameIndex = 0;

		void OnScrollPositionChanged(object sender, EventArgs args)
		{
			if (!_isActive)
			{
				_isActive = true;
				SetActive(true);
				UpdateManager.AddAction(OnUpdate);
			}
			_prevFrameIndex = UpdateManager.FrameIndex;
		}

		void OnUpdate()
		{
			if (_prevFrameIndex < UpdateManager.FrameIndex)
			{
				SetActive(false);
				_isActive = false;
				UpdateManager.RemoveAction(OnUpdate);
			}
		}
	}
}

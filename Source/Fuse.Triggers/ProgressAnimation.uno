using Uno;
using Uno.UX;

using Fuse.Animations;

namespace Fuse.Triggers
{
	public interface IProgress
	{
		double Progress { get; }
		event ValueChangedHandler<double> ProgressChanged;
	}

	/**
		Triggers when a @Slider or other compatible control changes its value.

		ProgressAnimation can be used together with a slider to animate
		elements as one slides its thumb. ProgressAnimation always goes from
		0 to 1 as one slides the slider from its minimum value to its maximum
		value.

		## Example

		This example shows a slider, and blurs the slider itself with the
		blur-radius taken from the slider-value:

			<Panel Color="Black">
				<Slider>
					<Blur ux:Name="blur" Radius="0"/>
					<ProgressAnimation>
						<Change blur.Radius="10"/>
					</ProgressAnimation>
				</Slider>
			</Panel>
			
		## Compatible controls
		
		ProgressAnimation works with classes that implement `Fuse.Triggers.IProgress`.
		
		[subclass Fuse.Triggers.IProgress]
	*/
	public class ProgressAnimation : Trigger
	{
		IProgress FindIProgress()
		{
			var p = Parent;
			while (p != null && !(p is IProgress)) p = p.Parent;
			return p as IProgress;
		}

		IProgress _source;

		/**
			The source of the progress

			If Source is not set, the ancestry is searched for a suitable source
			instead.
		*/
		public IProgress Source
		{
			get { return _source; }
			set
			{
				DeinitProgress();
				_source = value;
				InitProgress();
			}
		}
		
		IProgress _progress;
		double _prevValue;
		protected override void OnRooted()
		{
			base.OnRooted();

			InitProgress();
		}

		protected override void OnUnrooted()
		{
			DeinitProgress();

			base.OnUnrooted();
		}

		void InitProgress()
		{
			_progress = Source ?? FindIProgress();
			if (_progress != null)
			{
				_progress.ProgressChanged += OnChanged;
				_prevValue = _progress.Progress;
				BypassSeek(_prevValue);
			}
		}

		void DeinitProgress()
		{
			if (_progress != null)
			{
				_progress.ProgressChanged -= OnChanged;
				_progress = null;
			}
		}

		void OnChanged(object s, object a)
		{
			var p = _progress.Progress;
			var diff = p - _prevValue;
			_prevValue = p;

			Seek(p, diff >= 0 ? AnimationVariant.Forward : AnimationVariant.Backward);
		}
	}

}

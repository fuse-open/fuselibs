using Uno;
using Uno.Collections;

namespace Fuse.Reactive
{
	/** Using this class directly is unusual. `ComputeExpression` is the preferred option for functions, and `ExpressionListener` for when that doesn't apply.
	
		Relying on this behaviour is bad. The Observable support was only intended for bindings. All other 
		values should use IExpression's facilities. The unintended support may be removed in the future.

		Implements `IListener`, and forward incoming values to the protected `OnNewData` method.
		If the incoming value is an observable, a subscription is created and the value of that observable
		is forwarded to the `OnNewData` method instead.

		Extenders should override `OnNewData()`, `OnLostData` and `Dispose()`.
		
		@hide
	*/
	public abstract class InnerListener: IDisposable, IListener
	{
		protected abstract void OnNewData(IExpression source, object value);
		protected abstract void OnLostData(IExpression source);

		IDisposable _diag;

		public void SetDiagnostic(string message, object source)
		{
			ClearDiagnostic();
			_diag = Diagnostics.ReportTemporalUserWarning(message, source);
		}

		public void ClearDiagnostic()
		{
			if (_diag != null)
			{
				_diag.Dispose();
				_diag = null;
			}
		}

		public virtual void Dispose()
		{
			ClearDiagnostic();

			if (_obsSubs != null)
			{
				foreach (var k in _obsSubs.Values) k.Dispose();
				_obsSubs.Clear();
				_obsSubs = null;
			}
		}

		Dictionary<IExpression, ObservableSubscription> _obsSubs;

		void IListener.OnNewData(IExpression source, object value)
		{
			ObservableSubscription obsSub = null;
			if (_obsSubs != null && _obsSubs.TryGetValue(source, out obsSub))
			{
				obsSub.Dispose();
				_obsSubs.Remove(source);
			}

			var obs = value as IObservable;
			if (obs != null)
			{
				// Special case for IObservable which can be interpreted as a single value
				if (_obsSubs == null) _obsSubs = new Dictionary<IExpression, ObservableSubscription>();
				_obsSubs.Add(source, new ObservableSubscription(source, obs, this));
			}
			else
			{
				OnNewData(source, value);
			}
		}
		
		void IListener.OnLostData(IExpression source)
		{
			OnLostData(source);
		}

		class ObservableSubscription: ValueObserver
		{
			InnerListener _listener;
			IExpression _source;

			public ObservableSubscription(IExpression source, IObservable obs, InnerListener listener)
			{
				_listener = listener;
				_source = source;
				Subscribe(obs);
			}

			public override void Dispose()
			{
				base.Dispose();
				_source = null;
				_listener = null;
			}

			protected override void PushData(object newValue)
			{
				_listener.OnNewData(_source, newValue);
			}
			
			protected override void LostData()
			{
				_listener.OnLostData(_source);
			}
		}
	}
}
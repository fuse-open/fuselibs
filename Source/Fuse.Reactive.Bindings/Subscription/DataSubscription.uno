using Uno;
using Uno.Collections;

namespace Fuse.Reactive
{
	class DataSubscription: Node.DataFinder, IDisposable, Node.IDataListener, IPropertyObserver, IWriteable
	{
		IExpression _source;
		Node _origin;
		IListener _listener;
		IDisposable _diag;

		public DataSubscription(IExpression source, Node origin, string key, IListener listener): base(key)
		{
			_source = source;
			_origin = origin;
			_listener = listener;

			_origin.AddDataListener(key, this);

			FindData();
		}

		bool _isResolved;

		void FindData()
		{
			if (_origin == null) return;

			ClearDiagnostic();
			_isResolved = false;
			_origin.EnumerateData(this); 

			if (!_isResolved)
				_diag = Diagnostics.ReportTemporalUserWarning("{" + Key + "} not found in data context", _origin);
		}

		object _currentData;
		IPropertySubscription _sub;

		void DisposeSubscription()
		{
			if (_sub != null)
			{
				_sub.Dispose();
				_sub = null;
			}
		}

		bool IWriteable.TrySetExclusive(object newValue)
		{
			var w = _sub as IPropertySubscription;
			if (w != null)
				return w.TrySetExclusive(Key, newValue);
			
			return false;
		}

		protected override void Resolve(IObject provider, object data)
		{
			DisposeSubscription();

			var obs = provider as IObservableObject;
			if (obs != null)
				_sub = obs.Subscribe(this);

			ResolveInner(data);
		}

		void IPropertyObserver.OnPropertyChanged(IDisposable sub, string propertyName, object newValue)
		{
			if (sub != _sub) return;
			if (propertyName != Key) return;
			ResolveInner(newValue);
		}

		void ResolveInner(object data)
		{
			_isResolved = true;
			if (data != _currentData)
			{
				_currentData = data;
				_listener.OnNewData(_source, data);
			}
		}

		public void Dispose()
		{
			DisposeSubscription();
			ClearDiagnostic();
			_origin.RemoveDataListener(Key, this);
			_origin = null;
			_source = null;
			_listener = null;
		}

		void Node.IDataListener.OnDataChanged()
		{
			FindData();
		}

		void ClearDiagnostic()
		{
			if (_diag != null)
			{
				_diag.Dispose();
				_diag = null;
			}
		}
	}
}

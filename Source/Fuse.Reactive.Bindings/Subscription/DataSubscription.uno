using Uno;
using Uno.Collections;

namespace Fuse.Reactive
{
	class DataSubscription: IDisposable, Node.IDataListener, IPropertyObserver, IWriteable
	{
		IExpression _source;
		Node _origin;
		IListener _listener;
		IDisposable _diag;
		string _key;
		Node.NodeDataSubscription _dataSub;

		public DataSubscription(IExpression source, Node origin, string key, IListener listener)
		{
			_key = key;
			_source = source;
			_origin = origin;
			_listener = listener;

			_dataSub = _origin.SubscribeData(key, this);
			FindData();
		}

		bool _isResolved = false;
		bool _hasData = false;

		void FindData()
		{
			if (_dataSub == null) return;

			ClearDiagnostic();
			DisposeSubscription();
			_isResolved = false;
			
			if (_dataSub.HasData)
			{
				var obs = _dataSub.Provider as IObservableObject;
				if (obs != null)
					_sub = obs.Subscribe(this);

				ResolveInner(_dataSub.Data);
			}
			else
			{
				_diag = Diagnostics.ReportTemporalUserWarning("{" + _key + "} not found in data context", _origin);
				if (_hasData)
				{
					_listener.OnLostData(_source);
					_hasData = false;
				}
			}
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
			{
				if (w.TrySetExclusive(_key, newValue))
				{
					_currentData = newValue;
					return true;
				}
			}

			return false;
		}

		void IPropertyObserver.OnPropertyChanged(IDisposable sub, string propertyName, object newValue)
		{
			if (sub != _sub) return;
			if (propertyName != _key) return;
			ResolveInner(newValue);
		}

		void ResolveInner(object data)
		{
			_isResolved = true;
			if (data != _currentData || !_hasData)
			{
				_hasData = true;
				_currentData = data;
				_listener.OnNewData(_source, data);
			}
		}

		public void Dispose()
		{
			DisposeSubscription();
			ClearDiagnostic();
			_origin = null;
			_source = null;
			_listener = null;
			if (_dataSub != null)
			{
				_dataSub.Dispose();
				_dataSub =  null;
			}
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

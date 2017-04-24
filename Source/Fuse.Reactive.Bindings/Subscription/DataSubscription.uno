using Uno;
using Uno.Collections;

namespace Fuse.Reactive
{
	class DataSubscription: Node.DataFinder, IDisposable, Node.IDataListener
	{
		IExpression _source;
		Binding _origin;
		IListener _listener;
		IDisposable _diag;

		public DataSubscription(IExpression source, Binding origin, string key, IListener listener): base(key)
		{
			_source = source;
			_origin = origin;
			_listener = listener;

			_origin.Parent.AddDataListener(key, this);

			FindData();
		}

		bool _isResolved;

		void FindData()
		{
			if (_origin == null) return;

			ClearDiagnostic();
			_isResolved = false;
			_origin.Parent.EnumerateData(this); 

			if (!_isResolved)
				_diag = Diagnostics.ReportTemporalUserWarning("{" + Key + "} not found in data context", _origin);
		}

		object _currentData;

		protected override void Resolve(object data)
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
			ClearDiagnostic();
			_origin.Parent.RemoveDataListener(Key, this);
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

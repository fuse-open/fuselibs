using Uno;
using Uno.UX;
using Fuse.Resources;

namespace Fuse.Reactive
{
	class ResourceSubscription: IDisposable
	{
		Node _origin;
		readonly string _key;
		readonly Type _type;
		IListener _listener;
		IExpression _source;
		IDisposable _diag;
		
		public ResourceSubscription(IExpression source, Node origin, string key, IListener listener, Type type)
		{
			_source = source;
			_origin = origin;
			_key = key;
			_type = type;
			_listener = listener;

			ResourceRegistry.AddResourceChangedHandler(_key, OnChanged);
			OnChanged();		
		}

		public void Dispose()
		{
			ClearDiagnostic();
			ResourceRegistry.RemoveResourceChangedHandler(_key, OnChanged);
			_listener = null;
			_origin = null;
		}

		void ClearDiagnostic()
		{
			if (_diag != null)
			{
				_diag.Dispose();
				_diag = null;
			}
		}

		void OnChanged()
		{
			ClearDiagnostic();

			object resource;
			if (_origin.TryGetResource(_key, Accept, out resource))
			{
				_listener.OnNewData(_source, resource);
			}
			else
			{
				_diag = Diagnostics.ReportTemporalUserWarning("{Resource " + _key + "} not found in data context", _origin);
			}
		}

		bool Accept(object o)
		{
			return Marshal.Is(o, _type);
		}
	}
}
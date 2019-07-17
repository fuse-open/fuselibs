using Uno.Collections;
using Uno.UX;

using Fuse.Reactive;

namespace Fuse.Charting
{
	public enum DataSeriesMetric
	{
		/** Values are interpreted as-is */
		Direct,
		/** Values are added to previous series and a range is constructed */
		Add,
	}
	
	/**
		Provides a source of data for plotting.
	*/
	public class DataSeries : PropertyObject, Fuse.Reactive.IObserver
	{
		Uno.IDisposable _subscription;
		IArray _rawData;
		IObservableArray _observableData;
		public IArray Data
		{
			get { return _rawData; }
			set 
			{
				ClearSubscription();
				_rawData = value;
				_observableData = value as IObservableArray;
				AddSubscription();
			}
		}
		
		List<Data> _data = new List<Data>();
		internal List<Data> PlotData 
		{
			get { return _data; }
		}
		
		DataSeriesMetric _metric = DataSeriesMetric.Direct;
		/**
			How the input values are interpreted.
		*/
		public DataSeriesMetric Metric
		{
			get { return _metric; }
			set
			{
				if (_metric == value)
					return;
			
				_metric = value;
				InvalidateData();
			}
		}
		
		void ClearSubscription()
		{
			if (_subscription != null)
			{
				_subscription.Dispose();
				_subscription = null;
			}
		}
		
		void AddSubscription()
		{
			if (_plot == null || _rawData == null)
				return;
				
			if (_observableData != null)
			{
				_subscription = _observableData.Subscribe(this);
				((IObserver)this).OnNewAll(_observableData);
			}
			else
				AddArrayData(_rawData);
		}
		
		void AddArrayData(IArray data)
		{
			for (int i=0; i < data.Length; ++i )
				AddDataObject(data[i]);
			InvalidateData();
		}
		
		void AddDataObject(object a)
		{
			InsertDataObject(_data.Count, a);
		}

		float SafeMarshalFloat(object a)
		{
			double value;
			if (Marshal.TryToDouble(a, out value))
			{	
				float v = (float)value;
				if (Uno.Float.IsNaN(v) || Uno.Float.IsInfinity(v))
				{
					Fuse.Diagnostics.UserError( "Invalid floating point value: " + value, this );
					return 0;
				}
				
				return v;
			}
			
			Fuse.Diagnostics.UserError( "Invalid floating point value: " + a, this );
			return 0;
		}
		
		void InsertDataObject(int index, object a)
		{
			var iobj = a as IObject;
			if (iobj != null)
			{
				var d = new Data();
				var val = float4(0);
				if (iobj.ContainsKey("x"))
					val.X = SafeMarshalFloat(iobj["x"]);
				if (iobj.ContainsKey("y"))
					val.Y = SafeMarshalFloat(iobj["y"]);
				else if (iobj.ContainsKey("value"))
					val.Y = SafeMarshalFloat(iobj["value"]);
				if (iobj.ContainsKey("z"))
					val.Z = SafeMarshalFloat(iobj["z"]);
				if (iobj.ContainsKey("w"))
					val.W = SafeMarshalFloat(iobj["w"]);
				d.SourceValue = val;
				
				if (iobj.ContainsKey("label"))
					d.Label = Marshal.ToType<string>(iobj["label"]);
					
				d.SourceObject = iobj;
				d.Behavior = _plot;
				_data.Insert(index, d);
				return;
			}

			var value = SafeMarshalFloat(a);
			var vd = new Data();
			vd.SourceValue = float4(0,(float)value,0,0);
			vd.Behavior = _plot;
			_data.Insert(index, vd);
		}
		
		void IObserver.OnClear()
		{
			_data.Clear();
			InvalidateData();
		}
		
		void IObserver.OnNewAll(IArray values)
		{
			_data.Clear();
			for (int i=0; i < values.Length; ++i)
				AddDataObject(values[i]);
			InvalidateData();
		}
		
		void IObserver.OnNewAt(int index, object newValue)
		{
			_data.RemoveAt(index);
			InsertDataObject(index, newValue);
			InvalidateData();
		}
		
		void IObserver.OnSet(object newValue)
		{
			_data.Clear();
			AddDataObject(newValue);
			InvalidateData();
		}
		
		void IObserver.OnAdd(object addedValue)
		{
			AddDataObject(addedValue);
			InvalidateData();
		}
		
		void IObserver.OnRemoveAt(int index)
		{
			_data.RemoveAt(index);
			InvalidateData();
		}
		
		void IObserver.OnInsertAt(int index, object value)
		{
			InsertDataObject(index, value);
			InvalidateData();
		}
		
		void IObserver.OnFailed(string message)
		{
			_data.Clear();
			Fuse.Diagnostics.InternalError( "Error on the SourceData", this );
			InvalidateData();
		}
		
		PlotBehavior _plot;
		void InvalidateData()
		{
			if (_plot != null)
				_plot.InvalidateData();
		}
		
		internal void Root( PlotBehavior plot )
		{
			_plot = plot;
			AddSubscription();
		}
		
		internal void Unroot()
		{
			ClearSubscription();
			for (int i=0; i < _data.Count; ++i)
				_data[i].Behavior = null;
			_data.Clear();
		}

		static DataStats Empty = new DataStats();
		//updated by PlotBehavior when the stats are recalculated
		internal DataStats Stats = Empty; //ensure it's never null
	}
}

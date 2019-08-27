using Uno;
using Uno.UX;

using Fuse.Reactive;

namespace Fuse.Charting
{
	/**
		Used to access information about the plot.
		
		The prefix `data.` is used within a @PlotData to access the values of the individual points on the plot.
		
		The prefix `axis.` is used within a @PlotAxis to access the values of axis.
		
		Unprefixed values access values in the @Plot
	*/
	[UXUnaryOperator("Plot")]
	public sealed class PlotExpression : Fuse.Reactive.Expression
	{
		string Identifier { get; private set; }
		string _idObject;
		string _idProperty;
		Field _field;
		
		static char[] _tokenSplit = new[]{'.'};

		enum Field
		{
			None,
			X,
			Y,
			Z,
			W,
		}
		
		[UXConstructor]
		public PlotExpression([UXParameter("Identifier")] string identifier)
		{
			Identifier = identifier;
			var parts = Identifier.Split( _tokenSplit );
			_idObject = parts.Length > 0 ? parts[0] : null;
			_idProperty = parts.Length > 1 ? parts[1] : null;
			var field = parts.Length > 2 ? parts[2] : null;
			
			//if not a known prefix then assume plot was meant
			if (_idObject != _dataPrefix && _idObject != _axisPrefix)
			{
				field = _idProperty;
				_idProperty = _idObject;
				_idObject = _plotPrefix;
			}
			
			if (field == null)
				_field = Field.None;
			else if (field == "x")
				_field = Field.X;
			else if (field == "y")
				_field = Field.Y;
			else if (field == "z")
				_field = Field.Z;
			else if (field == "w")
				_field = Field.W;
			else
			{
				_field = Field.None;
				Fuse.Diagnostics.UserError( "Unrecognized field: " + field, this );
			}
				
		}
		
		const string _dataPrefix = "data";
		const string _axisPrefix = "axis";
		const string _plotPrefix = "plot";
		
		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			if (_idObject == _dataPrefix)
				return new PlotDataSubscription<PlotDataPoint>(this, context.Node, _idProperty, _field, listener);
				
			if (_idObject == _axisPrefix)
				return new PlotDataSubscription<AxisEntry>(this, context.Node, _idProperty, _field, listener);
					
			//_idObject == _plotPrefix  (guaranteed by ctor)
			var plot = PlotBehavior.FindPlot(context.Node);
			if (plot == null)
			{
				Fuse.Diagnostics.UserError( "Could not find a Plot", this );
				return null;
			}

			return new PlotSubscription(this, plot, _idProperty, _field, listener);
		}
		
		static object AccessField( Field f, object value )
		{
			try
			{
				switch (f)
				{
					case Field.None: return value;
					case Field.X: return LenientToFloat4(value).X;
					case Field.Y: return LenientToFloat4(value).Y;
					case Field.Z: return LenientToFloat4(value).Z;
					case Field.W: return LenientToFloat4(value).W;
				}
			}
			catch (MarshalException e)
			{
				Fuse.Diagnostics.UserError( "Invalid field and/or conversion: " + f, value );
			}
			
			return null;
		}
		
		static float4 LenientToFloat4(object value)
		{
			//to allow "stepCount" to work
			if (value is Uno.Int4)
			{
				var o = (Uno.Int4)value;
				return float4(o.X,o.Y,o.Z,o.W);
			}
			
			return Marshal.ToFloat4(value);
		}
		
		class PlotDataSubscription<T> : IDisposable, IPlotDataItemListener<T> where T : IPlotDataItem
		{
			PlotExpression _expr;
			IListener _listener;
			string _key;
			PlotDataItemWatcher<T> _watcher;
			Field _field;
			
			public PlotDataSubscription(PlotExpression expr, Node origin, string key, Field field, IListener listener)
			{
				_expr = expr;
				_listener = listener;
				_key = key;
				_field = field;
				_watcher = new PlotDataItemWatcher<T>(origin, this);
			}
			
			public void Dispose()
			{
				_expr = null;
				_listener = null;
				_watcher.Dispose();
				_watcher = null;
			}
			
			void IPlotDataItemListener<T>.OnNewData(T entry)
			{
				var q = entry[_key];
				if (q != null)
					_listener.OnNewData(_expr, AccessField(_field, q));
			}
		}
		
		class PlotSubscription : IDisposable
		{
			PlotExpression _expr;
			PlotBehavior _plot;
			Selector _key;
			Field _field;
			IListener _listener;
			
			public PlotSubscription(PlotExpression expr, PlotBehavior plot, Selector key, Field field, IListener listener)
			{
				_expr = expr;
				_plot = plot;
				_key = key;
				_field = field;
				_listener = listener;
				_plot.DataChanged += OnDataChanged;
				
				PushValue();
			}
			
			public void Dispose()
			{
				_expr = null;
				_listener = null;
				_plot.DataChanged -= OnDataChanged;
				_plot = null;
			}
			
			void OnDataChanged(object s, object a)
			{
				PushValue();
			}
			
			void PushValue()
			{
				var q = GetValue();
				if (q == _undefined)
					_listener.OnNewData(_expr, null);
				else if (q != null)
					_listener.OnNewData(_expr, AccessField(_field, q));
				else
					Fuse.Diagnostics.UserError( "Unrecognizied Plot Identifier: " + _key, this );
			}
			
			class UndefinedObject { }
			static object _undefined = new UndefinedObject();
			
			static Selector CountName = "count";
			static Selector HasNextName = "hasNext";
			static Selector HasPrevName = "hasPrev";
			static Selector OffsetName = "offset";
			static Selector DataMinlineName = "dataMinline";
			static Selector DataMaxlineName = "dataMaxline";
			static Selector BaselineName = "baseline";
			static Selector StepsName = "stepCount";
			
			object GetValue()
			{
				if (_key == CountName)
					return _plot.PlotStats.Count;
				if (_key == HasNextName)
					return (_plot.Offset + _plot.Limit) < _plot.DataStats.Count;
				if (_key == HasPrevName)
					return _plot.Offset > 0;
				if (_key == OffsetName)
					return _plot.Offset;
					
				//these items are undefined if there is no data (important for animation)
				if (_plot.PlotStats.Count == 0 && (_key == BaselineName || _key == DataMaxlineName ||
					_key == DataMinlineName || _key == StepsName ))
					return _undefined;
					
				if (_key == BaselineName )
					return _plot.PlotStats.Baseline;
					
				if (_key == DataMaxlineName )
					return _plot.ScreenValue(_plot.PlotStats.GetRelativeValue( _plot.DataStats.Maximum ));
						
				if (_key == DataMinlineName )
					return _plot.ScreenValue(_plot.PlotStats.GetRelativeValue( _plot.DataStats.Minimum ));
			
				if (_key == StepsName)
					return _plot.ScreenSteps(_plot.PlotStats.Steps);
					
				return null;
			}
		}
	}
}
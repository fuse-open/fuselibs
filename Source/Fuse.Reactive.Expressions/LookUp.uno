using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Reactive
{
	/** Represents a reactive look-up operation, with a computed index (number) or key (string).

		Index can be either a number (for IArray lookups) or a string (for IObject lookups).

		Diagnostic erros are reported in the following cases:
		* If the collection is an `IArray` and the index is not convertible to a number.
		* If the collection is an `IArray` and the index is not within the bounds of the array.
		* If the colleciton is an `IObject` and the key is not present in the object.
		* If the collection is neither an `IArray` or `IObject`.
	 */
	public sealed class LookUp: Expression
	{
		public Expression Collection { get; private set; }
		public Expression Index { get; private set; }

		[UXConstructor]
		public LookUp([UXParameter("Collection")] Expression collection, [UXParameter("Index")] Expression index)
		{
			Collection = collection;
			Index = index;
		}

		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			return new LookUpSubscription(this, context, listener);
		}

		sealed class LookUpSubscription: IDisposable, IObserver, IListener, ValueForwarder.IValueListener, IPropertyObserver
		{
			IListener _listener;
			LookUp _lu;

			IDisposable _colSub;
			IDisposable _indexSub;

			public LookUpSubscription(LookUp lu, IContext context, IListener listener)
			{
				_listener = listener;
				_lu = lu;
				_colSub = _lu.Collection.Subscribe(context, this);
				_indexSub = _lu.Index.Subscribe(context, this);
			}

			bool _hasCollection;
			object _collection;
			bool _hasIndex;
			object _index;

			public void OnNewData(IExpression source, object value)
			{
				if (_lu == null) return;
				if (source == _lu.Index) NewIndex(value);
				if (source == _lu.Collection) NewCollection(value);
			}

			IDisposable _indexForwarder;
			void NewIndex(object ind)
			{
				DisposeIndexSub();

				var obs = ind as IObservable;
				if (obs != null)
				{
					// Special case for when index is an IObservable 
					_indexForwarder = new ValueForwarder(obs, this);
				}
				else
				{
					_index = ind;
					_hasIndex = true;
					ResultChanged();
				}
			}

			IDisposable _diag;

			public void SetDiagnostic(string message, IExpression source)
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

			void ValueForwarder.IValueListener.NewValue(object value)
			{
				_index = value;
				_hasIndex = true;
				ResultChanged();
			}

			void DisposeIndexSub()
			{
				if (_indexForwarder != null)
				{
					_indexForwarder.Dispose();
					_indexForwarder = null;
				}
			}

			void DisposeCollectionObservableObjectSub()
			{
				if (_colObsObjSub != null)
				{
					_colObsObjSub.Dispose();
					_colObsObjSub = null;
				}
			}

			IDisposable _colObsObjSub;
			IDisposable _colObservableSub;
			void NewCollection(object col)
			{
				_collection = col;
				_hasCollection = true;

				DisposeCollectionObservableObjectSub();
				DisposeCollectionObservableSub();

				var obs = col as IObservableArray;
				if (obs != null) 
					// Special case for when the collection is an IObservableArray
					_colObservableSub = obs.Subscribe(this);

				ResultChanged();
			}

			void DisposeCollectionObservableSub()
			{
				if (_colObservableSub != null)
				{
					_colObservableSub.Dispose();
					_colObservableSub = null;
				}
			}

			

			void ResultChanged()
			{
				if (_listener == null) return;
				ClearDiagnostic();

				if (!_hasIndex) return;
				if (!_hasCollection) return;
				if (_index == null || _collection == null) PushNewData(null);

				var arr = _collection as IArray;
				if (arr != null)
				{
					int index = 0;
					try
					{
						index = Marshal.ToInt(_index);
					}
					catch (MarshalException me)
					{
						SetDiagnostic("Index must be a number: " + me.Message, _lu.Index);
						return;
					}

					if (index >= 0 && index < arr.Length)
					{
						PushNewData(arr[index]);
					}
					else
					{
						SetDiagnostic("Index was outside the bounds of the array", _lu.Index);
					}
					return;
				}

				var obj = _collection as IObject;
				if (obj != null)
				{
					var obsObj = obj as IObservableObject;
					if (obsObj != null)
						_colObsObjSub = obsObj.Subscribe(this);

					var key = _index.ToString();
					if (obj.ContainsKey(key))
					{
						PushNewData(obj[key]);
					}
					else
					{
						SetDiagnostic("Object does not contain the given key '" + key + "'", _lu.Index);
					}
					return;
				}

				SetDiagnostic("Look-up operator not supported on collection type: " + _collection, _lu.Collection);
			}

			void IPropertyObserver.OnPropertyChanged(IDisposable sub, string propertyName, object newValue)
			{
				if (sub != _colObsObjSub) return;
				if (propertyName != _index.ToString()) return;
				PushNewData(newValue);
			}

			void PushNewData(object value)
			{
				_listener.OnNewData(_lu, value);
			}

			public void Dispose()
			{
				ClearDiagnostic();
				DisposeCollectionObservableObjectSub();
				DisposeCollectionObservableSub();
				DisposeIndexSub();

				if (_colSub != null)
					_colSub.Dispose();

				if (_indexSub != null)
					_indexSub.Dispose();

				_colSub = null;
				_indexSub = null;
				_collection = null;
				_listener = null;
				_index = null;
				_lu = null;
			}

			void IObserver.OnClear(){ ResultChanged(); }
			void IObserver.OnSet(object newValue){ ResultChanged(); }
			void IObserver.OnAdd(object addedValue){ ResultChanged(); }
			void IObserver.OnNewAt(int index, object value){ ResultChanged(); }
			void IObserver.OnFailed(string message){ ResultChanged(); }
			void IObserver.OnNewAll(IArray values){ ResultChanged(); }
			void IObserver.OnRemoveAt(int index){ ResultChanged(); }
			void IObserver.OnInsertAt(int index, object value){ ResultChanged(); }		
		}
	}
}

using Uno;
using Uno.UX;
using Fuse.Triggers;

namespace Fuse.Reactive
{
	[Flags]
	public enum BindingMode
	{
		Read = 1,
		Write = 2,
		Clear = 4,
		ReadClear = Read | Clear,
		WriteClear = Write | Clear,
		ReadWriteClear = Read | Write | Clear,
		ReadWrite = Read | Write,
		Default = ReadWrite
	}

	[UXValueBindingAlias("Data")]
	/** 
		Data bindings allow you to bind properties on UX markup objects to values coming from
		a @JavaScript or other data context.

		@topic Data binding

		Data bindings are most easily expressed in UX Markup using the `{expression}` syntax, where `expression` is
		the binding path, like so:

			<Text Value="{textKey}" />

		Data bindings can also be declared explicitly. Explicit databindings allow you
		to specify a default value that is used before the data binding is resolved:

			<Panel ux:Name="panel1" Width="100" />
			<DataBinding Target="panel1.Width" Key="panelWidth" />

		> Note: The expression passed to `Key` in explicit mode is by default in the data scope. To reference global names, escape it using `{= }`
		
		The above code will use `100` as the default value for `panel1.Width` until the `panelWidth`
		data is resolved.

		@remarks Docs/DataBindingRemarks.md
	*/
	public class DataBinding: ExpressionBinding, IObserver, INameListener, IPropertyListener
	{
		[UXValueBindingTarget]
		public Uno.UX.Property Target { get; private set; }

		BindingMode _mode;

		[UXConstructor]
		public DataBinding(
			[UXParameter("Target")] Uno.UX.Property target, 
			[UXParameter("Key"), UXDataScope] IExpression key, 
			[UXParameter("Mode"), UXDefaultValue("Default")] BindingMode mode): base(key)
		{
			_mode = mode;
			Target = target;
		}

		public override IDisposable SubscribeResource(IExpression source, string key, IListener listener)
		{
			return new ResourceSubscription(source, Parent, key, listener, Target.PropertyType);
		}

		bool Read { get { return _mode.HasFlag(BindingMode.Read); } }
		bool Write { get { return _mode.HasFlag(BindingMode.Write); } }
		bool Clear { get { return _mode.HasFlag(BindingMode.Clear); } }

		void IObserver.OnClear()
		{
			ClearValue();
		}

		void IObserver.OnSet(object newValue)
		{
			PushValue(newValue);
		}

		static string TypeToJSName(Type t) 
		{
			if (t == typeof(int) || t == typeof(float) || t == typeof(double)) return "number";
			if (t == typeof(string)) return "string";
			return "value that can be converted to type " + t.FullName;
		}

		void InvalidListOperation()
		{
			Diagnostics.UserError("Cannot bind '" + Key + "' to property '" + Target.Name + "'. The observable must contain exactly one " + TypeToJSName(Target.PropertyType) + ".", this);
		}

		void IObserver.OnAdd(object addedValue)
		{
			InvalidListOperation();
		}

		void IObserver.OnNewAt(int index, object value)
		{
			InvalidListOperation();
		}

		void IObserver.OnFailed(string message)
		{
			ClearValue();
			MarkFailed(message);
		}

		void IObserver.OnNewAll(IArray values)
		{
			if (values.Length > 0)
				InvalidListOperation();
		}

		void IObserver.OnRemoveAt(int index)
		{
			InvalidListOperation();
		}

		void IObserver.OnInsertAt(int index, object value)
		{
			InvalidListOperation();
		}
		
		protected override void OnRooted()
		{
			base.OnRooted();

			if (Write && Target.SupportsOriginSetter) Target.AddListener(this);
		}

		BusyTask _busyTask;
		void MarkFailed(string message)
		{
			BusyTask.SetBusy( Parent, ref _busyTask, BusyTaskActivity.Failed, message );
		}
		
		void ClearFailed()
		{
			if (Parent != null)
				BusyTask.SetBusy( Parent, ref _busyTask, BusyTaskActivity.None );
		}
		
		protected override void OnUnrooted()
		{
			ClearFailed();
			UnlistenNameRegistry();

			if (Write && Target.SupportsOriginSetter) Target.RemoveListener(this);

			if (_subscription != null)
			{
				_subscription.Dispose();
				_subscription = null;
			}
		
			ClearValue();
			base.OnUnrooted();
		}
		
		internal void SetTarget( object value )
		{
			ClearFailed();
			Target.SetAsObject(value, this);
		}
		
		void ClearValue()
		{
			if (Clear) SetTarget(null);
		}

		void INameListener.OnNameChanged(Node obj, Selector name)
		{
			PushValue(_currentValue);
		}

		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector prop)
		{
			if (prop == Target.Name)
			{
				if (_subscription != null)
				{
					if (Write) 
					{
						var sub = _subscription as ISubscription;
						if (sub != null) sub.SetExclusive(Target.GetAsObject());
					}
				}
				else if (CanWriteBack)
				{
					WriteBack(Target.GetAsObject());
				}
			}
		}

		IDisposable _subscription;

		internal override void NewValue(object value)
		{
			if (_subscription != null)
			{
				_subscription.Dispose();
				_subscription = null;
			}
			
			if (Marshal.Is(value, Target.PropertyType))
			{
				// Note - this case is required in addition to the final 'else', because if the target
				// property accepts the observable object, we should not create a subscription, but pass it
				// directly to the target

				PushValue(value);
			}
			else if (Marshal.Is(value, typeof(IObservable)))
			{
				// Special treatment for the IObservable interface - see docs on IObservable for rationale
				var obs = (IObservable)value;
				if (obs.Length > 0) PushValue(obs[0]);
				_subscription = obs.Subscribe(this);
			}
			else
			{
				PushValue(value);
			}
		}

		object _currentValue;

		protected virtual void PushValue(object newValue)
		{
			if (!Read) return;
			if (Parent == null) return;

			_currentValue = newValue;

			if (TryPushAsValue(newValue)) return;
			else if (TryPushAsName(newValue)) return;
			else TryPushAsMarshalledValue(newValue);
		}

		bool TryPushAsValue(object newValue)
		{
			if (Marshal.Is(newValue, Target.PropertyType))
			{
				UnlistenNameRegistry();
				SetTarget(newValue);
				return true;
			}

			return false;
		}

		string _registryName;
		void UnlistenNameRegistry()
		{
			if (_registryName != null)
			{
				NameRegistry.RemoveListener(_registryName, this );
				_registryName = null;
			}
		}
		
		bool TryPushAsName(object newValue)
		{
			var name = ToSelector(newValue);

			if (!name.IsNull)
			{
				UnlistenNameRegistry();
				_registryName = name;
				NameRegistry.AddListener(_registryName, this);

				var k = Parent.FindNodeByName(name, Acceptor);
				if (k != null)
				{
					SetTarget(k);
					return true;
				}

				// Unable to resolve node
				if (Target.PropertyType.IsClass && !Marshal.CanConvertClass(Target.PropertyType)) 
				{
					// TODO: this gives a lot of false positives if the tree isn't fully populated yet.
					//debug_log("Warning: Data binding failed. No object named '" + name + "' of type " + typeof(T) + " found");
					return true;
				}
			}

			return false;
		}

		static Selector ToSelector(object newValue)
		{
			return
				newValue is Selector ? (Selector)newValue : 
				newValue is string ? new Selector((string)newValue) : default(Selector);
		}

		bool Acceptor(object obj)
		{
			return Marshal.Is(obj, Target.PropertyType);
		}

		void TryPushAsMarshalledValue(object newValue)
		{
			object res;

			if (Marshal.TryConvertTo(Target.PropertyType, newValue, out res, this))
			{
				try
				{
					SetTarget(res);
				}
				catch (Exception e)
				{
					MarkFailed(e.ToString());
					Fuse.Diagnostics.UserError(e.ToString(), Target);
				}
			}
		}
	}

	public class PropertyBinding: DataBinding
	{
		[UXConstructor]
		public PropertyBinding([UXParameter("Target")] Uno.UX.Property target, [UXParameter("Source")] Uno.UX.Property source) 
			: base(target, new Reactive.Property(new Constant(source.Object), source), BindingMode.Default) {}
	}

	public class ResourceBinding: DataBinding
	{
		[UXConstructor]
		public ResourceBinding([UXParameter("Target")] Uno.UX.Property target, [UXParameter("Key")] string key) 
			: base(target, new Reactive.Resource(key), BindingMode.Default) {}
	}

	
}

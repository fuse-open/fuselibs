using Uno;
using Uno.UX;
using Uno.Collections;
using Uno.Compiler;
using Fuse.Scripting;
using Uno.Testing;
using Uno.Threading;

namespace Fuse.Reactive
{
	public partial class JavaScript
	{
		public class Dependency : IListener
		{
			internal string Name { get; private set; }
			internal IExpression Expression { get; private set; }

			[UXConstructor]
			public Dependency([UXParameter("Name")] string name, [UXParameter("Expression")] IExpression expression)
			{
				Name = name;
				Expression = expression;
			}

			JavaScript _script;
			IDisposable _expSubscription;

			internal void Subscribe(JavaScript script)
			{
				Unsubscribe();
				_script = script;
				_expSubscription = Expression.Subscribe(script, this);
			}

			internal void Unsubscribe()
			{
				if (_expSubscription != null)
				{
					_expSubscription.Dispose();
					_expSubscription = null;
				}
				Value = null;
				HasValue = false;
				_script = null;
			}

			internal bool HasValue;
			internal object Value;

			void IListener.OnNewData(IExpression source, object data)
			{
				if (_script == null) return;

				Value = data;
				HasValue = true;

				_script.DispatchEvaluateIfDependenciesReady();
			}
		}


   		List<Dependency> _dependencies;
		/** A list of named expressions that will be evaluated and injected as variables into the script.
		
			This property allows injecting dependencies defined as UX expressions into the script using the `dep:` XML namespace.
			
			Example:

				<JavaScript>
					exports.foo = 123
				</JavaScript>
				<JavaScript dep:foo="{foo}">
					foo // this is now 123
				</JavaScript>

			A script is not executed until all of its dependencies are available. If any of the dependencies change, the script is re-executed.

			This has multiple use-cases:
			* Accessing data from data context `dep:foo="{foo}"`
			* Accessing properties synchronously `dep:SomeProp="{Property SomeProp}"`
		*/
		public IList<Dependency> Dependencies 
		{ 
			get 
			{
				if (_dependencies == null) 
					_dependencies = new List<Dependency>();

				return _dependencies; 
			} 
		}

		void SubscribeToDependenciesAndDispatchEvaluate() 
		{
			if (_dependencies != null) 
				for (var i = 0; i < _dependencies.Count; i++)
					_dependencies[i].Subscribe(this);

			if (_dependencies == null || _dependencies.Count == 0) DispatchEvaluateIfDependenciesReady();
		}

		void DisposeDependencySubscriptions()
		{
			if (_dependencies != null) 
				for (var i = 0; i < _dependencies.Count; i++)
					_dependencies[i].Unsubscribe();
		}

		void DispatchEvaluateIfDependenciesReady()
		{
			if (_dependencies != null) 
				for (var i = 0; i < _dependencies.Count; i++)
					if (!_dependencies[i].HasValue) return;

			DispatchEvaluate();
		}

		ModuleInstance _moduleInstance;

		void OnReset()
		{
			if (IsRootingCompleted) DispatchEvaluate();
		}

		internal void DispatchEvaluate()
		{
			if (!IsRootingStarted) return;
			DisposeModuleInstance();
			_moduleInstance = new ModuleInstance(Worker, this);
		}

		void DisposeModuleInstance()
		{
			if (_moduleInstance != null)
			{
				_moduleInstance.Dispose();
				_moduleInstance = null;
			}
		}

		IDisposable IContext.Subscribe(IExpression source, string key, IListener listener)
		{
			return new DataSubscription(source, this, key, listener);
		}

		Node IContext.Node { get { return this; } }

		IDisposable IContext.SubscribeResource(IExpression source, string key, IListener listener)
		{
			return new ResourceSubscription(source, this, key, listener, typeof(object));
		}
	}
}
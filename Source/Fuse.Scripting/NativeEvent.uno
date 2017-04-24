using Uno;
using Uno.Collections;
using Uno.Threading;

namespace Fuse.Scripting
{
	public sealed class NativeEvent : NativeProperty<Scripting.Function, Scripting.Function>
	{
		Queue<object[]> _eventArgsQueue;
		bool _queueEventsBeforeEvaluation;
		Scripting.Function _jsFunction;

		public NativeEvent(string name, bool queueEventsBeforeHandlerIsSet = true) : base(name)
		{
			_eventArgsQueue = new Queue<object[]>();
			_queueEventsBeforeEvaluation = queueEventsBeforeHandlerIsSet;
		}
		
		protected override void SetProperty(Scripting.Function function)
		{
			_jsFunction = function;
			DispatchQueue();
		}
		
		protected override Scripting.Function GetProperty()
		{
			return _jsFunction;
		}

		void DispatchQueue()
		{
			while (_eventArgsQueue.Count > 0 && _jsFunction != null)
				Context.Dispatcher.Invoke1<object[], object>(_jsFunction.Call, _eventArgsQueue.Dequeue());
		}

		public void RaiseAsync(params object[] args)
		{
			if(Context != null || _queueEventsBeforeEvaluation)
				_eventArgsQueue.Enqueue(args);
			
			DispatchQueue();
		}

		internal object RaiseSync(params object[] args)
		{
			assert Context != null;
			if (_jsFunction != null)
				Context.Dispatcher.Invoke1<object[], object>(_jsFunction.Call, args);

			return null;
		}
	}
}

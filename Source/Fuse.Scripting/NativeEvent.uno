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

		protected override void SetProperty(Context context, Scripting.Function function)
		{
			_jsFunction = function;
			DispatchQueue(context.ThreadWorker);
		}

		protected override Scripting.Function GetProperty()
		{
			return _jsFunction;
		}

		void DispatchQueue(IThreadWorker threadWorker)
		{
			while (_eventArgsQueue.Count > 0 && _jsFunction != null)
				threadWorker.Invoke<object[]>(_jsFunction.CallDiscardingResult, _eventArgsQueue.Dequeue());
		}

		public void RaiseAsync(IThreadWorker threadWorker, params object[] args)
		{
			if(Context != null || _queueEventsBeforeEvaluation)
				_eventArgsQueue.Enqueue(args);

			DispatchQueue(threadWorker);
		}

		internal object RaiseSync(Context context, params object[] args)
		{
			if (_jsFunction != null)
				context.ThreadWorker.Invoke<object[]>(_jsFunction.CallDiscardingResult, args);

			return null;
		}
	}
}

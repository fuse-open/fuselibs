using Uno.Collections;

namespace Fuse.Text
{
	class SinglyLinkedList<T> : IEnumerable<T>
	{
		public T Value { get; private set; }
		public SinglyLinkedList<T> Next;

		public SinglyLinkedList(T value, SinglyLinkedList<T> next = null)
		{
			Value = value;
			Next = next;
		}

		public IEnumerator<T> GetEnumerator()
		{
			return new Enumerator(this);
		}

		public static SinglyLinkedList<T> FromEnumerable(IEnumerable<T> xs)
		{
			var before = new SinglyLinkedList<T>(default(T), null);
			var head = before;
			foreach (var x in xs)
			{
				head.Next = new SinglyLinkedList<T>(x, null);
				head = head.Next;
			}
			return before.Next;
		}

		class Enumerator : IEnumerator<T>
		{
			SinglyLinkedList<T> _beforeHead;
			SinglyLinkedList<T> _current;

			public Enumerator(SinglyLinkedList<T> list)
			{
				_beforeHead = new SinglyLinkedList<T>(default(T), list);
				Reset();
			}

			public T Current
			{
				get
				{
					return _current.Value;
				}
			}

			public void Reset()
			{
				_current = _beforeHead;
			}

			public bool MoveNext()
			{
				if (_current != null)
				{
					_current = _current.Next;
					return _current != null;
				}
				return false;
			}

			public void Dispose()
			{
				// Nothing to do
			}
		}
	}
}

using Uno;
using Uno.Collections;

namespace Fuse.Internal
{
    public class ReverseArrayEnumerable<T>: IEnumerable<T>
    {
        readonly T[] _arr;
        public ReverseArrayEnumerable(T[] arr)
        {
            _arr = arr;
        }
        public IEnumerator<T> GetEnumerator()
        {
            return new Enumerator(_arr);
        }

        class Enumerator: IEnumerator<T>
        {
            readonly T[] _arr;
            int _pos;
            public Enumerator(T[] arr)
            {
                _arr = arr;
                Reset();
            }

            public void Reset()
            {
                _pos = _arr.Length;
            }

            public bool MoveNext()
            {
                _pos--;
                return _pos >= 0;
            }

            public T Current
            {
                get { return _arr[_pos]; }
            }

            public void Dispose()
            {
            }
        }
    }
}
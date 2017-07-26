using Uno;
using Uno.Collections;
using Uno.Text;
using Uno.UX;

using Fuse.Internal;

namespace Fuse
{
	public partial class Visual
	{
        // Offers a fast but unsafe (as in doesn't deal correclty with changes) enumeration over 
        // exclusively the visual children of the visual.
        // This is only mean to interface with APIs that require IEnumerable<Visual> - for general
        // purpose enumeration, use FirstChild<Visual>() and NextSibling<Visual>()
        IEnumerator<Visual> IEnumerable<Visual>.GetEnumerator()
        {
            return new Enumerator<Visual>(this);
        }

        // Visual implements this interface itself to avoid creating an extra object
        internal IEnumerable<Visual> VisualChildren { get { return this; } }

        class Enumerator<T> : IEnumerator<T> where T: Node
        {
            Visual _parent;
            T _current;
            bool _reachedEnd;

            public Enumerator(Visual parent)
            {
                _parent = parent;
            }

            public bool MoveNext()
            {
                if (_reachedEnd) return false;

                if (_current == null) _current = _parent.FirstChild<T>();
                else _current = _current.NextSibling<T>();

                if (_current == null) _reachedEnd = true;
                return !_reachedEnd;
            }

            public T Current { get { return _current; } }
            public void Reset() { _current = null; _reachedEnd = false; } 
            public void Dispose() { Reset(); _parent = null;  }
        }
    }
}
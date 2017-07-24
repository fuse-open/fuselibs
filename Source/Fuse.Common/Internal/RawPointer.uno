using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Internal
{
    /** A reference that in C++ behaves just like a plain pointer. Faster than weakref, but not technically a weakref.

        This is unsafe to use. The user must take special care that a separate reference to the object
        exists before de-referencing an `RawPointer`.

        Used internally with special care in performance critical contexts.
    */
    [extern(CPLUSPLUS) TargetSpecificType]
    struct RawPointer<T> where T : class
    {
        extern(!CPLUSPLUS) readonly T _object;

        extern(!CPLUSPLUS) RawPointer(T obj) { _object = obj; }

        public static explicit operator T(RawPointer<T> weak)
        {
            if defined(CPLUSPLUS)
                return extern<T> "(uObject*) $0";
            else
                return weak._object;
        }

        public static implicit operator RawPointer<T>(T obj)
        {
            if defined(CPLUSPLUS)
                return extern<RawPointer<T>> "(void*) $0";
            else
                return new RawPointer<T>(obj);
        }
    }
}
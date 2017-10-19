using Uno;

namespace Fuse.Scripting
{
	public static class JSCallback
    {
        public static Callback FromAction(Action action)
        {
            return new ActionClosure(action).Run;
        }

        public static Callback FromAction<T>(Action<T> action)
        {
            return new ActionClosure<T>(action).Run;
        }
        
        public static Callback FromAction<T1, T2>(Action<T1, T2> action)
        {
            return new ActionClosure<T1, T2>(action).Run;
        }

        public static Callback FromFunc<TResult>(Func<TResult> func)
        {
            return new FuncClosure<TResult>(func).Run;
        }

        public static Callback FromFunc<T, TResult>(Func<T, TResult> func)
        {
            return new FuncClosure<T, TResult>(func).Run;
        }

        public static Callback FromFunc<T1, T2, TResult>(Func<T1, T2, TResult> func)
        {
            return new FuncClosure<T1, T2, TResult>(func).Run;
        }

        sealed class ActionClosure
        {
            readonly Action _action;

            public ActionClosure(Action action)
            {
                _action = action;
            }

            public object Run(Context context, object[] args)
            {
                _action();
                return null;
            }
        }

        sealed class ActionClosure<T>
        {
            readonly Action<T> _action;

            public ActionClosure(Action<T> action)
            {
                _action = action;
            }

            public object Run(Context context, object[] args)
            {
                T arg = default(T);
                if (GetArg(args, out arg, 0))
                    _action(arg);
                else
                    throw new ArgumentException("First argument should be of type " + typeof(T) + " value was " + args[0]);

                return null;
            }
        }

        sealed class ActionClosure<T1, T2>
        {
            readonly Action<T1, T2> _action;

            public ActionClosure(Action<T1, T2> action)
            {
                _action = action;
            }

            public object Run(Context context, object[] args)
            {
                T1 arg = default(T1);
                T2 arg1 = default(T2);
                if (GetArg(args, out arg, 0) && GetArg(args, out arg1, 1))
                    _action(arg, arg1);
                else
                    throw new ArgumentException("First argument should be of type " + typeof(T1));

                return null;
            }
        }

        sealed class FuncClosure<TResult>
        {
            readonly Func<TResult> _method;

            public FuncClosure(Func<TResult> method)
            {
                _method = method;
            }

            public object Run(Context context, object[] args)
            {
                return _method();
            }
        }

        sealed class FuncClosure<TArg, TResult>
         {
             readonly Func<TArg, TResult> _method;

             public FuncClosure(Func<TArg, TResult> method)
             {
                 _method = method;
             }

             public object Run(Context context, object[] args)
             {
                if(typeof(TArg) == typeof(object[])) return _method((TArg)args);

                TArg arg = default(TArg);
                if(GetArg(args, out arg, 0))
                    return _method(arg);

                throw new ArgumentException("First argument should be of type " + typeof(TArg));
             }
         }

        sealed class FuncClosure<TArg, TArg1, TResult>
        {
            readonly Func<TArg, TArg1, TResult> _method;

            public FuncClosure(Func<TArg, TArg1, TResult> method)
            {
                _method = method;
            }

            public object Run(Context context, object[] args)
            {
                TArg arg = default(TArg);
                TArg1 arg1 = default(TArg1);
                if (GetArg(args, out arg, 0) && GetArg(args, out arg1, 1))
                    return _method(arg, arg1);

                throw new ArgumentException("First argument should be of type " + typeof(TArg)); // TODO: error for all arguments
            }
        }

        static bool GetArg<T>(object[] args, out T arg, int index)
        {
            arg = default(T);
            if (args.Length > index)
            {
                if(NumberConverter.TryConvert<T>(args[index], out arg))
                    return true;
            }
            return false;
        }

        public static class NumberConverter
        {
            public static bool TryConvert<TValue>(object value, out TValue convertedValue)
            {
                convertedValue = default(TValue);
                try
                {
                    convertedValue = Convert<TValue>(value);
                    return true;
                }
                catch {}
                return false;
            }

            public static TValue Convert<TValue>(object value)
            {
                return (TValue)Convert(typeof(TValue), value);
            }

            public static object Convert(Type targetType, object value)
            {
                if (value is short) return Convert((short)value, targetType);
                if (value is int) return Convert((int)value, targetType);
                if (value is long) return Convert((long)value, targetType);
                if (value is float) return Convert((float)value, targetType);
                if (value is double) return Convert((double)value, targetType);
                return value;
            }

            static object Convert(short value, Type targetType)
            {
                if (targetType == typeof(int)) return (int)value;
                if (targetType == typeof(long)) return (long)value;
                if (targetType == typeof(float)) return (float)value;
                if (targetType == typeof(double)) return (double)value;
                return value;
            }

            static object Convert(int value, Type targetType)
            {
                if (targetType == typeof(short)) return (short)value;
                if (targetType == typeof(long)) return (long)value;
                if (targetType == typeof(float)) return (float)value;
                if (targetType == typeof(double)) return (double)value;
                return value;
            }

            static object Convert(long value, Type targetType)
            {
                if (targetType == typeof(short)) return (short)value;
                if (targetType == typeof(int)) return (int)value;
                if (targetType == typeof(float)) return (float)value;
                if (targetType == typeof(double)) return (double)value;
                return value;
            }

            static object Convert(float value, Type targetType)
            {
                if (targetType == typeof(short)) return (short)value;
                if (targetType == typeof(int)) return (int)value;
                if (targetType == typeof(long)) return (long)value;
                if (targetType == typeof(double)) return (double)value;
                return value;
            }

            static object Convert(double value, Type targetType)
            {
                if (targetType == typeof(short)) return (short)value;
                if (targetType == typeof(int)) return (int)value;
                if (targetType == typeof(long)) return (long)value;
                if (targetType == typeof(float)) return (float)value;
                return value;
            }
        }
    }
}
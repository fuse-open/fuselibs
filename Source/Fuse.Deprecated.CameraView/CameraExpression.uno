using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse;
using Fuse.Reactive;

namespace Fuse.Deprecated
{
    /** A Camera expression can be used to get meta-data about a device's Camera.
        Currently supported queries are `hasFront` and `hasBack`, used to identify available cameras.

        ```
            <App>
                <Text Value="{Camera hasFront}"/>
                <Text Value="{Camera hasBack"/>
            </App>
        ``` 
    */
    [UXUnaryOperator("Camera")]
    public sealed class CameraExpression: Fuse.Reactive.Expression
    {
        public Fuse.Reactive.Expression Value { get; private set; }
        private Subscription _sub;

        [UXConstructor]
        public CameraExpression([UXParameter("Value")] Fuse.Reactive.Expression key)
        {
            Value = key;
            _sub = null;
        }

        public override IDisposable Subscribe(IContext context, IListener listener)
        {
            if (_sub == null)
                _sub = new Subscription(this, context, listener);

            _sub.OnNewData(this, Value);

            return _sub;
        }

        class Subscription: IDisposable, IListener
        {
            CameraExpression _sf;
            bool _hasStartValue;
            IDisposable _valueSub;
            IListener _listener;

            public Subscription(CameraExpression sf, IContext context, IListener listener)
            {
                _sf = sf;
                _listener = listener;
                _valueSub = sf.Value.Subscribe(context, this);
            }

            public void Dispose()
            {
                if (_valueSub != null)
                    _valueSub.Dispose();

                _valueSub = null;
                _listener = null;
            }

            public void OnNewData(IExpression source, object value)
            {
                var v = value.ToString();

                if (v == "{hasFront}")
                    _listener.OnNewData(_sf, CameraDevice.SupportedDirections.Contains(CameraDirection.Front));
                else if (v == "{hasBack}")
                    _listener.OnNewData(_sf, CameraDevice.SupportedDirections.Contains(CameraDirection.Back));
                else 
                {
                    _listener.OnNewData(_sf, false);
                    Fuse.Diagnostics.UserError("Invalid value given to Camera expression.", v);
                } 
            }

            public void OnLostData(IExpression source)
            {
                // Deprecated API, so leave it doing nothing
            }
        }
    }

}

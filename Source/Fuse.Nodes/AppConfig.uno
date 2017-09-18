namespace Fuse
{
    /** Allows configuration of App.Background through data bindings .

        As the `App` class is not a `PropertyObject` and doesn't have a containing data context,
        properties like `Background` cannot be databound regularly. This behavior class
        allows you to do that from a specific data context.

        ## Example

            <App>
                ...
                <AppConfig Background="{foo}" />
    */
    public class AppConfig: Behavior
    {
        public float4 Background 
        {
            get { return AppBase.Current.Background; }
            set { AppBase.Current.Background = value; }
        }
    }
}
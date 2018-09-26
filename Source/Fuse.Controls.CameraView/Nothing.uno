namespace Fuse.Controls
{
    // Nothing, because we can't return void. Use default(Nothing), which is just null
    internal sealed class Nothing : object
    {
        // Should never be created
        private Nothing() {}
    }
}

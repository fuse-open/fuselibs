namespace Fuse.FileSystem
{
    // Nothing, because we can't return void. Use default(Nothing), which is just null
    public sealed class Nothing : object
    {
        // Should never be created
        private Nothing() {}
    }
}

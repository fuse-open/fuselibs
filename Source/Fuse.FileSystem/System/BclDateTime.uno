using Uno.Compiler.ExportTargetInterop;

namespace Fuse.FileSystem
{
    [extern(DOTNET) DotNetType("System.DateTime")]
    extern(DOTNET) internal struct BclDateTime
    {
        // get a compiler error if we don't have field defined
        extern private ulong dateData;

        extern public long Ticks { get; }
    }
}

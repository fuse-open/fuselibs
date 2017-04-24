using Uno.Compiler.ExportTargetInterop;

namespace Fuse.FileSystem
{
    [extern(DOTNET) DotNetType("System.IO.FileAttributes")]
    extern(DOTNET) internal enum BclFileAttributes
    {
    }
}

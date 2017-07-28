using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.FileSystem
{
    // This class must be removed when feature-FileSystemInfo branch is merged
    [extern(DOTNET) DotNetType("System.IO.FileSystemInfo")]
    extern(DOTNET) internal abstract class BclFileSystemInfo
    {
        public extern BclFileAttributes Attributes { get; }
        public extern void Refresh();
        public extern bool Exists { get; }
        public extern DateTime LastAccessTimeUtc { get; }
        public extern DateTime LastWriteTimeUtc { get; }
        public extern DateTime CreationTimeUtc { get; }
    }
}

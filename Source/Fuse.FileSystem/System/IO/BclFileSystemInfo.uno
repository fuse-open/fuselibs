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
        public extern BclDateTime LastAccessTimeUtc { get; }
        public extern BclDateTime LastWriteTimeUtc { get; }
        public extern BclDateTime CreationTimeUtc { get; }
    }
}

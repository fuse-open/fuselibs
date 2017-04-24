using Uno.Compiler.ExportTargetInterop;

namespace Fuse.FileSystem
{
    [extern(DOTNET) DotNetType("System.IO.FileInfo")]
    extern(DOTNET) internal sealed class BclFileInfo : BclFileSystemInfo
    {
        public extern BclFileInfo(string path);
        public extern long Length { get; }
    }
}

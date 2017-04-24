using Uno.Compiler.ExportTargetInterop;

namespace Fuse.FileSystem
{
    [extern(DOTNET) DotNetType("System.IO.DirectoryInfo")]
    extern(DOTNET) internal sealed class BclDirectoryInfo : BclFileSystemInfo
    {
        public extern BclDirectoryInfo(string path);
        private extern BclDirectoryInfo();
    }
}

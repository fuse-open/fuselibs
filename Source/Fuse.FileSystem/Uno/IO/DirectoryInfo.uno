using Uno;

namespace Fuse.FileSystem
{
    public class DirectoryInfo : FileSystemInfo
    {
        public DirectoryInfo(string originalPath) : base(originalPath)
        {
        }


        extern(DOTNET) internal override BclFileSystemInfo LoadStatus()
        {
            return new BclDirectoryInfo(_fullPath);
        }


        extern(!DOTNET) internal override FileStatus LoadStatus()
        {
            var status = base.LoadStatus();
            // If we're stat'ing a file, ignore and return "not exist" status
            if ((status.Attributes & FileAttributes.Directory) == 0)
                return new FileStatus();

            return status;
        }
    }
}

using Uno;

namespace Fuse.FileSystem
{
    extern(!(MSVC || UNIX)) internal static class FileStatusHelpers
    {
        public static FileStatus GetFileStatus(string path)
        {
            throw new NotImplementedException();
        }
    }
}

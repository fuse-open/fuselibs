using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.IO;
using Uno.Time;

namespace Fuse.FileSystem
{
    public abstract class FileSystemInfo
    {
        protected readonly string _fullPath;
        readonly string _originalPath;


        protected FileSystemInfo(string originalPath)
        {
            if (originalPath == null)
                throw new ArgumentNullException("originalPath");

            this._originalPath = originalPath;
            this._fullPath = Path.GetFullPath(_originalPath);
        }


        public void Refresh()
        {
            // Could this introduce a potential memory leak when
            // used from multiple threads?
            // I know this is safe with GC, but might not be with
            // refcount??
            _status = LoadStatus();
        }


        private static ZonedDateTime ConvertTime(object time)
        {
            if defined(DOTNET)
            {
                var dt = (BclDateTime)time;
                var instant = Constants.BclEpoch.PlusTicks(dt.Ticks);
                return new ZonedDateTime(instant, DateTimeZone.Utc);
            }
            else
                return (ZonedDateTime)time;
        }


        public FileAttributes Attributes { get { return (FileAttributes)Status.Attributes; } }

        public bool Exists { get { return Status.Exists; } }

        public string FullName { get { return _fullPath; } }

        public ZonedDateTime LastAccessTimeUtc { get { return ConvertTime(Status.LastAccessTimeUtc); } }

        public ZonedDateTime LastWriteTimeUtc { get { return ConvertTime(Status.LastWriteTimeUtc); } }


        extern(!DOTNET) private FileStatus _status;

        extern(!DOTNET) internal FileStatus Status
        {
            get
            {
                if (_status == null)
                    Refresh();

                return _status;
            }
        }

        extern(!DOTNET) internal virtual FileStatus LoadStatus()
        {
            return FileStatusHelpers.GetFileStatus(this._fullPath);
        }

        extern(DOTNET) private BclFileSystemInfo _status;

        extern(DOTNET) internal virtual BclFileSystemInfo LoadStatus()
        {
            // Marking this as abstract combined with extern did not work, why?
            throw new InvalidOperationException();
        }

        extern(DOTNET) internal BclFileSystemInfo Status
        {
            get
            {
                if (_status == null)
                    Refresh();

                return _status;
            }
        }
    }
}

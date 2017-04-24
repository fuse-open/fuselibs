using Uno;
using Uno.Time;

namespace Fuse.FileSystem
{
    internal class FileStatus
    {
        internal static readonly Instant FileTimeEpoch = Instant.FromUtc(1601, 1, 1, 0, 0);

        readonly bool _exists;
        readonly long _length;
        readonly FileAttributes _attributes;
        readonly ZonedDateTime _creationTimeUtc;
        readonly ZonedDateTime _lastAccessTimeUtc;
        readonly ZonedDateTime _lastWriteTimeUtc;


        public FileStatus()
        {
            // When file does not exists the timestamps will be
            //  12:00 midnight, January 1, 1601 A.D. (C.E.) Coordinated Universal Time (UTC).
            // This is because we want to follow the .NET API behavior
            var defaultTime = new ZonedDateTime(FileTimeEpoch, DateTimeZone.Utc);
            _creationTimeUtc = defaultTime;
            _lastWriteTimeUtc = defaultTime;
            _lastAccessTimeUtc = defaultTime;
            _exists = false;

            // FileInfo on .NET seems to return -1, don't know why but let's just follow that
            _attributes = (FileAttributes)(-1);
        }


        public FileStatus(long length,
                          FileAttributes attributes,
                          ZonedDateTime creationTimeUtc,
                          ZonedDateTime lastAccessTimeUtc,
                          ZonedDateTime lastWriteTimeUtc)
        {
            _length = length;
            _attributes = attributes;
            _creationTimeUtc = creationTimeUtc;
            _lastWriteTimeUtc = lastWriteTimeUtc;
            _lastAccessTimeUtc = lastAccessTimeUtc;
            _exists = true;
        }


        // This is not currently exposed on FileSystemInfo, as there's no simple way
        // to get file creation timestamp on Linux.
        public ZonedDateTime CreationTimeUtc { get { return _creationTimeUtc; } }

        public bool Exists { get { return _exists; } }

        public FileAttributes Attributes { get { return _attributes; } }

        public ZonedDateTime LastAccessTimeUtc { get { return _lastAccessTimeUtc; } }

        public ZonedDateTime LastWriteTimeUtc { get { return _lastWriteTimeUtc; } }

        public long Length { get { return _length; } }
    }
}

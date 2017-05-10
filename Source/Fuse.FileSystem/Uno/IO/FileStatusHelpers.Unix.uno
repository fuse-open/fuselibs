using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Time;

namespace Fuse.FileSystem
{
    [Require("Source.Include", "sys/types.h")]
    [Require("Source.Include", "sys/stat.h")]
    [Require("Source.Include", "unistd.h")]
    [Require("Source.Include", "Uno/Support.h")]
    extern(UNIX) internal static class FileStatusHelpers
    {
        extern(UNIX) private static ZonedDateTime UnixTimeToZoned(long sec)
        {
            var ticks = sec * Constants.TicksPerSecond;
            return new ZonedDateTime(new Instant(ticks), DateTimeZone.Utc);
        }

        extern(UNIX) public static FileStatus GetFileStatus(string path)
        @{
            struct stat s;

            if (stat(uStringToXliString(path).Ptr(), &s) == -1)
                return @{FileStatus():New()};

            @{FileAttributes} attributes = 0;

            // ReadOnly used to be mapped the following way in uno-base,
            // but until we're sure this is the correct way to do we just avoid
            // mapping the ReadOnly attribute at all.
            //
            // if (!(((s.st_mode & S_IWOTH) == S_IWOTH)
            //    || (s.st_gid == getgid() && ((s.st_mode & S_IWGRP) == S_IWGRP))
            //    || (s.st_uid == getuid() && ((s.st_mode & S_IWUSR) == S_IWUSR))))
            //    attributes |= AT{FileAttributes.ReadOnly};

            if (S_ISDIR(s.st_mode))
                attributes |= @{FileAttributes.Directory};

            if (S_ISCHR(s.st_mode) || S_ISBLK(s.st_mode))
                attributes |= @{FileAttributes.Device};

            if (S_ISLNK(s.st_mode))
                attributes |= @{FileAttributes.ReparsePoint};

            // Apparently posix stat standard doesn't define a way to get creation time,
            // so we'll just use lastWriteTime.
            // TODO: It seems like this might be possible on OS X though, in some non-posix way..
            @{ZonedDateTime} lastWriteTime =
                @{UnixTimeToZoned(long):Call(s.st_mtime)};
            @{ZonedDateTime} lastAccessTime =
                @{UnixTimeToZoned(long):Call(s.st_atime)};

            return @{FileStatus(long, FileAttributes, ZonedDateTime, ZonedDateTime, ZonedDateTime):New(
                s.st_size,
                attributes,
                lastWriteTime,
                lastAccessTime,
                lastWriteTime
            )};
        @}
    }
}

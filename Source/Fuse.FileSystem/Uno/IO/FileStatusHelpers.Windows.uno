using Uno;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.FileSystem
{
    [Require("Source.Declaration", "#define WIN32_LEAN_AND_MEAN")]
    [Require("Source.Include", "windows.h")]
    [Require("Source.Declaration", "#undef GetSystemDirectory")]
    [Require("Source.Declaration", "#undef GetCurrentDirectory")]
    [Require("Source.Declaration", "#undef SetCurrentDirectory")]
    [Require("Source.Declaration", "#undef CreateDirectory")]
    [Require("Source.Declaration", "#undef ChangeDirectory")]
    [Require("Source.Declaration", "#undef DeleteFile")]
    [Require("Source.Declaration", "#undef MoveFile")]
    [Require("Source.Declaration", "#undef CopyFile")]
    [Require("Source.Declaration", "#undef GetMessage")]
    [Require("Source.Include", "Uno/Support.h")]
    extern(MSVC) internal static class FileStatusHelpers
    {
        extern(MSVC) private static DateTime FileTimeToZoned(uint fileTimeHigh, uint fileTimeLow)
        {
            var fileTime = ((long)fileTimeHigh << 32) | fileTimeLow;
            return DateTime.FromFileTimeUtc(fileTime);
        }


        extern(MSVC) public static FileStatus GetFileStatus(string path)
        @{
            WIN32_FILE_ATTRIBUTE_DATA data;

            if (!GetFileAttributesEx(path->Ptr(), GetFileExInfoStandard, &data))
                return @{FileStatus():New()};

            uint64_t size = ((uint64_t)data.nFileSizeHigh << 32) | data.nFileSizeLow;
            @{FileAttributes} attributes = 0;

            if (data.dwFileAttributes & FILE_ATTRIBUTE_DEVICE)
                attributes |= @{FileAttributes.Device};

            if (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
                attributes |= @{FileAttributes.Directory};

            // We're not mapping the ReadOnly attribute until we decides on
            // a good way to do this with posix api. Or never.
            //
            // if (data.dwFileAttributes & FILE_ATTRIBUTE_READONLY)
            //     attributes |= AT{FileAttributes.ReadOnly};

            if (data.dwFileAttributes & FILE_ATTRIBUTE_REPARSE_POINT)
                attributes |= @{FileAttributes.ReparsePoint};

            return @{FileStatus(long, FileAttributes, DateTime, DateTime, DateTime):New(
                size,
                attributes,
                // CreationTime
                @{FileTimeToZoned(uint, uint):Call(data.ftCreationTime.dwHighDateTime, data.ftCreationTime.dwLowDateTime)},
                // LastAccessTime
                @{FileTimeToZoned(uint, uint):Call(data.ftLastAccessTime.dwHighDateTime, data.ftLastAccessTime.dwLowDateTime)},
                // LastWriteTime
                @{FileTimeToZoned(uint, uint):Call(data.ftLastWriteTime.dwHighDateTime, data.ftLastWriteTime.dwLowDateTime)}
            )};
        @}
    }
}

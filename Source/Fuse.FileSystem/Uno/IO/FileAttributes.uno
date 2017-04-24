namespace Fuse.FileSystem
{
    public enum FileAttributes
    {
        // Some attributes have been commented away due to not
        // being relevant or easily obtainable on posixy platforms.

        // ReadOnly = 0x1,
        // Hidden = 0x2,
        // System = 0x4,
        Directory = 0x10,
        // Archive = 0x20,
        Device = 0x40,
        // Normal = 0x80,
        // Temporary = 0x100,
        // SparseFile = 0x200,
        ReparsePoint = 0x400,
        // Compressed = 0x800,
        // Offline = 0x1000,
        // NotContentIndexed = 0x2000,
        // Encrypted = 0x4000,
    }
}

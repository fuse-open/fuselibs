using Uno;
using Uno.IO;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Resources.Exif
{
	[Flags]
	public enum ImageOrientation
	{
		Identity = 0,
		Rotate90 = 1,
		Rotate180 = 2,
		Rotate270 = 3,
		FlipVertical = 1 << 2,
	}

	public struct ExifData
	{
		public readonly ImageOrientation Orientation;

		public static ExifData FromByteArray(byte[] buffer)
		{
			if defined(Android)
				return ExifAndroidImpl.FromByteArray(buffer);
			if defined(iOS)
				return ExifIOSImpl.FromByteArray(buffer);
			if defined(DotNet)
				return ExifDotNetImpl.FromByteArray(buffer);
			else
				throw new Exception("Exif is not supported by this platform");
		}

		internal ExifData(int orientation)
		{
			//This is based on the vertical flip being applied before the rotation
			switch (orientation)
			{
				case 0: Orientation = ImageOrientation.Identity; break; //Exif orientation is undefined
				case 1: Orientation = ImageOrientation.Identity; break;
				case 2: Orientation = ImageOrientation.FlipVertical | ImageOrientation.Rotate180; break;
				case 3: Orientation = ImageOrientation.Rotate180; break;
				case 4: Orientation = ImageOrientation.FlipVertical; break;
				case 5: Orientation = ImageOrientation.FlipVertical | ImageOrientation.Rotate270; break;
				case 6: Orientation = ImageOrientation.Rotate90; break;
				case 7: Orientation = ImageOrientation.FlipVertical | ImageOrientation.Rotate90; break;
				case 8: Orientation = ImageOrientation.Rotate270; break;
			}
		}
	}

	[TargetSpecificImplementation, DotNetType("System.Drawing.Image")]
	extern(CIL) class Image
	{
		[TargetSpecificImplementation]
		public extern static Image FromStream(Stream stream);

		[TargetSpecificImplementation]
		public extern PropertyItem[] PropertyItems { get; }
	}

	[TargetSpecificImplementation, DotNetType("System.Drawing.Imaging.PropertyItem")]
	extern(CIL) class PropertyItem
	{
		[TargetSpecificImplementation]
		public extern int Id { get; set; }

		[TargetSpecificImplementation]
		public extern int Len { get; set; }

		[TargetSpecificImplementation]
		public extern short Type { get; set; }

		[TargetSpecificImplementation]
		public extern byte[] Value { get; set; }
	}

	extern(CIL) static class ExifDotNetImpl
	{
		const int OrientationTagId = 274; //as defined by the exif spec www.exif.org/Exif2-2.PDF (page 16)

		internal static ExifData FromByteArray(byte[] bytes)
		{
			var memStream = new MemoryStream(bytes);
			var img = Image.FromStream(memStream);
			return new ExifData(GetOrientation(img));
		}

		static int GetOrientation(Image img)
		{
			var properties = img.PropertyItems;
			foreach (var p in properties)
			{
				if (p.Id == OrientationTagId)
				{
					var buffer = new Buffer(p.Value);
					var orientation = buffer.GetShort(0,true);
					return orientation;
				}
			}
			return 0;
		}
	}

	[Require("Source.Include", "ImageIO/ImageIO.h")]
	[Require("Source.Include", "CoreFoundation/CoreFoundation.h")]
	[Require("Xcode.Framework", "ImageIO.framework")]
	[Require("Xcode.Framework", "CoreFoundation.framework")]
	extern(iOS) static class ExifIOSImpl
	{
		internal static ExifData FromByteArray(byte[] bytes)
		{
			var orientation = GetOrientation(bytes);
			return new ExifData(orientation);
		}

		[Foreign(Language.ObjC)]
		static int GetOrientation(byte[] bytes)
		@{
			CFDataRef data = CFDataCreateWithBytesNoCopy(NULL, (const UInt8 *)bytes.unoArray->Ptr(), bytes.unoArray->Length(), kCFAllocatorNull);
			CGImageSourceRef imageSource = CGImageSourceCreateWithData(data, NULL);

			NSArray *metadataArray = nil;

			if (imageSource) {
				CGImageMetadataRef metadata = CGImageSourceCopyMetadataAtIndex(imageSource, 0, NULL);
				if (metadata) {
					metadataArray = CFBridgingRelease(CGImageMetadataCopyTags(metadata));
					CFRelease(metadata);
				}
				CFRelease(imageSource);
			}

			int rotation = 0;
			NSString* tagTarget = @"Orientation";
			if (metadataArray != nil)
			{
				for (id tag in metadataArray) {
					CFStringRef tagName = CGImageMetadataTagCopyName((CGImageMetadataTagRef)tag);
					if ([tagTarget isEqualToString: (__bridge NSString*)tagName]) {
						CFTypeRef rot = CGImageMetadataTagCopyValue((CGImageMetadataTagRef)tag);
						rotation = [((__bridge NSNumber*)rot) intValue];
						break;
					}
				}
			}

			return rotation;

		@}
	}

	[Require("Gradle.Dependency.Compile", "com.drewnoakes:metadata-extractor:2.10.1")]
	[ForeignInclude(Language.Java,
		"java.io.ByteArrayInputStream",
		"java.io.InputStream",
		"java.io.IOException",
		"com.drew.imaging.ImageMetadataReader",
		"com.drew.imaging.ImageProcessingException",
		"com.drew.metadata.Metadata",
		"com.drew.metadata.MetadataException",
		"com.drew.metadata.exif.ExifIFD0Directory")]
	//Uses https://drewnoakes.com/code/exif/
	extern(Android) class ExifAndroidImpl
	{
		internal static ExifData FromByteArray(byte[] bytes)
		{
			var buf = ForeignDataView.Create(bytes);
			var orientation = GetOrientation(buf);
			return new ExifData(orientation);
		}

		[Foreign(Language.Java)]
		static int GetOrientation(Java.Object buf)
		@{
			InputStream s = new com.fuse.android.ByteBufferInputStream((com.uno.UnoBackedByteBuffer)buf);
			try {
				Metadata metadata = ImageMetadataReader.readMetadata(s);
				ExifIFD0Directory directory = metadata.getFirstDirectoryOfType(ExifIFD0Directory.class);

				if (directory != null && directory.containsTag(ExifIFD0Directory.TAG_ORIENTATION)) {
					return directory.getInt(ExifIFD0Directory.TAG_ORIENTATION);
				}
			}
			catch (Exception e) {
				e.printStackTrace();
			}
			return 0;
		@}
	}
}

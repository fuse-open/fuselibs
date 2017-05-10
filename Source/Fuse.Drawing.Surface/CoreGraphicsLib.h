#include <algorithm>
#include <CoreGraphics/CoreGraphics.h>

namespace CGLib
{

struct Context
{
	CGContextRef Context;
	CGColorSpaceRef ColorSpace;
	void* BitmapData;
	int Width, Height;
	int GLTexture;

	int saveStateCount;
	void SaveState()
	{
		CGContextSaveGState(Context);
		saveStateCount++;
	}
	
	bool RestoreState()
	{
		if (saveStateCount >0)
		{
			CGContextRestoreGState(Context);
			saveStateCount--;
			return true;
		}
		return false;
	}
	
	bool ResetState()
	{
		bool okay = true;
		while (saveStateCount > 0)
		{
			if (!RestoreState())
				okay = false;
		}
		return okay;
	}
	
	void ReleaseContext()
	{
		CGContextRelease(Context);
		free(BitmapData);
		Context = nullptr;
		BitmapData = nullptr;
		saveStateCount = 0;
	}

	void FillPath(CGPathRef path, bool eoFill)
	{
		CGContextAddPath(Context, path);

		if (eoFill)
			CGContextEOFillPath(Context);
		else
			CGContextFillPath(Context);
	}

	void ClipPath(CGPathRef path, bool eoFill)
	{
		CGContextAddPath(Context, path);

		if (eoFill)
			CGContextEOClip(Context);
		else
			CGContextClip(Context);
	}
};

} //eon CGLib

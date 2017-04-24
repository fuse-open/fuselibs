package com.fuse.android;

import java.io.IOException;
import com.uno.UnoBackedByteBuffer;
import android.media.MediaDataSource;
import java.nio.BufferUnderflowException;

public class ByteBufferMediaDataSource extends MediaDataSource
{
	private UnoBackedByteBuffer _buf;

	public ByteBufferMediaDataSource(UnoBackedByteBuffer buf)
	{
		_buf = buf;
	}

	@Override
	public long getSize ()
	{
		return (long)_buf.capacity();
	}

	@Override
	public int readAt (long position, byte[] buffer, int offset, int size)
	{
		_buf.position((int)position); // ugly but buffer only has position with int
		try
		{
			if (size == 0)
				return 0;

			size = Math.min(size, _buf.remaining());
			if (size == 0)
				return -1;

			_buf.get(buffer, offset, size);
			return size;
		}
		catch (BufferUnderflowException e)
		{
			return -1;
		}
		catch (IndexOutOfBoundsException e)
		{
			return -1;
		}
	}

	@Override
	public void close ()
	{
		_buf.close();
	}
}

package com.fuse.android;

import java.io.InputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import com.uno.UnoBackedByteBuffer;

public class ByteBufferInputStream extends InputStream
{
	private UnoBackedByteBuffer _buf;

	public ByteBufferInputStream(UnoBackedByteBuffer buf)
	{
		_buf = buf;
	}

	public int read() throws IOException
	{
		if (!_buf.hasRemaining())
			return -1;

		return _buf.get() & 0xFF;
	}

	public int read(byte[] bytes, int off, int len) throws IOException
	{
		if (len == 0)
			return 0;

		len = Math.min(len, _buf.remaining());
		if (len == 0)
			return -1;

		_buf.get(bytes, off, len);
		return len;
	}

	public int read(byte[] buffer) throws IOException
	{
		return read(buffer, 0, buffer.length);
	}

	public int available() throws IOException
	{
		return _buf.remaining();
	}

	@Override
	public void close ()
	{
		_buf.close();
	}
}

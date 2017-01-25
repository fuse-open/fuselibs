package com.fuse.android;
import java.io.InputStream;
import java.io.IOException;
import java.nio.ByteBuffer;

public class ByteBufferInputStream extends InputStream {
	ByteBuffer buf;

	public ByteBufferInputStream(ByteBuffer buf) {
		this.buf = buf;
	}

	public int read() throws IOException {
		if (!buf.hasRemaining())
			return -1;

		return buf.get() & 0xFF;
	}

	public int read(byte[] bytes, int off, int len) throws IOException {
		if (len == 0)
			return 0;

		len = Math.min(len, buf.remaining());
		if (len == 0)
			return -1;

		buf.get(bytes, off, len);
		return len;
	}

	public int read(byte[] buffer) throws IOException {
		return read(buffer, 0, buffer.length);
	}

	public int available() throws IOException {
		return buf.remaining();
	}
}

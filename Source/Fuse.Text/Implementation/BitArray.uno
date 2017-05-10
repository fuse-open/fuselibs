namespace Fuse.Text.Implementation
{
	class BitArray
	{
		public readonly byte[] Data;
		public readonly int Count;

		const int ByteSize = 8;

		public BitArray(int length)
		{
			Count = length;
			Data = new byte[(length + ByteSize - 1) / ByteSize];
		}

		public bool this[int i]
		{
			get
			{
				return (Data[Index(i)] & Mask(i)) != 0;
			}
			set
			{
				var index = Index(i);
				var mask = Mask(i);
				var data = Data[index];
				Data[index] = value
					? (data | mask)
					: (data & ~ mask);
			}
		}

		int Index(int i)
		{
			return i / ByteSize;
		}

		byte Mask(int i)
		{
			return (byte)(1 << (i % ByteSize));
		}
	}
}

using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Runtime.InteropServices;

namespace Fuse.Scripting.V8
{
	internal static extern(USE_V8) class Handle
	{
		public static IntPtr Create(object o) { return (IntPtr)GCHandle.Alloc(o); }
		public static void Free(IntPtr handle) { ((GCHandle)handle).Free(); }
		public static object Target(IntPtr handle) { return ((GCHandle)handle).Target; }
	}

	internal extern(USE_V8) class ArrayHandle
	{
		public readonly byte[] Array;
		extern(DOTNET) readonly GCHandle _handle;

		public ArrayHandle(byte[] array)
		{
			Array = array;
			if defined(DOTNET)
			{
				_handle = GCHandle.Alloc(Array, GCHandleType.Pinned);
			}

		}

		extern(DOTNET) ~ArrayHandle()
		{
			_handle.Free();
		}

		public IntPtr GetIntPtr()
		{
			if defined(DOTNET)
			{
				return Marshal.UnsafeAddrOfPinnedArrayElement(Array, 0);
			}
			else if defined(CPlusPlus)
			{
				return extern<IntPtr> (Array) "$0->Ptr()";
			}
		}

		public static byte[] CopyToArray(IntPtr ptr, int length)
		{
			if defined(DOTNET)
			{
				byte[] res = new byte[length];
				Marshal.Copy(ptr, res, 0, length);
				return res;
			}
			else if defined(CPlusPlus)
			{
				return extern<byte[]> (length, ptr) "uArray::New(@{byte[]:TypeOf}, $0, $1)";
			}
		}
	}

	[DotNetType("System.Runtime.InteropServices.Marshal")]
	internal extern(DOTNET) static class Marshal
	{
		public static extern IntPtr UnsafeAddrOfPinnedArrayElement(Uno.Array arr, int index);
		public static extern void Copy(IntPtr source, byte[] destination, int start, int length);
	}
}

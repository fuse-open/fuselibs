using Uno;

namespace Fuse.Designer
{
	
	extern(Designer) public static class UnoHostInterface
	{

		internal static Func<object, Action<Rect, float4x4>, IDisposable> VisualAppearedFactory;
		internal static Func<object, Action<Rect>, IDisposable> VisualBoundsChangedFactory;
		internal static Func<object, Action<float4x4>, IDisposable> VisualTransformChangedFactory;
		internal static Func<object, Action, IDisposable> VisualDisappearedFactory;

		public static IDisposable OnVisualAppeared(object obj, Action<Rect, float4x4> handler)
		{
			if (VisualAppearedFactory == null)
				throw new Exception("VisualAppearedFactory func is null");

			return VisualAppearedFactory(obj, handler);
		}

		public static IDisposable OnVisualBoundsChanged(object obj, Action<Rect> handler)
		{
			if (VisualBoundsChangedFactory == null)
				throw new Exception("VisualBoundsChangedFactory func is null");

			return VisualBoundsChangedFactory(obj, handler);
		}

		public static IDisposable OnVisualTransformChanged(object obj, Action<float4x4> handler)
		{
			if (VisualTransformChangedFactory == null)
				throw new Exception("VisualTransformChangedFactory func is null");

			return VisualTransformChangedFactory(obj, handler);
		}

		public static IDisposable OnVisualDisappeared(object obj, Action handler)
		{
			if (VisualDisappearedFactory == null)
				throw new Exception("VisualDisappearedFactory func is null");

			return VisualDisappearedFactory(obj, handler);
		}
	}
}
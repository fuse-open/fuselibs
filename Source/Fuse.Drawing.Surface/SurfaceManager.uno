using Uno;
using Uno.Collections;

namespace Fuse.Drawing
{
	internal interface INativeSurfaceOwner
	{
		Surface GetSurface();
	}
	
	static public class SurfaceManager
	{
		static public Surface Create(object owner)
		{
			Surface c = null;

			var v = owner as Visual;
			if (v != null && v.VisualContext == VisualContext.Native)
			{
				if defined(Android||iOS)
				{
					var nativeOwner = v.ViewHandle as INativeSurfaceOwner;
					if (nativeOwner != null)
						c = nativeOwner.GetSurface();
				}
			}

			if (c == null)
			{
				if defined(iOS||OSX)
					c = new GraphicsSurface();
				else if defined(Android)
					c = new GraphicsSurface();
				else if defined(DOTNET)
					c = new DotNetSurface();
				else
					throw new Exception( "Unsupported backend for Surface");
			}

			c.Owner = owner;
			return c;
		}

		static Dictionary<object, Surface> _owners = new Dictionary<object,Surface>();

		static public Surface Find(Node source)
		{
			return FindImpl(source, false);
		}

		static public Surface FindOrCreate(Node source)
		{
			return FindImpl(source, true);
		}

		static Surface FindImpl(Node source, bool create)
		{
			ISurfaceProvider provider = null;

			var from = source;
			while (from != null)
			{
				if (from is ISurfaceProvider && from != source)
					provider = from as ISurfaceProvider;
				//can still find another provider if in drawable chain

				if (from is ISurfaceDrawable)
					from = from.Parent;
				else
					break;
			}

			var owner = (object)provider ?? (object)source;
			Surface cur;
			if (_owners.TryGetValue(owner, out cur))
				return cur;
			if (!create && provider == null)
				return null;

			cur = Create(owner);
			_owners[owner] = cur;
			return cur;
		}

		static public void Release(object owner, Surface c)
		{
			if (c.Owner == owner)
			{
				c.Dispose();
				_owners.Remove(owner);
			}
		}
	}

	internal interface ISurfaceProvider { }
}
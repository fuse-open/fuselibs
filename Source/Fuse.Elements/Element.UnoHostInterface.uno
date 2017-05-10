using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Elements
{
	//  E0000: Partial class does not support 'extern(CONDITION)' :(
	/*extern(Designer)*/ public abstract partial class Element
	{

		extern(Designer) class DefaultDisposable : IDisposable
		{
			static IDisposable _instance;
			public static IDisposable Instance
			{
				get { return _instance ?? (_instance = new DefaultDisposable()); }
			}

			void IDisposable.Dispose() { }
		}

		extern(Designer) internal static IDisposable VisualTransformChangedFactory(object obj, Action<float4x4> handler)
		{
			return (obj is Element)
				? (IDisposable)new TransformChanged((Element)obj, handler)
				: DefaultDisposable.Instance;
		}

		extern(Designer) class TransformChanged : IDisposable
		{
			Element _element;
			Action<float4x4> _handler;

			public TransformChanged(Element element, Action<float4x4> handler)
			{
				_element = element;
				_handler = handler;
				_handler(_element.WorldTransform);
				_element.WorldTransformInvalidated += OnWorldTransformInvalidated;
			}

			void OnWorldTransformInvalidated(object sender, EventArgs args)
			{
				_handler(_element.WorldTransform);
			}

			void IDisposable.Dispose()
			{
				_element.WorldTransformInvalidated -= OnWorldTransformInvalidated;
				_element = null;
				_handler = null;
			}
		}

		extern(Designer) internal static IDisposable VisualAppearedFactory(object obj, Action<Rect, float4x4> handler)
		{
			return (obj is Element)
				? (IDisposable)new VisualAppeared((Element)obj, handler)
				: DefaultDisposable.Instance;
		}

		extern(Designer) internal static IDisposable VisualBoundsChangedFactory(object obj, Action<Rect> handler)
		{
			return (obj is Element)
				? (IDisposable)new BoundsChanged((Element)obj, handler)
				: DefaultDisposable.Instance;
		}

		extern(Designer) class BoundsChanged : IDisposable
		{
			Element _element;
			Action<Rect> _handler;

			public BoundsChanged(Element element, Action<Rect> handler)
			{
				_element = element;
				_handler = handler;
				_handler(new Rect(_element.ActualPosition, _element.ActualSize));
				_element.Placed += OnPlaced;
			}

			void OnPlaced(object sender, PlacedArgs args)
			{
				_handler(new Rect(args.NewPosition, args.NewSize));
			}

			void IDisposable.Dispose()
			{
				_element.Placed -= OnPlaced;
				_element = null;
				_handler = null;
			}
		}

		extern(Designer) internal static IDisposable VisualDisappearedFactory(object obj, Action handler)
		{
			return (obj is Element)
				? (IDisposable)new VisualDisappeared((Element)obj, handler)
				: DefaultDisposable.Instance;
		}

		extern(Designer) class VisualAppeared : IDisposable
		{

			Element _element;
			Action<Rect, float4x4> _handler;

			public VisualAppeared(Element element, Action<Rect, float4x4> handler)
			{
				_element = element;
				_element.RootedListeners.Add(OnRooted);
				_handler = handler;
				if (_element.IsRootingCompleted)
					OnRooted();
			}

			void OnRooted()
			{
				_handler(new Rect(_element.ActualPosition, _element.ActualSize), _element.WorldTransform);
			}

			void IDisposable.Dispose()
			{
				_element.RootedListeners.Remove(OnRooted);
				_element = null;
				_handler = null;
			}
		}

		extern(Designer) class VisualDisappeared : IDisposable
		{

			Element _element;
			Action _handler;

			public VisualDisappeared(Element element, Action handler)
			{
				_element = element;
				_handler = handler;
				_element.UnrootedListeners.Add(_handler);
			}

			void IDisposable.Dispose()
			{
				_element.UnrootedListeners.Remove(_handler);
				_element = null;
				_handler = null;
			}
		}

		extern(Designer) List<Action> _rootedListeners;
		extern(Designer) List<Action> RootedListeners
		{
			get { return _rootedListeners ?? (_rootedListeners = new List<Action>(1)); }
		}

		extern(Designer) void NotifyRooted()
		{
			if (_rootedListeners != null)
			{
				foreach(var l in RootedListeners)
					l();
			}
		}

		extern(Designer) List<Action> _unrootedListeners;
		extern(Designer) List<Action> UnrootedListeners
		{
			get { return _unrootedListeners ?? (_unrootedListeners = new List<Action>(1)); }
		}

		extern(Designer) void NotifyUnrooted()
		{
			if (_unrootedListeners != null)
			{
				foreach(var l in UnrootedListeners)
					l();
			}
		}

	}

}

using Uno;
using Uno.Platform;
using Uno.Compiler;
using Uno.Collections;
using Uno.Diagnostics;
using Uno.UX;

using Fuse.Input;
using Fuse.Nodes;
using Fuse.Resources;

namespace Fuse
{
	public interface IRootVisualProvider
	{
		Visual Root { get; }
	}

	/** Holds information about an unhandled exception */
	public class UnhandledExceptionArgs: EventArgs
	{
		public Exception Exception { get; private set; }
		public bool IsHandled { get; set; }

		public UnhandledExceptionArgs(Exception e)
		{
			Exception = e;
		}
	}

	/** Signature of a method that can handle an unhandled exception */
	public delegate void UnhandledExceptionHandler(object sender, UnhandledExceptionArgs args);


	[IgnoreMainClass]
	/** Base class for Fuse @Apps. 
		This class contains implementation and interface that is common between all platforms. You
		only need to derive from this class when adding support for a new platform.
		Fuse already provides derived classes for each supported platform, all of them named @App, that you
		should use as base class when creating an app for an already supported platform. */
	public abstract class AppBase: Uno.Application, IProperties, IRootVisualProvider
	{

		Visual IRootVisualProvider.Root { get { return RootViewport; } }

		/** The top-level root viewport of this @App. This object has `null` as parent. */
		public RootViewport RootViewport { get; protected set; }

		Properties _properties;
		public Properties Properties
		{
			get { return _properties ?? (_properties = new Properties()); }
		}

		protected AppBase()
		{
			Background = float4(1);

			if defined(iOS || Android)
			{
				Fuse.Platform.Lifecycle.EnteringBackground += OnEnteringBackground;
				Fuse.Platform.AppEvents.LowMemoryWarning += OnLowMemory;
			}

			if defined(FUSELIBS_PROFILING)
			{
				string hostname;
				if defined (CPLUSPLUS)
					hostname = extern<string>"uString::Ansi(\"@(Fuselibs.Profiler.HostName:Or('127.0.0.1'))\")";
				else
					hostname = "127.0.0.1";

				debug_log "Connecting to profiler: " + hostname + "...";
				try
				{
					Fuse.Profiling.ProfileClient = new Fuse.ProfileClient(hostname, 1337);
					debug_log "Connected!";
				}
				catch (Exception e)
				{
					debug_log "Connection failed: " + e.Message;
				}
			}

			if defined(FUSELIBS_DEBUG_DRAW_RECTS && FUSELIBS_DEBUG_DRAW_RECTS_DEFAULT_ENABLE_CAPTURE)
				DrawRectVisualizer.IsCaptureEnabled = true;
		}

		//a workaround for static contexts for now
		internal float PixelsPerPoint
		{
			get
			{
				if (RootViewport == null)
					return 1; //for tests
					//throw new Exception("Unknown density: RootViewport not created" );
				return RootViewport.PixelsPerPoint;
			}
		}

		internal float PixelsPerOSPoint
		{
			get
			{
				if (RootViewport == null)
					return 1; //for tests
					//throw new Exception("Unknown density: RootViewport not created" );
				return RootViewport.PixelsPerOSPoint;
			}
		}
		
		void InvalidateGraphicsView(Node n)
		{
			var v = n as Visual;
			if (v == null)
				return;

			// HACK: We really want to invalidate GraphicsViews, but
			// we don't know about them at this level of abstraction
			// so instead, let's invalidate all IViewports
			if (!(v is IViewport))
				return;

			v.InvalidateVisual();
		}

		void OnEnteringBackground(Fuse.Platform.ApplicationState s)
		{
			Fuse.Resources.DisposalManager.Clean(DisposalRequest.Background);
		}

		void OnLowMemory()
		{
			Fuse.Resources.DisposalManager.Clean(DisposalRequest.LowMemory);
		}

		/** Occurs when an exception is unhandled within the @App.
			You can subscribe to this event to handle exceptions that were otherwise
			unhandled by the @App, to avoid crashing the app. If the `IsHandled`
			property of the @UnhandledExceptionArgs object is set to `true` by a handler,
			the app will not crash, but resume execution.

			@hide

			*/
		public event UnhandledExceptionHandler UnhandledException;

		/** Notfies the @App about an unhandled exception within a subsystem of the app. 
			If implementing a subsystems (such as separate threads) where exceptions can be
			thrown out of the app, you can catch such otherwise unhandled exceptions and report them
			to this method, to allow users to use the @UnhandledException event to deal with
			such exceptions instead of crashing the @App.

			@hide

			*/
		public void OnUnhandledException(Exception e, bool propagate = true)
		{
			//don't use Fuse.Diagnostics.UnknownException, that assumes a sane error path, but
			//at this point we don't have one anymore and thus Diagnostics may not be able to report correctly
			Uno.Diagnostics.Debug.Log(e.ToString(), Uno.Diagnostics.DebugMessageType.Error);
			if (UnhandledException != null)
			{
				var args = new UnhandledExceptionArgs(e);
				UnhandledException(this, args);
				if (args.IsHandled)
					return;
			}

			if (propagate)
				throw new WrapException(e);
		}

		internal static void OnUnhandledExceptionInternal(Exception e)
		{
			var app = Current;
			if (app != null) app.OnUnhandledException(e);
		}

		/** The currently executing @App. Note that this property might return `null`
			during execution of static constructors */
		public static new AppBase Current
		{
			get { return Uno.Platform.CoreApp.Current as Fuse.AppBase; }
		}

		//allows test setup to override this
		static RootViewport _testRootViewport;
		static internal void TestSetRootViewport( RootViewport rv)
		{
			_testRootViewport = rv;
		}
		
		static internal RootViewport CurrentRootViewport
		{
			get 
			{
				if (_testRootViewport != null)
					return _testRootViewport;
					
				if (Current == null)
					throw new Exception( "No AppBase Current defined" );
					
				var rv = Current.RootViewport;
				if (rv == null)
					throw new Exception( "No RootViewport defined" );
					
				return rv;
			}
		}

		// This satisfies UX as ClearColor is no longer a property of Uno.Application
		protected float4 ClearColor
		{
			get
			{
				return Background;
			}
			set
			{
				Background = value;
			}
		}

		/** The clear color of the root graphics view of the @App, if applicable. */
		public virtual float4 Background { get; set; }

		[UXPrimary]
		/** The @Node.Children of the virtual root @Node of the @App.
			Note that the virtual root node might be different from the @RootViewport depending
			on platform. */
		public abstract IList<Node> Children
		{
			get;
		}

		/** The virtual root @Visual of the @App. This is where @Children are located. */
		public abstract Visual ChildrenVisual { get; }
		
		
		[UXContent]
		/** The @Node.Resources of the virtual root node of the @App.
			Note that the virtual root node might be different from the @RootViewport depending
			on platform */
		public IList<Resource> Resources { get { return RootViewport.Resources; } }

		/** Called when the application updates. 
			This method can be overridden by platform-specific @App implementations, but should not 
			be overridden in user code. Use @UpdateManager instead. */
		protected virtual void OnUpdate()
		{
			if defined(FUSELIBS_PROFILING)
				Profiling.BeginUpdate();

			UpdateManager.Update();

			if defined(MOBILE)
				UpdateManager.IncreaseFrameIndex();

			if defined(FUSELIBS_PROFILING)
				Profiling.EndUpdate();
		}
	}
}

using Uno;
using Uno.UX;

using Fuse.Scripting;

namespace Fuse.Controls
{
	public partial class ScrollViewBase
	{
		static ScrollViewBase()
		{
			ScriptClass.Register(typeof(ScrollViewBase),
				new ScriptMethod<ScrollViewBase>("goto", goto_),
				new ScriptMethod<ScrollViewBase>("gotoRelative", gotoRelative),
				new ScriptMethod<ScrollViewBase>("seekTo", seekTo),
				new ScriptMethod<ScrollViewBase>("seekToRelative", seekToRelative));
		}

		static bool getParams(ScrollViewBase s,object[] args, string func, out float2 pos)
		{
			if (args.Length == 0 || args.Length > 2)
			{
				Fuse.Diagnostics.UserError( "ScrollViewBase." + func + " requires 1 or 2 arguments", s );
				pos = float2(0);
				return false;
			}
			
			pos = args.Length == 1 ?
				s.FromScalarPosition(Marshal.ToFloat(args[0])) :
				float2(Marshal.ToFloat(args[0]), Marshal.ToFloat(args[1]));
			return true;
		}

		/**
			Scroll to an absolute position (in points).
			
			@scriptmethod goto(absolutePosition)
			@scriptmethod goto(absoluteX, absoluteY)
		*/
		static void goto_(ScrollViewBase s, object[] args)
		{
			float2 pos;
			if (!getParams(s, args, "goto", out pos))
				return;
			s.Goto(pos);
		}
		
		/**
			Scroll to a relative position (range 0..1 over the full scrolling range).
			
			@scriptmethod gotoRelative(relativePosition)
			@scriptmethod gotoRelative(relativeX, relativeY)
		*/
		static void gotoRelative(ScrollViewBase s, object[] args)
		{
			float2 pos;
			if (!getParams(s, args, "gotoToRelative", out pos))
				return;
			s.GotoRelative(pos);
		}
		
		/**
			Seek to an absolute position (in points). This bypasses the scrolling animation.
			
			@scriptmethod seekTo(absolutePosition)
			@scriptmethod seekTo(absoluteX, absoluteY)
		*/
		static void seekTo(ScrollViewBase s, object[] args)
		{
			float2 pos;
			if (!getParams(s, args, "seekTo", out pos))
				return;
			s.ScrollPosition = pos;
		}
		
		/**
			Seek to a relative position (range 0..1 over the full scrolling range). This bypasses the scrolling animation.
			
			@scriptmethod seekToRelative(relativePosition)
			@scriptmethod seekToRelative(relativeX, relativeY)
		*/
		static void seekToRelative(ScrollViewBase s, object[] args)
		{
			float2 pos;
			if (!getParams(s, args, "seekToRelative", out pos))
				return;
			s.RelativeScrollPosition = pos;
		}
	}
}

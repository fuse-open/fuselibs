using Uno;
using Uno.Collections;
using Uno.UX;

using Fuse.Reactive;

namespace Fuse.Controls
{
	/** Represents a reactive object-member look-up operation. */
	public abstract class PathExpression : Fuse.Reactive.Expression
	{
		Reactive.Expression _path, _arg;
		String _name;
		internal PathExpression(Reactive.Expression path, Reactive.Expression arg, string name)
		{
			_path = path;
			_arg = arg;
			_name = name;
		}
		
		public override string ToString()
		{
			return _name + "(" + _path + ", " + _arg + ")";
		}
		
		public override IDisposable Subscribe(IContext context, IListener listener)
		{
			var sub = new PathSubscription(this, context, listener);
			sub.Init(context);
			return sub;
		}

		protected abstract object Calculate( SegmentedShape path, object param );
		
		class PathSubscription : ExpressionListener
		{
			IListener _listener;
			PathExpression _expr;
			SegmentedShape _path;
		
			public PathSubscription(PathExpression expr, IContext context, IListener listener) :
				base(expr, listener, new Fuse.Reactive.Expression[]{ expr._path, expr._arg })
			{
				_expr = expr;
			}
			
			object _param;
			protected override void OnArguments(Fuse.Reactive.Expression.Argument[] args)
			{
				if (args.Length < 2)
					return;
				
				var ss = args[0].Value as SegmentedShape;
				if (ss == null)
				{
					Fuse.Diagnostics.UserError( _expr._name + " requires a SegmentedShape as first argument", this );
					ClearData();
					return;
				}
				
				SwitchPath(ss);
				_param = args[1].Value;
				UpdateValue();
			}
			
			protected override void OnDataCleared()
			{
				base.OnDataCleared();
				SwitchPath( null );
			}
			
			void UpdateValue()
			{
				if (_path != null)
				{
					var result = _expr.Calculate( _path, _param );
					SetData( result );
				}
			}
		
			void SwitchPath(SegmentedShape path)
			{
				if (_path == path)
					return;

				if (_path != null)
					_path.SegmentsChanged -= SegmentsChanged;
				
				_path = path;
				if (_path != null)
					_path.SegmentsChanged += SegmentsChanged;
			}
			
			void SegmentsChanged()
			{
				if (_path != null)
					UpdateManager.AddDeferredAction( UpdateValue );
			}
			
			public override void Dispose()
			{
				_listener = null;
				if (_path != null)
				{
					_path.SegmentsChanged -= SegmentsChanged;
					_path = null;
				}
				base.Dispose();
			}
		}
	}
	
	[UXFunction("pathPointAtDistance")]
	/**
		The point at a normalized distance (0..1) along a path.
		@experimental
	*/
	public sealed class PathPointAtDistance : PathExpression
	{
 		[UXConstructor]
 		public PathPointAtDistance([UXParameter("Path")] Fuse.Reactive.Expression path,
 			[UXParameter("Distance")] Fuse.Reactive.Expression distance) : 
 			base(path, distance, "pathPointAtDistance" )
		{ }
			
		protected override object Calculate( SegmentedShape path, object param )
		{
			return path.PointAtDistance( Marshal.ToType<float>(param) );
		}
	}
	
	[UXFunction("pathTangentAngleAtDistance")]
	/**
		The tangent angle at a normalized distance (0..1) along a path.
		@experimental
	*/
	public sealed class PathTangentAngleAtDistance : PathExpression
	{
		[UXConstructor]
		public PathTangentAngleAtDistance([UXParameter("Path")] Fuse.Reactive.Expression path,
			[UXParameter("Distance")] Fuse.Reactive.Expression distance) : 
			base(path, distance, "pathTangentAngleAtDistance" )
		{ }
			
		protected override object Calculate( SegmentedShape path, object param )
		{
			var tangent = path.TangentAtDistance( Marshal.ToType<float>(param) );
			return Math.Atan2(tangent.Y, tangent.X);
		}
	}
	
	[UXFunction("pathPointAtTime")]
	/**
		The point at a normalized time (0..1) along a path.
		@experimental
	*/
	public sealed class PathPointAtTime : PathExpression
	{
 		[UXConstructor]
 		public PathPointAtTime([UXParameter("Path")] Fuse.Reactive.Expression path,
 			[UXParameter("Time")] Fuse.Reactive.Expression time) : 
 			base(path, time, "pathPointAtTime" )
		{ }
			
		protected override object Calculate( SegmentedShape path, object param )
		{
			return path.PointAtTime( Marshal.ToType<float>(param) );
		}
	}
	
	[UXFunction("pathTangentAngleAtTime")]
	/**
		The tangent angle (radians) at a normalized time (0..1) along a path.
		@experimental
	*/
	public sealed class PathTangentAngleAtTime : PathExpression
	{
		[UXConstructor]
		public PathTangentAngleAtTime([UXParameter("Path")] Fuse.Reactive.Expression path,
			[UXParameter("Time")] Fuse.Reactive.Expression time) :
			base(path, time, "pathTangentAngleAtTime" )
		{ }
			
		protected override object Calculate( SegmentedShape path, object param )
		{
			var tangent = path.TangentAtTime( Marshal.ToType<float>(param) );
			return Math.Atan2(tangent.Y, tangent.X);
		}
	}

}
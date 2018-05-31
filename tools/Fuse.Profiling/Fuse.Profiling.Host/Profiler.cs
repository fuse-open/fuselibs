using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Collections.ObjectModel;

namespace Fuse.Profiling
{

	public abstract class Event
	{
		public double Duration { get; private set; }
		public double Duration10 { get { return Duration * 10; } }

		protected Event(double duration)
		{
			Duration = duration;
		}
	}

	public class NewFramebuffer : Event
	{
		
		public int Width { get; private set; }
		public int Height { get; private set; }
		
		public NewFramebuffer(double duration, int x, int y) : base(duration)
		{
			Width = x;
			Height = y;
		}

		public override string ToString()
		{
			return "NewFrambuffer w: " + Width + ", h: " + Height + " - Duration: " + Duration + " ms";
		}
	}

	public class LogEvent : Event
	{
		
		public string Message { get; private set; }

		public LogEvent(double duration, string message) : base(duration)
		{
			Message = message;
		}

		public override string ToString()
		{
			return "LogEvent: " + Message + " - Duration: " + Duration + " ms";
		}

	}

	public class Node
	{

		public double Duration { get { return _durationMs;  } }
		public double Duration10 { get { return _durationMs * 10; } }

		public string Source { get { return _source; } }

		readonly List<Node> _children = new List<Node>();
		readonly List<Event> _events = new List<Event>();
		readonly string _source;


		double _durationMs;
        public IEnumerable<Node> Children { get { return _children; } }
		public IEnumerable<Event> Events { get { return _events; } }

		public Node(string source)
		{
			_source = source;
		}

		public void AddChild(Node child)
		{
			_children.Add(child);
		}

		public void End(double durationMs)
		{
			_durationMs = durationMs;
		}

		public void AddEvent(Event e)
		{
			_events.Add(e);
		}

		public override string ToString()
		{
			return (Source + " - Duration: " + Duration + " ms");
		}

	}

	public class Frame
	{
        public double Duration { get { return _durationMs; } }

        public double DurationMs100 { get { return _durationMs * 4.0; /* * 4.0 because of bar in XAML code */ } }

		public int FrameIndex { get { return _frameIndex; } }

		readonly int _frameIndex;

		double _durationMs;

		public Frame(int frameIndex)
		{
			_frameIndex = frameIndex;
		}

		public Node CurrentNode
		{
			get { return _nodeStack.Peek();  }
		}

		public List<Event> Events = new List<Event>();

        Node _root;
        public Node Root { get { return _root; } }

		readonly Stack<Node> _nodeStack = new Stack<Node>();

		public void PushNode(string source)
		{
            var n = new Node(source);

            if (_root == null)
                _root = n;
			
			if (_nodeStack.Count != 0)
				_nodeStack.Peek().AddChild(n);

			_nodeStack.Push(n);
		}

		public void PopNode(double durationMs)
		{
			_nodeStack.Pop().End(durationMs);
		}

		public void End(double durationMs)
		{
			_durationMs = durationMs;
		}

        public override string ToString()
        {
            var sb = new StringBuilder();
            Serializer.Serialize(this, sb, 0);
            return sb.ToString();
        }

	}

    static class Serializer
    {
        internal static void Serialize(Frame f, StringBuilder sb, int indent)
        {
            Indent(sb, indent);
            sb.AppendLine("Frame " + f.FrameIndex + " - Duration: " + (f.Duration) + " ms");
			Serialize(f.Events, sb, indent + 1);
            Serialize(f.Root, sb, indent+1);
        }

		static void Serialize(IEnumerable<Event> events, StringBuilder sb, int indent)
		{
			foreach (var e in events)
			{
				Indent(sb, indent + 1);
				sb.AppendLine(e.ToString());
			}
		}

        static void Serialize(Node n, StringBuilder sb, int indent)
        {
            Indent(sb, indent);
            sb.AppendLine(n.Source + " - Duration: " + (n.Duration) + " ms");
			Serialize(n.Events, sb, indent + 1);
            foreach (var c in n.Children)
                Serialize(c, sb, indent+1);
        }

        static void Indent(StringBuilder sb, int indent)
        {
            for (int i = 0; i < indent; i++)
                sb.Append("  ");
        }
    }

	public class Profiler : IProfiler
	{

		public ObservableCollection<Frame> Frames
		{
			get { return _frames; }
		}

		readonly ObservableCollection<Frame> _frames = new ObservableCollection<Frame>();
		readonly Action<Action> _dispatcher;


		public Profiler(Action<Action> dispatcher)
		{
			_dispatcher = dispatcher;
		}

		Frame _currentFrame;


		

		public void Error()
		{
			throw new Exception("ERROR");
		}


		readonly string[] _stringCache = new string[0xff];

		public void CacheString(byte id, string str)
		{
			_stringCache[id] = str;
		}


		public void BeginDrawNode(byte stringId)
		{
			var str = _stringCache[stringId];
			_currentFrame.PushNode(str);
		}

		public void EndDrawNodeByte(byte duration)
		{
			_currentFrame.PopNode(duration / 100.0);	
		}

        public void EndDrawNodeInt(int duration)
        {
            _currentFrame.PopNode(duration / 100.0);
        }

		public void BeginDraw(int frameIndex)
		{
			_currentFrame = new Frame(frameIndex);
		}

		public void EndDrawByte(byte duration)
		{
            EndDrawInt(duration);
		}

        public void EndDrawInt(int duration)
        {
            _currentFrame.End(duration / 100.0);

            var c = _currentFrame;

            Task.Run(() => _dispatcher(() => _frames.Add(c)));

            _currentFrame = null;
        }


		public void NewFramebufferByte(byte duration, int x, int y)
		{
			if (_currentFrame != null)
			{
				_currentFrame.CurrentNode.AddEvent(new NewFramebuffer(duration / 100.0, x, y));
			}
		}

		public void NewFramebufferInt(int duration, int x, int y)
		{
			if (_currentFrame != null)
			{
				_currentFrame.CurrentNode.AddEvent(new NewFramebuffer(duration / 100.0, x, y));
			}
		}


		public void LogEventByte(byte duration, byte stringId)
		{
			if (_currentFrame != null)
			{
				_currentFrame.CurrentNode.AddEvent(new LogEvent(duration / 100.0, _stringCache[stringId]));
			}
		}

		public void LogEventInt(int duration, byte stringId)
		{
			if (_currentFrame != null)
			{
				_currentFrame.CurrentNode.AddEvent(new LogEvent(duration / 100.0, _stringCache[stringId]));
			}
		}
	}
}


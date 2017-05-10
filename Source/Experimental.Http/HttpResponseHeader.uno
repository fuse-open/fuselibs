using Uno;
using Uno.Collections;
using Uno.IO;

namespace Experimental.Http
{
	public class HttpResponseHeader
	{
		public int StatusCode { get; internal set; }
		public string ReasonPhrase { get; internal set; }
		//all keys are lower-case
		public Dictionary<string,string> Headers { get; internal set; }
		
		void WriteSafe( BinaryWriter w, String s )
		{
			if (s == null || s.Length ==0)
				w.Write("!");
			else
				w.Write(s);
		}
		
		internal void Write( BinaryWriter w )
		{
			w.Write(StatusCode);
			//UNO: https://github.com/fusetools/Uno/issues/20
			WriteSafe(w,ReasonPhrase);
			
			int c = Headers.Count;
			w.Write(c);
			foreach( var h in Headers )
			{
				WriteSafe(w, h.Key);
				WriteSafe(w, h.Value );
			}
		}
		
		static internal HttpResponseHeader Read( BinaryReader r )
		{
			var h = new HttpResponseHeader();
			h.StatusCode = r.ReadInt();
			h.ReasonPhrase = r.ReadString();
			
			int c = r.ReadInt();
			h.Headers = new Dictionary<string,string>();
			for (int i=0; i < c; ++i)
			{
				var k = r.ReadString();
				var v = r.ReadString();
				h.Headers[k] = v;
			}
				
			return h;
		}
	}
	
}
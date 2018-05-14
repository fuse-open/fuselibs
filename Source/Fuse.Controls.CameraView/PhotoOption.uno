using Uno;
using Uno.Collections;
using Uno.Threading;

using Fuse;
using Fuse.Scripting;

namespace Fuse.Controls
{
	public abstract class PhotoOption
	{
		internal PhotoOption() {}

		internal static PhotoOption[] From(Fuse.Scripting.Object obj)
		{
			var options = new List<PhotoOption>();
			foreach (var key in obj.Keys)
			{
				if (key == PhotoResolution.Name)
					options.Add(PhotoResolution.From(obj[key] as Fuse.Scripting.Object));
				else
					throw new Exception("Unexpected PhotoOption: " + key);
			}
			return options.ToArray();
		}
	}

	public class PhotoResolution : PhotoOption
	{
		public const string Name = "PhotoResolution";

		public readonly int Width;
		public readonly int Height;

		public PhotoResolution(int width, int height)
		{
			Width = width;
			Height = height;
		}

		new internal static PhotoOption From(Fuse.Scripting.Object obj)
		{
			if (!obj.ContainsKey("width") || !obj.ContainsKey("height"))
				throw new Exception(Name + ": missing width or height argument");

			var width = Fuse.Scripting.Value.ToNumber(obj["width"]);
			var height = Fuse.Scripting.Value.ToNumber(obj["height"]);
			return new PhotoResolution((int)width, (int)height);
		}
	}

	internal abstract class PhotoOptionPromise : Promise<PhotoOption[]>
	{
		public Promise<PhotoOption[]> Visit(PhotoOption[] options)
		{
			try
			{
				foreach (var option in options)
				{
					if (option is PhotoResolution)
						Visit((PhotoResolution)option);
					else
						throw new Exception("Unexpected PhotoOption: " + option);
				}
			}
			catch (Exception e)
			{
				Reject(e);
				return this;
			}
			Resolve(options);
			return this;
		}

		protected abstract void Visit(PhotoResolution photoResolution);
	}
}

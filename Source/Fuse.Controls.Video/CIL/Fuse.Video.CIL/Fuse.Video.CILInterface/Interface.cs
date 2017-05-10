using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Fuse.Video.CILInterface
{
	public interface IVideo : IDisposable
	{
		int Width { get; }
		int Height { get; }
		float Volume { get; set; }
		bool IsFrameAvaiable { get; }
		double Position { get; set; }
		double Duration { get; }
		int RotationDegrees { get; }
		void Play();
		void Pause();
		void Stop();
		void UpdateTexture(System.Int32 textureHandle);
		void CopyPixels(byte[] destination);
	}
}

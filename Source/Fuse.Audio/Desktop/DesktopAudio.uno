using Uno.Threading;
using Uno;
using Uno.Collections;
using Uno.IO;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;

namespace System.Media
{
	[TargetSpecificImplementation, DotNetType]
	extern(DOTNET) internal class SoundPlayer
	{
		[TargetSpecificImplementation]
		public extern SoundPlayer(Stream stream);

		[TargetSpecificImplementation]
		public extern void Play();
	}
}

namespace Fuse.Audio
{
	internal extern(DOTNET) class SoundPlayer
	{
		static List<SoundHandle> _playingSounds = new List<SoundHandle>();

		public static void PlaySoundFromBundle(BundleFileSource file)
		{
			PlaySoundFromByteArray(file.ReadAllBytes());
		}

		public static void PlaySoundFromByteArray(byte[] byteArray)
		{
			_playingSounds.Add(
				new SoundHandle(byteArray)
					.OnComplete(Dispose)
					.Play()
			);
		}

		static void Dispose(SoundHandle handle)
		{
			_playingSounds.Remove(handle);
		}
	}

	extern(DOTNET) class SoundHandle
	{
		MemoryStream _memStream;
		Action<SoundHandle> _onComplete;

		public SoundHandle(byte[] bytes)
		{
			_memStream = new MemoryStream(bytes);
		}

		public SoundHandle Play()
		{
			new Thread(PlayTask).Start();
			return this;
		}

		void PlayTask()
		{
			using (_memStream)
			{
				new System.Media.SoundPlayer(_memStream).Play();
			}
			HandleComplete();
		}

		void HandleComplete()
		{
			if (_onComplete != null)
				_onComplete(this);
		}

		public SoundHandle OnComplete(Action<SoundHandle> disposeAction)
		{
			_onComplete = disposeAction;
			return this;
		}
	}
}

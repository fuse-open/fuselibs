
namespace Fuse
{
	public interface IRaw
	{
		object Raw { get; }
	}

	public interface IArray
	{
		int Length { get; }
		object this[int index] 
		{ 
			get; 
		}
	}
	public interface IObject
	{
		bool ContainsKey(string key);
		object this[string key]
		{
			get;
		}
		string[] Keys { get; }
	}
}
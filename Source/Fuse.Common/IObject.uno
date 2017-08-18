
namespace Fuse
{
	/** Represents an array-like collection.

		The underlaying type is not neccessarily an Uno array or collection.
		
		Allthough read-only through this interface, the array is not neccessarily immutable. 
		Changes to the array can only happen on the UI thread. This means the UI thread can safely
		read properties from this array.

		If the object also supports `Fuse.Reactive.IObservableArray, consumers can subscribe to the
		array to receive change notifications.
	*/
	public interface IArray
	{
		int Length { get; }
		object this[int index] 
		{ 
			get; 
		}
	}

	/** Represents a key-value object, where the keys can be enumerated and looked up by string name.

		The enumerable keys do not neccessarily correspond to Uno properties on the object.
	
		Allthough read-only through this interface, the object is not neccessarily immutable. 
		Changes to the object can only happen on the UI thread. This means the UI thread can safely
		read properties from this object.

		If the object also supports `Fuse.Reactive.IObservableObject`, consumers can subscribe
		to receive change notifications.
	*/
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
package com.fuse;

public class AndroidInteropHelper
{
	// This allows us to take a java exception and throw it, even though java usually
	// requires you to specify the exception in the signature.
	//
	// This is most useful when you want to throw a java exception to uno.
	//
	// This will be less useful when we have support for declaring these exceptions
	// in foreign code function signatures.
	//
	public static void UncheckedThrow(Throwable e)
	{
		AndroidInteropHelper.<RuntimeException>throwAny(e);
	}

	@SuppressWarnings("unchecked")
	private static <E extends Throwable> void throwAny(Throwable e) throws E
	{
		throw (E)e;
	}
}

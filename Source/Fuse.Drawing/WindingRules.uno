namespace Fuse.Drawing
{
	public static class WindingRules
	{
        public static bool Odd(int n)
        {
            return (n & 1) != 0;
        }
        public static bool NonZero(int n)
        {
            return (n != 0);
		}
        public static bool Positive(int n)
        {
            return (n > 0);
		}
        public static bool Negative(int n)
        {
            return (n < 0);
		}
		public static bool AbsoluteGreaterOrEqualsTwo(int n)
		{
	        return (n >= 2) || (n <= -2);
		}
	}
}
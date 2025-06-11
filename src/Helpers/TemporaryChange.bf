namespace BeefParser
{
	internal class TemporaryChange<T>
	{
		private T* mVariablePtr;
		private T mOldValue;

		public this(ref T variable, T value)
		{
			mVariablePtr = &variable;
			mOldValue = variable;

			*mVariablePtr = value;
		}

		public ~this()
		{
			*mVariablePtr = mOldValue;
		}
	}
}

using System.Diagnostics;

namespace BeefParser
{
	internal class ScopedValueRollback<T>
	{
		private T* mVariablePtr;
		private T mInitialValue;
		public bool Cancelled { get; private set; }
#if DEBUG
		public bool Manual;
#endif

		public this(ref T variable, bool manual = false)
		{
			mVariablePtr = &variable;
			mInitialValue = variable;
			Cancelled = manual;
#if DEBUG
			Manual = manual;
#endif
		}

		public ~this()
		{
			if (!Cancelled)
				*mVariablePtr = mInitialValue;
		}

		// Should be used only in Manual mode.
		public void Rollback()
		{
#if DEBUG
			Debug.Assert(Manual);
#endif
			*mVariablePtr = mInitialValue;
		}

		// Useless in Manual mode.
		public void Cancel()
		{
#if DEBUG
			Debug.Assert(!Manual);
#endif
			Cancelled = true;
		}
	}
}

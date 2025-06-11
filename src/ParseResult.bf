using System;

namespace BeefParser
{
	static
	{
		internal static mixin TryParse<T>(ParseResult<T> result)
		{
			if (result case .Err(var err))
				return .Err((.)err);
			result != .NotSuitable
		}
		internal static mixin Parse<T>(ParseResult<T> result)
		{
			if (result case .Err(var err1))
				return .Err((.)err1);
			if (result case .NotSuitable(var err2))
				return .Err((.)err2);
		}

		internal static mixin TryParseContinue<T>(ParseResult<T> result)
		{
			if (result case .Err(var err))
				return .Err((.)err);
			if (result case .Ok)
				continue;
			// Do nothing if not suitable
		}

		internal static mixin TryParseReturn<T>(ParseResult<T> result)
		{
			if (result case .Err(var err))
				return .Err((.)err);
			if (result case .Ok(var ok))
				return .Ok((.)ok);
			// Do nothing if not suitable
		}
	}

	enum ParseResult<T> : IDisposable
	{
		case Ok(T val);
		case NotSuitable(void err);
		case Err(void err);

		[Inline]
		T Unwrap()
		{
			switch (this)
			{
			case .Ok(var val): return val;
			case .NotSuitable, .Err:
				{
					Internal.FatalError("Unhandled error in result", 2);
				}
			}
		}

		public T Value
		{
			get
			{
				return Unwrap();
			}
		}

		public static implicit operator ParseResult<T>(T value)
		{
		    return .Ok(value);
		}

		public static implicit operator T(ParseResult<T> result)
		{
			return result.Unwrap();
		}

		public void IgnoreError()
		{
		}

		public T Get()
		{
			return Unwrap();
		}

		public T Get(T defaultVal)
		{
			if (this case .Ok(var val))
				return val;
			return defaultVal;
		}

		public T GetValueOrDefault()
		{
			if (this case .Ok(var val))
				return val;
			return default(T);
		}

		public static nullable(T) operator?(Self val)
		{
			switch (val)
			{
			case .Ok(let inner): return inner;
			case .NotSuitable, .Err: return null;
			}
		}

		[SkipCall]
		public void Dispose()
		{

		}

		[SkipCall]
		static void NoDispose<TVal>()
		{

		}

		static void NoDispose<TVal>() where TVal : IDisposable
		{
			Internal.FatalError("Result must be disposed", 1);
		}

		public void ReturnValueDiscarded()
		{
		    if (this case .NotSuitable(let err1))
				Internal.FatalError("Unhandled error in result", 1);
		    if (this case .Err(let err2))
				Internal.FatalError("Unhandled error in result", 1);
			NoDispose<T>();
		}
	}

	extension ParseResult<T> where T : IDisposable
	{
		public new void Dispose()
		{
			if (this case .Ok(var val))
				val.Dispose();
		}
	}
}

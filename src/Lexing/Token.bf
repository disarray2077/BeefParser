using System;

namespace BeefParser
{
	struct Token
	{
		public TokenType Type { get; set mut; }
		private StringView _value;
		public int Position { get; }

		public this(TokenType type, int position, StringView value)
		{
		    Type = type;
		    Position = position;
			_value = value;
		}

		public this(TokenType type, int position)
		{
		    Type = type;
		    Position = position;
			_value = .();
		}

		public override void ToString(String outStr)
		{
		    outStr.AppendF("Token({}, {})", Type, _value);
		}

		public int64 AsInteger()
		{
			var value = _value;
			if (_value.Contains('\''))
			{
				let str = scope:: String(_value);
				str.Replace("'", "");
				value = str;
			}
			// TODO: Maybe I should use uint64 instead of int64...?
			if (value.StartsWith("0x"))
			{
				if (value.Contains('-'))
					return int64.Parse(value.Substring(2), .Hex);
				else
					return (.)uint64.Parse(value.Substring(2), .Hex);

			}
			if (value.Contains('-'))
		    	return int64.Parse(value);
			else
		    	return (.)uint64.Parse(value);
		}

		public double AsReal()
		{
		    return double.Parse(_value);
		}

		public StringView AsText()
		{
		    return _value;
		}
	}
}

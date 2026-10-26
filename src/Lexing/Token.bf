using System;

namespace BeefParser
{
	struct Token
	{
		public TokenType Type { get; set mut; }
		private StringView _value = .();
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

		public char32 AsChar()
		{
			if (_value[0] != '\\')
				return _value.DecodedChars.GetNext();

			switch (_value[1])
			{
			case '0': return '\0';
			case 'a': return '\a';
			case 'b': return '\b';
			case 'f': return '\f';
			case 'n': return '\n';
			case 'r': return '\r';
			case 't': return '\t';
			case 'v': return '\v';
			case '\\', '"', '\'': return _value[1];
			case 'x', 'u':
				let digits = _value[1] == 'x' ? _value.Substring(2) : _value.Substring(3, _value.Length - 4);
				uint32 value = uint32.Parse(digits, .Hex);
				return (char32)value;
			default:
				Runtime.FatalError("Invalid character literal");
			}
		}

		public double AsReal()
		{
			if (_value.Contains('\''))
			{
				let value = scope String(_value);
				value.Replace("'", "");
				return double.Parse(value);
			}
			return double.Parse(_value);
		}

		public StringView AsText()
		{
		    return _value;
		}
	}
}

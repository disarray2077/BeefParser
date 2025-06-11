using System;
using System.Collections;
using System.Diagnostics;

namespace BeefParser
{
	typealias SourcePosition = (StringView lineText, int line, int collumn);

	public class Lexer
	{
	    private static Dictionary<String, TokenType> ReservedKeywords = new Dictionary<String, TokenType>() ~ Release!(_);

	    private String _text ~ if (_ownsText) delete _;
		private bool _ownsText;
	    private int _pos;
	    private char8 _currentChar;

		private bool _interpolation = false;
		private bool _interpolationStarted = false;

		static this()
		{
			for (let field in typeof(TokenType).GetFields())
			{
				let fieldData = field.[Friend]mFieldData;
				if ((TokenType)fieldData.mData == TokenType.IntegerLiteral)
					break;

				ReservedKeywords.Add(new String(fieldData.mName)..ToLower(), (TokenType)fieldData.mData);
			}
		}

	    public this(String text, bool copyText = true)
	    {
			_text = !copyText ? text : new .(text);
			_ownsText = copyText;
	        _pos = 0;
	        _currentChar = String.IsNullOrEmpty(text) ? '\0' : _text[_pos];
	    }

	    public bool getSourcePosition(int strPos, out SourcePosition result)
	    {
			result = ?;
	        var lines = _text.Split('\n');
	        var line = 0, collumn = 0, pos = 0;
	        for (var l in lines)
	        {
	            line += 1;
	            pos += l.Length + 1;
	            if (strPos < pos)
	            {
	                collumn = (l.Length + 1) - (pos - strPos);
					result = (l, line, collumn);
	                return true;
	            }
	        }
			return false;
	    }

		public int getCurrentPosition()
		{
			return _pos;
		}

	    private void advance()
	    {
	        _pos++;
	        if (_pos > _text.Length - 1)
	        {
	            _currentChar = '\0';
	            return;
	        }

	        _currentChar = _text[_pos];
#if LEXER_VERBOSE
			Console.Write(_currentChar);
#endif
	    }

	    private char8 peek(int offset = 1)
	    {
	        var peek_pos = _pos + offset;
	        if (peek_pos >= _text.Length)
	            return '\0';
	        return _text[peek_pos];
	    }

		private bool match(char8 c)
		{
		    if (_currentChar == c)
			{
				advance();
				return true;
			}
			return false;
		}

	    private void skipWhitespace()
	    {
	        while (_currentChar == ' ' || _currentChar == '\t' || _currentChar == '\r' || _currentChar == '\n')
	            advance();
	    }

	    private void skipComment(bool endInNewLine)
	    {
	        while ((endInNewLine || _currentChar != '*' || peek() != '/') &&
				   (!endInNewLine || _currentChar != '\n') &&
				   _currentChar != '\0')
	            advance();

			if (!endInNewLine && _currentChar == '*' && peek() == '/')
			{
	        	advance();
				advance();
			}
	    }

	    /// <summary>
	    /// Return a (multidigit) integer or float consumed from the input.
	    /// </summary>
	    private Result<Token, char8> number()
	    {
	        var startPos = _pos;

			if (_currentChar == '0' && peek() == 'x')
			{
				advance();
				advance();

				while (_currentChar.IsDigit  || _currentChar == '\'' || ((_currentChar >= 'a' && _currentChar <= 'f') || (_currentChar >= 'A' && _currentChar <= 'F')))
				    advance();
			}
			else
			{
		        while (_currentChar.IsDigit || _currentChar == '\'')
		            advance();
				
				var length = _pos - startPos; 
				StringView result = .(_text, startPos, length);
				var floatingPoint = false;

		        if (_currentChar == '.')
		        {
					if (floatingPoint)
						return .Err(_currentChar);

					floatingPoint = true;
		            advance();
	
		            while (_currentChar.IsDigit)
		                advance();
	
					length = _pos - startPos;	
					result = .(_text, startPos, length);
		        }

				if (_currentChar.ToLower == 'f')
				{
					advance();
					return .Ok(.(TokenType.FloatLiteral, startPos, result));
				}
				else if (_currentChar.ToLower == 'l' ||
						 _currentChar.ToLower == 'u')
				{
					if (floatingPoint)
						return .Err(_currentChar);

					// TODO: Do something here?

					if (peek().ToLower == 'l' || peek().ToLower == 'u')
						advance();
					advance();
					return .Ok(.(TokenType.IntegerLiteral, startPos, result));
				}
				else if (floatingPoint || _currentChar.ToLower == 'd')
				{
					if (_currentChar.ToLower == 'd')
						advance();
					return .Ok(.(TokenType.DoubleLiteral, startPos, result));
				}
			}

			var length = _pos - startPos; 
			StringView result = .(_text, startPos, length);

	        return .Ok(.(TokenType.IntegerLiteral, startPos, result));
	    }

	    private Token identifier(bool forceIdentifier = false)
	    {
			if (forceIdentifier)
				advance();

	        var startPos = _pos;

	        while (_currentChar.IsLetter || _currentChar.IsDigit || _currentChar == '_')
	            advance();

			int length = _pos - startPos;
			StringView result = .(_text, startPos, length);

			TokenType type;
	        if (!forceIdentifier && ReservedKeywords.TryGetValueAlt(result, out type))
	            return .(type, startPos, result);
	        return .(TokenType.Identifier, startPos, result);
	    }

	    private Result<Token, char8> str(bool isVerbatim, bool isInterpolation = false)
	    {
	        var startPos = _pos;

	        while (true)
	        {
				if (_currentChar == '\0' || (!isVerbatim && _currentChar == '\n'))
					return .Err(_currentChar);

				if (isInterpolation && (_currentChar == '{' || _currentChar == '"'))
					break;

	            if (_currentChar == '"')
	            {
					advance();
					if (!isVerbatim || _currentChar != '"')
						break;
				}

				if (!isVerbatim && _currentChar == '\\')
				{
					switch (peek())
					{
					case '"', '\\':
						advance();
					}
					
					// TODO: Parse \1, \x03, etc
				}

	            advance();
	        }		   

			int length = (_pos - 1) - startPos;
			StringView result = .(_text, startPos, length);

	        return .Ok(.(isInterpolation ? TokenType.InterpolatedStringText : TokenType.StringLiteral, startPos, result));
	    }

		private Result<Token, char8> chr()
		{
		    advance();
		    var startPos = _pos;

		    while (true)
		    {
				if (_currentChar == '\0' || _currentChar == '\n')
					return .Err(_currentChar);

		        if (_currentChar == '\'')
		        {
					advance();
					break;
				}

				if ((_pos - 1) - startPos > 1)
					return .Err(_currentChar);

				if (_currentChar == '\\')
				{
					switch (peek())
					{
					case '\'', '\\':
						advance();
					}

					// TODO: Parse \1, \x03, etc
				}

		        advance();
		    }

			int length = (_pos - 1) - startPos;
			StringView result = .(_text, startPos, length);

			if (result.IsEmpty)
				return .Err('\'');

		    return .Ok(.(TokenType.CharLiteral, startPos, result));
		}

	    /// <summary>
	    /// Lexical analyzer (also known as scanner or tokenizer)
	    /// This method is responsible for breaking a sentence
	    /// apart into tokens. One token at a time.
	    /// </summary>
	    public Result<Token, char8> GetNextToken()
	    {
			bool isNewLine = true;

	        while (_currentChar != '\0')
	        {
				if (_interpolation)
				{
					if (_currentChar == '"')
					{
						if (_interpolationStarted)
							return .Err(_currentChar);
						advance();
						_interpolation = false;
						return .Ok(.(.InterpolatedStringEnd, _pos));
					}
					else if (_currentChar == '{')
					{
						if (_interpolationStarted)
							return .Err(_currentChar);
						advance();
						_interpolationStarted = true;
						return .Ok(.(.InterpolationStart, _pos));
					}
					else if (_currentChar == '}' && _interpolationStarted)
					{
						advance();
						_interpolationStarted = false;
						return .Ok(.(.InterpolationEnd, _pos));
					}
					else if (!_interpolationStarted)
					{
						return str(false, _interpolation);
					}
				}


				if (_currentChar == '#' && isNewLine)
				{
	                skipComment(true);
					continue;
				}

	            if (_currentChar == ' ' || _currentChar == '\t' || _currentChar == '\r' || _currentChar == '\n')
	            {
					if (_currentChar == '\n')
						isNewLine = true;
	                skipWhitespace();
	                continue;
	            }
				else
					isNewLine = false;

	            if (_currentChar == '/' && peek() == '*')
	            {
	                advance(); 
	                advance();
	                skipComment(false);
	                continue;
	            }

	            if (_currentChar == '/' && peek() == '/')
	            {
	                advance();
	                advance();
	                skipComment(true);
	                continue;
	            }

	            if (_currentChar == '"' || ((_currentChar == '@' || _currentChar == '$') && peek() == '"'))
				{
					bool isVerbatin = _currentChar == '@';
					bool isInterpolation = _currentChar == '$';
					advance();

					if (isInterpolation)
					{
						advance();
						_interpolation = true;
						return .Ok(.(.InterpolatedStringStart, _pos));
					}
					
					if (isVerbatin)
						advance();
	                return str(isVerbatin);
				}

	            if (_currentChar == '\'')
	                return chr();

	            if (_currentChar.IsDigit)
	                return number();

	            if (_currentChar.IsLetter || _currentChar == '_' ||
					(_currentChar == '@' && (peek().IsLetter || peek() == '_')))
	                return identifier(_currentChar == '@');

	            var position = _pos;
				var c = _currentChar;
				advance();

				switch (c)
				{
				case '+': if (match('+'))		return Token(TokenType.Increment, position);
						  else if (match('='))	return Token(TokenType.AddAssign, position);
						  else					return Token(TokenType.Plus, position);
				case '-': if (match('-'))		return Token(TokenType.Decrement, position);
						  else if (match('='))	return Token(TokenType.SubAssign, position);
						  else					return Token(TokenType.Minus, position);
				case '*': if (match('='))		return Token(TokenType.MulAssign, position);
						  else					return Token(TokenType.Mul, position);
				case '/': if (match('='))		return Token(TokenType.DivAssign, position);
						  else					return Token(TokenType.Div, position);
				case '(': return Token(TokenType.LParen, position);
				case ')': return Token(TokenType.RParen, position);
				case '{': return Token(TokenType.LCurly, position);
				case '}': return Token(TokenType.RCurly, position);
				case '[': return Token(TokenType.LBracket, position);
				case ']': return Token(TokenType.RBracket, position);
				case '=': if (peek() == '=' && match('=')) { match('='); return Token(TokenType.StrictEqual, position); }
						  else if (match('=')) 	return Token(TokenType.Equal, position);
						  else if (match('>'))	return Token(TokenType.Bind, position);
						  else 					return Token(TokenType.Assign, position);	 
				case ';': return Token(TokenType.Semi, position);
				case '.': if (peek() == '.' && match('.')) { match('.'); return Token(TokenType.DotDotDot, position); }
						  else if (match('.'))			return Token(TokenType.DotDot, position);
						  else							return Token(TokenType.Dot, position);
				case ':': if (match(':'))		return Token(TokenType.DoubleColon, position);
						  else					return Token(TokenType.Colon, position);
				case ',': return Token(TokenType.Comma, position);
				case '!': if (match('='))		return Token(TokenType.NotEqual, position);
						  else					return Token(TokenType.Not, position);
				case '>': if (peek() == '=' && match('>')) { match('='); return Token(TokenType.RShiftAssign, position); } // >>=
						  	   					//else 			return Token(TokenType.RShift, position);
						  else if (match('='))	return Token(TokenType.GreaterEq, position);
						  else					return Token(TokenType.RArrow, position);
				case '<': if (match('<'))		if (match('=')) return Token(TokenType.LShiftAssign, position);
												else			return Token(TokenType.LShift, position);
						  else if (peek() == '>' && match('=')) { match('>'); return Token(TokenType.Spaceship, position); } // <=>
						  else if (match('='))	return Token(TokenType.LesserEq, position);
						  else					return Token(TokenType.LArrow, position);
				case '#': return Token(TokenType.HashTag, position);
				case '~': return Token(TokenType.Tilde, position);
				case '@': return Token(TokenType.Verbatim, position);
				case '&': if (match('&'))		return Token(TokenType.And, position);
						  else if (match('='))	return Token(TokenType.BitAndAssign, position);
						  else					return Token(TokenType.BitwiseAnd, position);
				case '|': if (match('|'))		return Token(TokenType.Or, position);
						  else if (match('='))	return Token(TokenType.BitOrAssign, position);
						  else					return Token(TokenType.BitwiseOr, position);
				case '^': if (match('='))		return Token(TokenType.BitXorAssign, position);
						  else					return Token(TokenType.BitwiseXor, position);
				case '?': if (match('?'))		return Token(TokenType.NullCoarl, position);
						  else if (match('.'))  return Token(TokenType.NullCond, position);
						  else					return Token(TokenType.QuestionMark, position);
				case '%': if (match('='))		return Token(TokenType.ModAssign, position);
						  else					return Token(TokenType.Module, position);
				case '$': return Token(TokenType.Dollar, position);
				}

	            return .Err(c);
	        }

	        return Token(TokenType.EOF, _pos);
	    }

		public Result<void, char8> GetAllTokens(ref List<Token> tokens)
		{
			var token = Try!(GetNextToken());
			tokens.Add(token);

			while (token.Type != TokenType.EOF)
			{
			    tokens.Add(token = Try!(GetNextToken()));
			}

			return .Ok;
		}

		public bool IsKeyword(TokenType type)
		{
			return ReservedKeywords.ContainsValue(type);
		}
	}
}

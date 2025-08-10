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
		private int _interpolationDollarCount = 0;
		private bool _isMultilineString = false;
		private bool _isVerbatimString = false;

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

		private Result<Token, char8> str(bool isVerbatim, bool isMultiline, bool isInterpolation)
		{
		    var startPos = _pos;

		    while (true)
		    {
		        if (_currentChar == '\0')
		            return .Err(_currentChar);

		        if (!isMultiline && _currentChar == '\n')
		            return .Err(_currentChar);

		        if (isInterpolation && _currentChar == '{')
		        {
				    int braceCount = 0;
				    int checkPos = _pos;
				    while (checkPos < _text.Length && _text[checkPos] == '{')
				    {
				        braceCount++;
				        checkPos++;
				    }

				    // One escaped literal "{" is 2 * _interpolationDollarCount opening braces.
				    // Consume as many complete escape pairs as possible as plain text.
				    int pairWidth = 2 * _interpolationDollarCount;
				    if (braceCount >= pairWidth)
				    {
				        int toConsume = (braceCount / pairWidth) * pairWidth;
				        for (int i = 0; i < toConsume; i++)
				            advance();
				        continue;
				    }

				    if (braceCount == _interpolationDollarCount)
				        break;
		        }

				if (!isMultiline)
				{
					if (_currentChar == '"')
						break;
				}
				else
				{
					if (_currentChar == '"' && peek() == '"' && peek(2) == '"')
						break;
				}

		        if (!isVerbatim && !isMultiline && _currentChar == '\\')
		        {
		            switch (peek())
		            {
						case '"', '\\':
							advance();
		            }
		            // TODO: Parse other escapes: \n, \x03, \u, etc
		        }

		        advance();
		    }

		    int length = _pos - startPos;

			// Try to trim the last line if this is a multiline string ending now.
			if (isMultiline && _currentChar == '"' && peek() == '"' && peek(2) == '"')
			{
			    StringView content = .(_text, startPos, length);
			    int lastNewlineIdx = content.LastIndexOf('\n');

			    if (lastNewlineIdx != -1)
			    {
			        bool isLastLineWhitespace = true;
			        for (int i = lastNewlineIdx + 1; i < content.Length; i++)
			        {
			            char8 c = content[i];
			            if (c != ' ' && c != '\t')
			            {
			                isLastLineWhitespace = false;
			                break;
			            }
			        }

			        if (isLastLineWhitespace)
			        {
			            length = lastNewlineIdx;
			        }
					else
					{
						return .Err(_currentChar);
					}
			    }
				else
				{
					return .Err(_currentChar);
				}
			}

		    StringView result = .(_text, startPos, length);

		    if (isInterpolation)
				return .Ok(.(TokenType.InterpolatedStringText, startPos, result));

			if (isMultiline)
			{
				advance(); advance(); advance(); // """
			}
			else
			{
				advance(); // "
			}

			return .Ok(.(TokenType.StringLiteral, startPos, result));
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
					int CountRun(char8 ch)
					{
						int i = 0;
						while ((_pos + i) < _text.Length && _text[_pos + i] == ch)
							i++;
						return i;
					}

					if (!_interpolationStarted)
					{
						if ((!_isMultilineString && _currentChar == '"') ||
							(_isMultilineString && _currentChar == '"' && peek() == '"' && peek(2) == '"'))
						{
							if (_isMultilineString)
							{
								advance(); advance(); advance();
							}
							else
							{
								advance();
							}
							_interpolation = false;
							_isMultilineString = false;
							_isVerbatimString = false;
							_interpolationDollarCount = 0;
							return .Ok(.(.InterpolatedStringEnd, _pos));
						}

						int openCount = CountRun('{');
						if (openCount == _interpolationDollarCount)
						{
						    for (int i = 0; i < _interpolationDollarCount; i++)
						        advance();

						    _interpolationStarted = true;
						    return .Ok(.(.InterpolationStart, _pos));
						}

						return str(_isVerbatimString, _isMultilineString, true);
					}
					else
					{
						int closeCount = CountRun('}');
						if (closeCount >= _interpolationDollarCount)
						{
						    for (int i = 0; i < _interpolationDollarCount; i++)
						        advance();

						    _interpolationStarted = false;
						    return .Ok(.(.InterpolationEnd, _pos));
						}
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

				if (_currentChar == '"' || _currentChar == '@' || _currentChar == '$')
				{
					int scanPos = _pos;
					int dollarCount = 0;
					bool verbatim = false;

					while (scanPos < _text.Length && (_text[scanPos] == '$' || _text[scanPos] == '@'))
					{
						if (_text[scanPos] == '$') dollarCount++;
						if (_text[scanPos] == '@') verbatim = true;
						scanPos++;
					}

					if (scanPos < _text.Length && _text[scanPos] == '"')
					{
						bool multiline = (scanPos + 2 < _text.Length && _text[scanPos + 1] == '"' && _text[scanPos + 2] == '"');
						int prefixLength = scanPos - _pos;

						for (int i = 0; i < prefixLength; i++)
						    advance();

						if (multiline)
						{
							advance(); advance(); advance(); // """
							if (_currentChar == '\n')
							{
							    advance();
							}
							else if (_currentChar == '\r' && peek() == '\n')
							{
							    advance();
							    advance();
							}
							else
							{
								return .Err(_currentChar);
							}
						}
						else
						{
							advance(); // "
						}

						if (dollarCount > 0)
						{
							_interpolation = true;
							_interpolationStarted = false;
							_interpolationDollarCount = dollarCount;
							_isMultilineString = multiline;
							_isVerbatimString = verbatim;

							var dollarSignsView = StringView(_text, _pos - prefixLength, dollarCount);
							return .Ok(.(.InterpolatedStringStart, _pos, dollarSignsView));
						}
						else
						{
							return str(verbatim, multiline, false);
						}
					}
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

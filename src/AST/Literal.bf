using System;
using System.Diagnostics;
using System.Reflection;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class Literal : Expression
	{
		public static IdentifierExpr MakeLiteral(String str)
		{
			return new IdentifierExpr(str);
		}

		public static IdentifierExpr MakeLiteral(StringView str)
		{
			return new IdentifierExpr(str);
		}

		public static IntLiteral MakeLiteral(int64 int)
		{
			return new IntLiteral((.)int);
		}

		public static ASTNode MakeLiteral(Object obj)
		{
			let type = obj.GetType();
			switch (type.IsBoxed ? type.UnderlyingType : type)
			{
			case typeof(String):
				Runtime.Assert(Convert.ConvertTo(obj, typeof(String)) case .Ok(let val));
				return MakeLiteral(val.Get<String>());
			case typeof(StringView):
				Runtime.Assert(Convert.ConvertTo(obj, typeof(StringView)) case .Ok(let val));
				return MakeLiteral(val.Get<StringView>());
			case typeof(Int), typeof(Int64), typeof(Int32), typeof(Int16), typeof(Int8),
				 typeof(UInt), typeof(UInt64), typeof(UInt32), typeof(UInt16), typeof(UInt8):
				Runtime.Assert(Convert.ToInt64(obj) case .Ok(let val));
				return MakeLiteral(val);
			default:
				Runtime.NotImplemented();
			}
		}
	}

	[ImplementAccept, ImplementToString]
	class BoolLiteral : Literal
	{
		public bool Value { get; set; }

		public this(bool value)
		{
			Value = value;
		}
	}

	[ImplementAccept, ImplementToString]
	class CharLiteral : Literal
	{
		public char32 Value { get; set; }

		public this(char32 value)
		{
			Value = value;
		}
	}
	
	[ImplementAccept, ImplementToString]
	class IntLiteral : Literal
	{
		public IntType Type { get; set; }
		public IntKind Kind { get; set; }
		public int64 Value { get; set; }

		public this(int64 value)
		{
			Value = value;
		}
	}

	[ImplementAccept, ImplementToString]
	class NullLiteral : Literal
	{
	}

	
	[ImplementAccept, ImplementToString]
	class RealLiteral : Literal
	{
		public RealType Type { get; set; }
		public double Value { get; set; }

		public this(RealType type, double value)
		{
			Type = type;
			Value = value;
		}
	}

	[ImplementAccept, ImplementToString]
	class StrLiteral : Literal
	{
		private String mValue ~ delete _;

		public StringView Value
		{
			get => mValue;
			set => String.NewOrSet!(mValue, value);
		}

		public this(StringView value)
		{
			Value = value;
		}
	}
}

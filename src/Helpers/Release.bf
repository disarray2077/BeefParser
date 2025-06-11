using System;
using System.Collections;

namespace BeefParser
{
	static
	{
		public enum ContainerReleaseKind
		{
			Items = 1 << 0,
			Self = 1 << 1,
	
			Default = Items | Self,
		}
	
		public enum DictionaryReleaseKind
		{
			Keys = 1 << 0,
			Values = 1 << 1,
			Self = 1 << 2,
	
			Items = Keys | Values,
			Default = Keys | Values | Self,
		}
	}
	
	static
	{
		// Common case for any value type
		[SkipCall]
		public static mixin Release<T>(T value)
			where T : struct
		{
		    // do nothing
		}
	
		// Common case for any nullable value type
		[SkipCall]
		public static mixin Release<T>(T? value)
			where T : struct
		{
		    // do nothing
		}
	
		// Types can't be deleted
		// NOTE: idk if theres a more generic way to check this...
		[SkipCall]
		public static mixin Release(Type value)
		{
		    // do nothing
		}
	
		// We need to release only a reference for IRefCounted types.
		[Inline] static void DoRelease<T>(T value) where T : IRefCounted => value?.Release(); // TODO: Hack to get around a compiler bug!
		public static mixin Release<T>(T value)
			where T : IRefCounted, class, delete
		{
			//value?.Release();
			DoRelease(value);
		}
	
		// Dispose IDisposable value types
		public static mixin Release<T>(T value)
			where T : struct, IDisposable
		{
			value.Dispose();
		}
	
		// Dispose nullable IDisposable value types
		public static mixin Release<T>(T? value)
			where T : struct, IDisposable
		{
			value?.Dispose();
		}
	
		// Delete deletable types
		public static mixin Release<T>(T value)
			where T : class, delete
		{
			delete value;
		}
	
		// Delete deletable types
		public static mixin Release<K, V>((K key, V value) kv)
			where K : var
			where V : var
		{
			Release!(kv.key);
			Release!(kv.value);
		}
	
		// Delete array items and then the array itself
		public static mixin Release<T>(T[] value, ContainerReleaseKind kind = ContainerReleaseKind.Default) where T : var
		{
			if (value != null)
			{
				if (kind.HasFlag(.Items))
					ReleaseItems!(value);
				if (kind.HasFlag(.Self))
					delete value;
			}
		}
	
		// Delete multidimensional array items and then the array itself
		public static mixin Release<T>(T[,] value, ContainerReleaseKind kind = ContainerReleaseKind.Default) where T : var
		{
			if (value != null)
			{
				if (kind.HasFlag(.Items))
					ReleaseItems!(value);
				if (kind.HasFlag(.Self))
					delete value;
			}
		}
	
		// Delete multidimensional array items and then the array itself
		public static mixin Release<T>(T[,,] value, ContainerReleaseKind kind = ContainerReleaseKind.Default) where T : var
		{
			if (value != null)
			{
				if (kind.HasFlag(.Items))
					ReleaseItems!(value);
				if (kind.HasFlag(.Self))
					delete value;
			}
		}
	
		// Delete multidimensional array items and then the array itself
		public static mixin Release<T>(T[,,,] value, ContainerReleaseKind kind = ContainerReleaseKind.Default) where T : var
		{
			if (value != null)
			{
				if (kind.HasFlag(.Items))
					ReleaseItems!(value);
				if (kind.HasFlag(.Self))
					delete value;
			}
		}
	
		// Delete fixed array items
		public static mixin Release<T, U>(T[U] value)
			where T : var
			where U : const int
		{
			for (int i = 0; i < U; i++)
				Release!(value[i]);
		}
	
		// Delete list items and then the list itself
		public static mixin Release<T>(List<T> value, ContainerReleaseKind kind = ContainerReleaseKind.Default)
			where T : var
		{
			if (value != null)
			{
				if (kind.HasFlag(.Items))
					ReleaseItems!(value);
				if (kind.HasFlag(.Self))
					delete value;
			}
		}
	
		// Delete queue items and then the queue itself
		public static mixin Release<T>(Queue<T> value, ContainerReleaseKind kind = ContainerReleaseKind.Default)
			where T : var
		{
			if (value != null)
			{
				if (kind.HasFlag(.Items))
					ReleaseItems!(value);
				if (kind.HasFlag(.Self))
					delete value;
			}
		}
	
		// Delete dictionary keys and values and then the dictionary itself
		public static mixin Release<K, V>(Dictionary<K, V> value, DictionaryReleaseKind kind = DictionaryReleaseKind.Default)
			where K : var, IHashable
			where V : var
		{
			if (value != null)
			{
				for (let kv in ref value)
				{
					if (kind.HasFlag(.Keys))
						Release!(kv.key);
					if (kind.HasFlag(.Values))
						Release!(*kv.valueRef);
				}
				if (kind.HasFlag(.Self))
					delete value;
			}
		}
	
		// Currently doesn't work, conflict with another Release(), maybe it's a compiler bug..?
		/*public static mixin Release<T, U>(T value)
			where T : delete, concrete, IEnumerable<U>
			where U : var
		{
			ReleaseItems!(value);
			delete value;
		}*/
	
		public static mixin ReleaseAndNullify(var value)
		{
			Release!(value);
			value = null;
		}
	
		// Delete enumerable items
		public static mixin ReleaseItems(var value)
		{
			for (let item in value)
				Release!(item);
		}
	
		// Delete and nullify enumerable items (by reference)
		public static mixin ReleaseAndNullifyItems(var value)
		{
			for (var item in ref value)
				ReleaseAndNullify!(item);
		}
	
		public static mixin ReleaseItemsAndClear(var value)
		{
			ReleaseItems!(value);
			value.Clear();
		}
	}
}

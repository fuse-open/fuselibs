using Uno;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace Fuse.Scripting.Duktape
{

	[TargetSpecificType]
	internal extern(USE_DUKTAPE) struct duk_context
	{
	}

	internal extern(USE_DUKTAPE) delegate int callback(duk_context ctx);

	[TargetSpecificImplementation]
	internal extern(USE_DUKTAPE) static class duktape
	{
		internal const int DUK_VARARGS = -1;

		internal static IntPtr alloc(this duk_context ctx, uint size)
		@{
			return duk_alloc($0, $1);
		@}

		internal static IntPtr alloc_raw(this duk_context ctx, uint size)
		@{
			return duk_alloc_raw($0, $1);
		@}

		internal static void enum_own_properties(this duk_context ctx, int index)
		@{
			duk_enum($0, $1, DUK_ENUM_OWN_PROPERTIES_ONLY);
		@}

		internal static bool next(this duk_context ctx, int index, bool getValue)
		@{
			return duk_next($0, $1, $2);
		@}

		internal static void base64_decode(this duk_context ctx, int index)
		@{
			duk_base64_decode($0, $1);
		@}

		internal static string base64_encode(this duk_context ctx, int index)
		@{
			return uString::Utf8(duk_base64_encode($0, $1));
		@}

		internal static int pcall(this duk_context ctx, int nargs)
		@{
			return duk_pcall($0, $1);
		@}

		internal static int pcall_method(this duk_context ctx, int nargs)
		@{
			return duk_pcall_method($0, $1);
		@}

		internal static int pcall_prop(this duk_context ctx, int obj_index, int nargs)
		@{
			return duk_pcall_prop($0, $1, $2);
		@}

		internal static int char_code_at(this duk_context ctx, int index, uint char_offset)
		@{
			return duk_char_code_at($0, $1, $2);
		@}

		internal static bool check_stack(this duk_context ctx, int extra)
		@{
			return duk_check_stack($0, $1);
		@}

		internal static bool check_stack_top(this duk_context ctx, int top)
		@{
			return duk_check_stack_top($0, $1);
		@}

		internal static bool check_type(this duk_context ctx, int index, int type)
		@{
			return duk_check_type($0, $1, $2);
		@}

		internal static bool check_type_mask(this duk_context ctx, int index, uint mask)
		@{
			return duk_check_type_mask($0, $1, $2);
		@}

		internal static void compact(this duk_context ctx, int obj_index)
		@{
			duk_compact($0, $1);
		@}

		internal static void compile(this duk_context ctx, uint flags)
		@{
			duk_compile($0, $1);
		@}

		internal static void compile_file(this duk_context ctx, uint flags, string path)
		@{
			duk_compile_file($0, $1, uCString($2).Ptr);
		@}

		internal static void compile_lstring(this duk_context ctx, uint flags, string src, uint len)
		@{
			duk_compile_lstring($0, $1, uCString($2).Ptr, $3);
		@}

		internal static void compile_lstring_filename(this duk_context ctx, uint flags, string src, uint len)
		@{
			duk_compile_lstring_filename($0, $1, uCString($2).Ptr, $3);
		@}

		internal static int pcompile_string(this duk_context ctx, uint flags, string src)
		@{
			return duk_pcompile_string($0, $1, uCString($2).Ptr);
		@}

		internal static int pcompile(this duk_context ctx, uint flags)
		@{
			return duk_pcompile($0, $1);
		@}

		internal static void compile_string(this duk_context ctx, uint flags, string src)
		@{
			duk_compile_string($0, $1, uCString($2).Ptr);
		@}

		internal static void compile_string_filename(this duk_context ctx, uint flags, string src)
		@{
			duk_compile_string_filename($0, $1, uCString($2).Ptr);
		@}

		internal static void concat(this duk_context ctx, int count)
		@{
			duk_concat($0, $1);
		@}

		internal static void copy(this duk_context ctx, int from_index, int to_index)
		@{
			duk_copy($0, $1, $2);
		@}

		internal static void def_prop(this duk_context ctx, int obj_index, uint flags)
		@{
			duk_def_prop($0, $1, $2);
		@}

		internal static bool del_prop(this duk_context ctx, int obj_index)
		@{
			return duk_del_prop($0, $1);
		@}

		internal static bool del_prop_index(this duk_context ctx, int obj_index, int arr_index)
		@{
			return duk_del_prop_index($0, $1, $2);
		@}

		internal static bool del_prop_string(this duk_context ctx, int obj_index, string key)
		@{
			return duk_del_prop_string($0, $1, uCString($2).Ptr);
		@}

		internal static void dump_context_stderr(this duk_context ctx)
		@{
			duk_dump_context_stderr($0);
		@}

		internal static void dump_context_stdout(this duk_context ctx)
		@{
			duk_dump_context_stdout($0);
		@}

		internal static void dup(this duk_context ctx, int from_index)
		@{
			duk_dup($0, $1);
		@}

		internal static void dup_top(this duk_context ctx)
		@{
			duk_dup_top($0);
		@}

		internal static void enum_(this duk_context ctx, int obj_index, uint enum_flags)
		@{
			duk_enum($0, $1, $2);
		@}

		internal static bool equals(this duk_context ctx, int index1, int index2)
		@{
			return duk_equals($0, $1, $2);
		@}

		internal static void error(this duk_context ctx, string message)
		@{
			duk_error($0, DUK_ERR_ERROR, uCString($1).Ptr);
		@}

		internal static void eval(this duk_context ctx)
		@{
			duk_eval($0);
		@}

		internal static void eval_file(this duk_context ctx, string path)
		@{
			duk_eval_file($0, uCString($1).Ptr);
		@}

		internal static void eval_file_noresult(this duk_context ctx, string path)
		@{
			duk_eval_file_noresult($0, uCString($1).Ptr);
		@}

		internal static duk_context create_heap_default()
		@{
			return duk_create_heap_default();
		@}

		internal static void push_global_object(this duk_context ctx)
		@{
			duk_push_global_object($0);
		@}

		internal static void pop(this duk_context ctx)
		@{
			duk_pop($0);
		@}

		internal static int get_top(this duk_context ctx)
		@{
			return duk_get_top($0);
		@}

		internal static double to_number(this duk_context ctx, int index)
		@{
			return duk_to_number($0, $1);
		@}

		internal static void push_number(this duk_context ctx, double val)
		@{
			duk_push_number($0, $1);
		@}

		internal static bool put_prop_string(this duk_context ctx, int obj_index, string key)
		@{
			return duk_put_prop_string($0, $1, uCString($2).Ptr);
		@}

		internal static int peval_string(this duk_context ctx, string code)
		@{
			return duk_peval_string($0, uCString($1).Ptr);
		@}

		internal static void destroy_heap(this duk_context ctx)
		@{
			duk_destroy_heap($0);
		@}

		internal static int push_object(this duk_context ctx)
		@{
			return duk_push_object($0);
		@}

		internal static string json_encode(this duk_context ctx, int index)
		@{
			return uString::Utf8(duk_json_encode($0, $1));
		@}

		internal static void json_decode(this duk_context ctx, int index)
		@{
			duk_json_decode($0, $1);
		@}

		internal static void push_int(this duk_context ctx, int val)
		@{
			duk_push_int($0, $1);
		@}

		internal static void push_string(this duk_context ctx, string str)
		@{
			duk_push_string($0, uCString($1).Ptr);
		@}

		internal static bool get_prop_string(this duk_context ctx, int obj_index, string key)
		@{
			return duk_get_prop_string($0, $1, uCString($2).Ptr);
		@}

		internal static bool is_array(this duk_context ctx, int index)
		@{
			return duk_is_array($0, $1);
		@}

		internal static bool is_boolean(this duk_context ctx, int index)
		@{
			return duk_is_boolean($0, $1);
		@}

		internal static bool is_callable(this duk_context ctx, int index)
		@{
			return duk_is_callable($0, $1);
		@}

		internal static bool is_function(this duk_context ctx, int index)
		@{
			return duk_is_function($0, $1);
		@}

		internal static bool is_nan(this duk_context ctx, int index)
		@{
			return duk_is_nan($0, $1);
		@}

		internal static bool is_null(this duk_context ctx, int index)
		@{
			return duk_is_null($0, $1);
		@}

		internal static bool is_null_or_undefined(this duk_context ctx, int index)
		@{
			return duk_is_null_or_undefined($0, $1);
		@}

		internal static bool is_number(this duk_context ctx, int index)
		@{
			return duk_is_number($0, $1);
		@}

		internal static bool is_object(this duk_context ctx, int index)
		@{
			return duk_is_object($0, $1);
		@}

		internal static bool is_string(this duk_context ctx, int index)
		@{
			return duk_is_string($0, $1);
		@}

		internal static bool is_external_buffer(this duk_context ctx, int index)
		@{
			return duk_is_external_buffer($0, $1);
		@}

		internal static int peval_string_noresult(this duk_context ctx, string str)
		@{
			return duk_peval_string_noresult($0, uCString($1).Ptr);
		@}

		internal static void swap_top(this duk_context ctx, int index)
		@{
			duk_swap_top($0, $1);
		@}

		internal static int push_heapptr(this duk_context ctx, IntPtr ptr)
		@{
			return duk_push_heapptr($0, $1);
		@}

		internal static IntPtr get_heapptr(this duk_context ctx, int index)
		@{
			return duk_get_heapptr($0, $1);
		@}

		internal static void push_null(this duk_context ctx)
		@{
			duk_push_null($0);
		@}

		internal static double get_number(this duk_context ctx, int index)
		@{
			return duk_get_number($0, $1);
		@}

		internal static long get_length(this duk_context ctx, int index)
		@{
			return duk_get_length($0, $1);
		@}

		internal static string get_string(this duk_context ctx, int index)
		@{
			return uString::Utf8(duk_get_string($0, $1));
		@}

		internal static string safe_to_string(this duk_context ctx, int index)
		@{
			return uString::Utf8(duk_safe_to_string($0, $1));
		@}

		internal static bool get_boolean(this duk_context ctx, int index)
		@{
			return duk_get_boolean($0, $1);
		@}

		internal static void push_boolean(this duk_context ctx, bool value)
		@{
			duk_push_boolean($0, $1);
		@}

		internal static bool get_prop_index(this duk_context ctx, int index, int arr_index)
		@{
			return duk_get_prop_index($0, $1, $2);
		@}

		internal static bool put_prop_index(this duk_context ctx, int index, int arr_index)
		@{
			return duk_put_prop_index($0, $1, $2);
		@}

		internal static void pop_2(this duk_context ctx)
		@{
			duk_pop_2($0);
		@}

		internal static void pop_3(this duk_context ctx)
		@{
			duk_pop_3($0);
		@}

		internal static int push_array(this duk_context ctx)
		@{
			return duk_push_array($0);
		@}

		internal static void push_global_stash(this duk_context ctx)
		@{
			duk_push_global_stash($0);
		@}

		internal static int get_int(this duk_context ctx, int index)
		@{
			return duk_get_int($0, $1);
		@}

		internal static bool has_prop_string(this duk_context ctx, int index, string key)
		@{
			return duk_has_prop_string($0, $1, uCString($2).Ptr);
		@}

		internal static void new_(this duk_context ctx, int nargs)
		@{
			duk_new($0, $1);
		@}

		internal static void push_external_buffer(this duk_context ctx)
		@{
			duk_push_external_buffer($0);
		@}

		internal static void config_buffer(this duk_context ctx, int index, IntPtr ptr, int len)
		@{
			duk_config_buffer($0, $1, $2, $3);
		@}

		internal static IntPtr get_buffer(this duk_context ctx, int index, out int size)
		@{
			duk_size_t outSize;
			void* result = duk_get_buffer($0, $1, &outSize);
			*$2 = (@{int})outSize;
			return result;
		@}

		internal static IntPtr get_buffer_data(this duk_context ctx, int index, out int size)
		@{
			duk_size_t outSize;
			void* result = duk_get_buffer_data($0, $1, &outSize);
			*$2 = (@{int})outSize;
			return result;
		@}

		internal static void push_external_finalizer(this duk_context ctx)
		@{
			duk_push_c_function($0, duk_finalize_external, 1);
		@}

		internal static void set_finalizer(this duk_context ctx, int index)
		@{
			duk_set_finalizer($0, $1);
		@}

		internal static void push_callback_proxy(this duk_context ctx)
		@{
			duk_push_c_function($0, duk_callback_proxy, 2);
		@}

		internal static void push_array_buffer(this duk_context ctx, int index, int offset, int length)
		@{
			duk_push_buffer_object($0, $1, $2, $3, DUK_BUFOBJ_ARRAYBUFFER);
		@}

		internal static bool instanceof(this duk_context ctx, int index1, int index2)
		@{
			return duk_instanceof($0, $1, $2);
		@}
	}
}

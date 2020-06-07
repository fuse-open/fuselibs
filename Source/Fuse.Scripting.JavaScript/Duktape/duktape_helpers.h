#pragma once
#include "duktape.h"
@{Uno.Object:IncludeDirective}
@{Uno.Action<Uno.IntPtr>:IncludeDirective}

static duk_ret_t duk_callback_proxy(duk_context* ctx)
{
	duk_get_prop_string(ctx, 0, "Object");
	void* arguments = duk_get_heapptr(ctx, 1);
	duk_size_t size;
	@{Uno.Action<Uno.IntPtr>} cb = (@{Uno.Action<Uno.IntPtr>})duk_get_buffer(ctx, -1, &size);
	duk_pop(ctx);
	@{Uno.Action<Uno.IntPtr>:Of(cb):Call(arguments)};

	// Return value on top of the stack
	return 1;
}

static duk_ret_t duk_finalize_external(duk_context* ctx)
{
	// object being finalized is at stack index 0
	duk_get_prop_string(ctx, 0, "Object");
	duk_size_t size;
	@{object} o = (@{object})duk_get_buffer(ctx, -1, &size);
	duk_pop(ctx);
	uRelease(o);

	// Return 'undefined'
	return 0;
}

/**
 * Temple (C) Dylan Knutson, 2013, distributed under the:
 * Boost Software License - Version 1.0 - August 17th, 2003
 *
 * Permission is hereby granted, free of charge, to any person or organization
 * obtaining a copy of the software and accompanying documentation covered by
 * this license (the "Software") to use, reproduce, display, distribute,
 * execute, and transmit the Software, and to prepare derivative works of the
 * Software, and to permit third-parties to whom the Software is furnished to
 * do so, all subject to the following:
 *
 * The copyright notices in the Software and this entire statement, including
 * the above license grant, this restriction and the following disclaimer,
 * must be included in all copies of the Software, in whole or in part, and
 * all derivative works of the Software, unless such copies or derivative
 * works are solely in the form of machine-executable object code generated by
 * a source language processor.
 */

module temple.temple_context;

import temple.temple;
import temple.output_stream;

public import std.variant : Variant;
private import std.array, std.string, std.typetuple;

class TempleContext
{
private:
	// First hook is called to set the output buffer, the second is to unset it.
	alias TemplateHooks = TypeTuple!(void delegate(OutputStream), void delegate());
	TemplateHooks[0][] pushBuffHooks;
	TemplateHooks[1][] popBuffHooks;

	Variant[string] vars;

	TempleFuncType* yielded_template;


	TemplateHooks[0] getPushBuffHook()
	{
		return pushBuffHooks[$-1];
	}

	TemplateHooks[1] getPopBuffHook()
	{
		return popBuffHooks[$-1];
	}

public:
	/// private
	void popTemplateHooks()
	{
		pushBuffHooks.length--;
		popBuffHooks.length--;
	}

	/// private
	void pushTemplateHooks(TemplateHooks h)
	{
		this.pushBuffHooks ~= h[0];
		this.popBuffHooks ~= h[1];
	}

	string capture(T...)(void delegate(T) block, T args)
	{
		auto buffer = new AppenderOutputStream();
		scope(exit) { buffer.clear(); }

		this.getPushBuffHook()(buffer);
		block(args);
		this.getPopBuffHook()();
		return buffer.data;
	}

	void partial(TempleFuncType* temple_func) @property
	{
		yielded_template = temple_func;
	}

	auto partial() @property
	{
		return yielded_template;
	}

	bool isSet(string name)
	{
		return (name in vars && vars[name] != Variant());
	}

	ref Variant var(string name) @property
	{
		if(name !in vars)
			vars[name] = Variant();

		return vars[name];
	}

	VarDispatcher var() @property
	{
		return VarDispatcher(this);
	}

	Variant opDispatch(string op)() @property
	{
		return vars[op];
	}

	void opDispatch(string op, T)(T other) @property
	{
		vars[op] = other;
	}

	static string renderWith(string file)(TempleContext ctx = null)
	{
		alias render_func = TempleFile!(file);

		if(ctx is null)
		{
			ctx = new TempleContext();
		}
		auto buff = new AppenderOutputStream();
		scope(exit) { buff.clear(); }

		render_func(buff, ctx);
		return buff.data();
	}

	string render(string file)()
	{
		return TempleContext.renderWith!(file)(this);
	}

	string yield()
	{
		auto buff = new AppenderOutputStream();
		scope(exit) { buff.clear(); }

		if(yielded_template is null)
		{
			return "";
		}
		else
		{
			(*yielded_template)(buff, this);
			return buff.data;
		}
	}
}

private struct VarDispatcher
{
private:
	TempleContext context;

public:
	this(TempleContext context)
	{
		this.context = context;
	}

	ref Variant opDispatch(string op)() @property
	{
		return context.var(op);
	}

	void opDispatch(string op, T)(T other) @property
	{
		context.var(op) = other;
	}
}

unittest
{
	auto context = new TempleContext();
	context.foo = "bar";
	context.bar = 10;

	with(context)
	{
		assert(var.foo == "bar");
		assert(var.bar == 10);

		var.baz = true;
		assert(var.baz == true);
	}
}
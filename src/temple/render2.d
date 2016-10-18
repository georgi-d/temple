///
module temple.render2;

import std.range.primitives : isOutputRange;

auto compile(string str, Args...)()
{
	return Context!(str, Args)();
}

struct Context(string str, Args...)
{
	void render(OR)(OR outputRange)
		//if (isOutputRange!OR)
	{
		import std.conv : to;
		import std.format : format;

		int x = g;

		outputRange.put(format("Context.render local var [x] %x %s\n", &x, x));

		outputRange.put("From alias: ");

		foreach (idx, arg; Args)
		{
			arg++;
			outputRange.put(format("[%s] %s: %s", Args[idx].stringof, &arg, arg));
		}

		outputRange.put("\n");
	}
}

__gshared int g = 111;

unittest
{
	import std.stdio;
	import std.range;
	import std.conv : to;
	import std.string : strip;

	static struct Point { float x, y; void opUnary(string op)() { x++; y++; } }

	int a = readln().strip.to!int;

	Point b = { x: 2, y: 4 };

	auto res = compile!("Some template", a, b, g);

	foreach (offset; iota(-32, 32, 4))
	{
		void* base = cast(void*)&res;
		auto p = base + offset;
		int* ip = cast(int*)p;
		float* fp = cast(float*)p;

		writefln("Base: %s, offeset: %s, p: %s, as int: %s, as float: %s",
			base, offset, p, *ip, *fp);
	}

	writefln("Global from unittest scope [g] %s: %s", &g, g);
	writefln("From unittest scope [a] %s: %s | [b] %s: %s", &a, a, &b, b);

	res.render(stdout.lockingTextWriter);

	writefln("Global from unittest scope [g] %s: %s", &g, g);
	writefln("From unittest scope %s: %s | %s: %s", &a, a, &b, b);
}

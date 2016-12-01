///
module temple.render2;

import std.range.primitives : isOutputRange;
import temple.output_stream  : TempleOutputStream, TempleInputStream;
import std.traits;

private import temple.func_string_gen2;

package string cttostring(T)(T x)
{
   static if( is(T == string) ) return x;
   else static if( is(T : long) || is(T : ulong) ){
      Unqual!T tmp = x;
      string s;
      do {
         s = cast(char)('0' + (tmp%10)) ~ s;
         tmp /= 10;
      } while(tmp > 0);
      return s;
   } else {
      static assert(false, "Invalid type for cttostring: "~T.stringof);
   }
}

/// When mixed in, makes all Args available in the local scope
template localAliases(int i, Args...)
{
   static if( i < Args.length ){
      enum string localAliases = "alias Args["~cttostring(i)~"] "~__traits(identifier, Args[i])~";\n"
         ~localAliases!(i+1, Args);
   } else {
      enum string localAliases = "";
   }
}

auto compile(string str, Args...)()
{
	return Context!(str, Args)();
}

struct Context(string str, Args...)
{
   mixin(localAliases!(0, Args));

   enum FuncStr = __temple_gen_temple_func_string(str, "__gdTemplateName",
                                                          "");
   pragma(msg, FuncStr);

   //void TempleFunc(ref TempleOutputStream sink)
   mixin(FuncStr);

	void render(OR)(OR outputRange)
		//if (isOutputRange!OR)
	{
      auto tos = TempleOutputStream(outputRange);
      TempleFunc(tos);
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

	int a = void;

	Point b = { x: 2, y: 4 };

	auto res = compile!("Some template <%= a %> ", a, b, g);
	auto res2 = compile!(`
                       % import std.stdio;
                       Before
                       <% foreach (i; 1..20) { %>
                        Index : <%= i %> : <%= b %>
                        <% } %>
                        After
                        `
                       , a, b, g);

	//foreach (offset; iota(-32, 32, 4))
	//{
		//void* base = cast(void*)&res;
		//auto p = base + offset;
		//int* ip = cast(int*)p;
		//float* fp = cast(float*)p;

		//writefln("Base: %s, offeset: %s, p: %s, as int: %s, as float: %s",
			//base, offset, p, *ip, *fp);
	//}

   writeln("RENDERING:");
	//writefln("From unittest scope [a] %s: %s | [b] %s: %s", &a, a, &b, b);

	res.render(stdout.lockingTextWriter);
   writeln("");
	res2.render(stdout.lockingTextWriter);
   writeln("");

	//writefln("Global from unittest scope [g] %s: %s", &g, g);
	//writefln("From unittest scope %s: %s | %s: %s", &a, a, &b, b);
}

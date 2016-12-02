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
   enum __localAliases = localAliases!(0, Args);

   enum __FuncStr = __temple_gen_temple_func_string(str, __localAliases,
                                                    "__gdTemplateName",
                                                    "");
   pragma(msg, __FuncStr);

   //void TempleFunc(ref TempleOutputStream sink)
   mixin(__FuncStr);

	void renderTo(OR)(OR outputRange)
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

   enum nested = "NestedBody <%= a %>";
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

	//auto res3 = compile!(`Nested template: <%= renderStr!(nested)  %> `, a, b,
                        //g, nested);

   writeln("RENDERING:");
	//writefln("From unittest scope [a] %s: %s | [b] %s: %s", &a, a, &b, b);

	res.renderTo(stdout.lockingTextWriter);
   writeln("");
	res2.renderTo(stdout.lockingTextWriter);
   writeln("");

	//res3.renderTo(stdout.lockingTextWriter);
   //writeln("");
}

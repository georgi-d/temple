void TempleFunc(ref TempleOutputStream sink) {

        void __temple_put_expr(T)(T expr) {

                // TempleInputStream should never be passed through
                // a filter; it should be directly appended to the stream
                static if(is(typeof(expr) == TempleInputStream))
                {
                        expr.into(sink);
                }

                // But other content should be filtered
                else
                {
                        __temple_buff_filtered_put(expr);
                }
        }

        TempleInputStream render(string __temple_file)() {
                return render_with!__temple_file();
        }

        void __temple_buff_filtered_put(T)(T thing)
        {
                import std.conv : to;
                sink.put(to!string(thing));
        }

        /// without filter, render subtemplate with an explicit context (which defaults to null)
        TempleInputStream render_with(string __temple_file)()
        {
                return TempleInputStream(delegate(ref TempleOutputStream s) {
                        auto nested = compile_file!(__temple_file)();
                        nested.render(s);
                });
        }

                #line 1 "__gdTemplateName"
                sink.put("Some template ");
                #line 1 "__gdTemplateName"
                __temple_put_expr(a);
                #line 1 "__gdTemplateName"
                sink.put(" ");
        }
}

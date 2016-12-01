static void TempleFunc(__gdFilter)(TempleContext __temple_context) {                                                                                                                                                                           [25/825]
        // Ensure that __temple_context is never null
        assert(__temple_context);

        void __temple_put_expr(T)(T expr) {

                // TempleInputStream should never be passed through
                // a filter; it should be directly appended to the stream
                static if(is(typeof(expr) == TempleInputStream))
                {
                        expr.into(__temple_context.sink);
                }

                // But other content should be filtered
                else
                {
                        __temple_buff_filtered_put(expr);
                }
        }

        deprecated auto renderWith(string __temple_file)(TempleContext tc = null)
        {
                return render_with!__temple_file(tc);
        }
        TempleInputStream render(string __temple_file)() {
                return render_with!__temple_file(__temple_context);
        }

        /// Run 'thing' through the Filter's templeFilter static
        void __temple_buff_filtered_put(T)(T thing)
        {
                static if(__traits(compiles, __gdFilter.templeFilter(__temple_context.sink, thing)))
                {
                        pragma(msg, "Deprecated: templeFilter on filters is deprecated; please use temple_filter");
                        __gdFilter.templeFilter(__temple_context.sink, thing);
                }
                else static if(__traits(compiles, __gdFilter.templeFilter(thing)))
                {
                        pragma(msg, "Deprecated: templeFilter on filters is deprecated; please use temple_filter");
                        __temple_context.put(__gdFilter.templeFilter(thing));
                }
                else static if(__traits(compiles, __gdFilter.temple_filter(__temple_context.sink, thing))) {
                        __gdFilter.temple_filter(__temple_context.sink, thing);
                }
                else static if(__traits(compiles, __gdFilter.temple_filter(thing)))
                {
                        __temple_context.put(__gdFilter.temple_filter(thing));
                }
                else {
                        // Fall back to templeFilter returning a string
                        static assert(false, "Filter does not have a case that accepts a " ~ T.stringof);
                }
        }

        /// with filter, render subtemplate with an explicit context (which defaults to null)
        TempleInputStream render_with(string __temple_file)(TempleContext tc = null)
        {
                return TempleInputStream(delegate(ref TempleOutputStream s) {
                        auto nested = compile_temple_file!(__temple_file, __gdFilter)();
                        nested.render(s, tc);
                });
        }

        with(__gdFilter)
        with(__temple_context) {
                #line 1 "__gdTemplateName"
                __temple_context.put("Some template");
        }
}

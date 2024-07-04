# This is a version of InteractiveUtils.gen_call_with_extracted_types, except that is passes back the
# call expression for further processing.
function extract_args(__module__, ex0)
    if isa(ex0, Expr)
        if any(a->(isexpr(a, :kw) || isexpr(a, :parameters)), ex0.args)
            arg1, args, kwargs = gensym("arg1"), gensym("args"), gensym("kwargs")
            return quote
                $arg1 = $(ex0.args[1])
                $args, $kwargs = $separate_kwargs($(ex0.args[2:end]...))
                tuple(Core.kwfunc($arg1), $kwargs, $arg1, $args...)
            end
        elseif ex0.head === :.
            return Expr(:tuple, :getproperty, ex0.args...)
        elseif ex0.head === :(<:)
            return Expr(:tuple, :(<:), ex0.args...)
        else
            return Expr(:tuple,
                mapany(x->isexpr(x,:parameters) ? QuoteNode(x) : x, ex0.args)...)
        end
    end
    if isexpr(ex0, :macrocall) # Make @edit @time 1+2 edit the macro by using the types of the *expressions*
        return error("Macros are not supported in @enter")
    end
    ex = Meta.lower(__module__, ex0)
    if !isa(ex, Expr)
        return error("expression is not a function call or symbol")
    elseif ex.head === :call
        return Expr(:tuple,
            mapany(x->isexpr(x, :parameters) ? QuoteNode(x) : x, ex.args)...)
    elseif ex.head === :body
        a1 = ex.args[1]
        if isexpr(a1, :call)
            a11 = a1.args[1]
            if a11 === :setindex!
                return Expr(:tuple,
                    mapany(x->isexpr(x, :parameters) ? QuoteNode(x) : x, arg.args)...)
            end
        end
    end
    return error("expression is not a function call, "
               * "or is too complex for @enter to analyze; "
               * "break it down to simpler parts if possible")
end

clear_caches() = nothing

function enter_call_expr(expr::Expr; enter_generated = false)
    clear_caches()
    r = determine_method_for_expr(expr; enter_generated = enter_generated)
    if r !== nothing && !isa(r[1], Compiled)
        frame = Frame(r[1])
        addargs!(frame, r[2:end]...)
        return frame
    end
    nothing
end

function determine_method_for_expr(expr::Expr; enter_generated = false)
    f = to_function(expr.args[1])
    allargs = expr.args
    # Extract keyword args
    kwargs = Expr(:parameters)
    if length(allargs) > 1 && isexpr(allargs[2], :parameters)
        kwargs = splice!(allargs, 2)::Expr
    end
    f, allargs = prepare_args(f, allargs, kwargs.args)
    return prepare_call(f, allargs; enter_generated=enter_generated)
end

function to_function(@nospecialize(x))
    isa(x, GlobalRef) ? getglobal(x.mod, x.name) : x
end

function prepare_args(@nospecialize(f), allargs, kwargs)
    if !isempty(kwargs)
        f = Core.kwfunc(f)
        allargs = Any[f, namedtuple(kwargs), allargs...]
    end
    return f, allargs
end

function prepare_call(@nospecialize(f), allargs; enter_generated = false)
    # Can happen for thunks created by generated functions
    if isa(f, Core.Builtin) || isa(f, Core.IntrinsicFunction)
        return nothing
    elseif any(is_vararg_type, allargs)
        return nothing  # https://github.com/JuliaLang/julia/issues/30995
    end
    argtypesv = Any[_Typeof(a) for a in allargs]
    argtypes = Tuple{argtypesv...}
    src = Base.code_typed_by_type(argtypes; debuginfo=:source)
    return (only(src).first, allargs[2:end]...)
end




"""
    @interpret f(args; kwargs...)

Evaluate `f` on the specified arguments using the interpreter.

# Example

```jldoctest
julia> a = [1, 7];

julia> sum(a)
8

julia> @interpret sum(a)
8
```
"""
macro interpret(arg)
    args = try
        extract_args(__module__, arg)
    catch e
        return :(throw($e))
    end
    quote
        local theargs = $(esc(args))
        local frame = IRCodeInterpreter.enter_call_expr(Expr(:call, theargs...))
        if frame === nothing
            eval(Expr(:call, map(QuoteNode, theargs)...))
        else
            local ret = IRCodeInterpreter.interpret(frame)
            # return ret
        end
    end
end

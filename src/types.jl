"""
`Compiled` is a trait indicating that any `:call` expressions should be evaluated
using Julia's normal compiled-code evaluation. The alternative is to pass `stack=Frame[]`,
which will cause all calls to be evaluated via the interpreter.
"""
struct Compiled end
Base.similar(::Compiled, sz) = Compiled()  # to support similar(stack, 0)

# # Our own replacements for Core types. We need to do this to ensure we can tell the difference
# # between "data" (Core types) and "code" (our types) if we step into Core.Compiler
# struct SSAValue
#     id::Int
# end
# struct SlotNumber
#     id::Int
# end

# Base.show(io::IO, ssa::SSAValue)    = print(io, "%J", ssa.id)
# Base.show(io::IO, slot::SlotNumber) = print(io, "_J", slot.id)

struct NoValue end
const novalue = NoValue()   # internal use only, equivalent to `nothing` but obviously not from user code

struct IntrinsicStatement
    f::Core.IntrinsicFunction
    callargs::Vector{Any}
    fillidx::Vector{Int}
end
struct BuiltinStatement
    f::Core.Builtin
    callargs::Vector{Any}
    fillidx::Vector{Int}
end

fillidx(@nospecialize(arg)) = isa(arg, SSAValue) ? arg.id :
                              isa(arg, SlotNumber) ? -arg.id :
                              isa(arg, Argument) ? -arg.n : 0

struct Frame
    src::CodeInfo
    optimized::Vector{Any}
    slotvalues::Vector{Any}
    ssavalues::Vector{Any}

    function Frame(src::CodeInfo)
        optimized = Vector{Any}(undef, length(src.code))
        slotvalues = fill!(Vector{Any}(undef, length(src.slotnames)), novalue)
        ssavalues = fill!(Vector{Any}(undef, length(src.code)), novalue)
        for (i, stmt) in enumerate(src.code)
            if isa(stmt, Expr)
                if stmt.head === :call
                    g = stmt.args[1]::GlobalRef
                    f = getglobal(g.mod, g.name)
                    if isa(f, Core.IntrinsicFunction)
                        optimized[i] = IntrinsicStatement(f, stmt.args[2:end], fillidx.(@view(stmt.args[2:end])))
                    elseif isa(f, Core.Builtin)
                        optimized[i] = BuiltinStatement(f, stmt.args[2:end], fillidx.(@view(stmt.args[2:end])))
                    else
                        error("invoke not handled yet")
                    end
                else
                    throw(ArgumentError("unsupported statement type: $stmt"))
                end
            else
                optimized[i] = stmt
            end
        end
        new(src, optimized, slotvalues, ssavalues)
    end
end

function addargs!(frame::Frame, args...)
    @assert length(args) == length(frame.slotvalues) - 1
    for (i, arg) in enumerate(args)
        frame.slotvalues[i+1] = arg
    end
    return frame
end

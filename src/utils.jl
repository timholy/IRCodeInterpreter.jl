function is_vararg_type(x)
    @static if isa(Vararg, Type)
        if isa(x, Type)
            (x <: Vararg && !(x <: Union{})) && return true
            if isa(x, UnionAll)
                x = Base.unwrap_unionall(x)
            end
            return isa(x, DataType) && nameof(x) === :Vararg
        end
    else
        return isa(x, typeof(Vararg))
    end
    return false
end

_Typeof(x) = isa(x, Type) ? Type{x} : typeof(x)

lookup(frame::Frame, @nospecialize(arg)) = isa(arg, SSAValue) ? frame.ssavalues[arg.id] :
                                           isa(arg, SlotNumber) ? frame.slotvalues[-arg.id] :
                                           isa(arg, Argument) ? frame.slotvalues[-arg.n] : arg
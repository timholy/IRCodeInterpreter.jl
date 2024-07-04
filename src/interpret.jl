function fillstatement!(stmt::Union{IntrinsicStatement, BuiltinStatement}, frame::Frame)
    for (i, j) in enumerate(stmt.fillidx)
        j == 0 && continue
        if j > 0
            stmt.callargs[i] = frame.ssavalues[j]
        else
            stmt.callargs[i] = frame.slotvalues[-j]
        end
    end
end

function interpret(frame::Frame)
    lastpc = 0
    pc = 1
    while true
        stmt = frame.optimized[pc]
        # @show lastpc pc stmt
        if isa(stmt, Core.PhiNode)
            found = false
            lastpc32 = Int32(lastpc)
            for (i, from) in enumerate(stmt.edges)
                if from == lastpc32
                    frame.ssavalues[pc] = lookup(frame, stmt.values[i])
                    found = true
                    break
                end
            end
            # @assert found
            # lastpc = pc
            pc += 1
        else
            lastpc = pc
            if isa(stmt, IntrinsicStatement)
                fillstatement!(stmt, frame)
                frame.ssavalues[pc] = ccall(:jl_f_intrinsic_call, Any, (Any, Ptr{Any}, UInt32), stmt.f, stmt.callargs, length(stmt.callargs))
                pc += 1
            elseif isa(stmt, BuiltinStatement)
                fillstatement!(stmt, frame)
                frame.ssavalues[pc] = callbuiltin(stmt)
                pc += 1
            elseif isa(stmt, GotoNode)
                pc = stmt.label
            elseif isa(stmt, GotoIfNot)
                pc = lookup(frame, stmt.cond) ? pc + 1 : stmt.dest
            elseif isa(stmt, ReturnNode)
                return lookup(frame, stmt.val)
            else
                error("unsupported statement type: $stmt")
            end
        end
    end
end

function callbuiltin(stmt::BuiltinStatement)
    (; f, callargs) = stmt
    if f === Core.arrayref
        if length(callargs) == 1
            return Core.arrayref(callargs[1])
        elseif length(callargs) == 2
            return Core.arrayref(callargs[1], callargs[2])
        elseif length(callargs) == 3
            return Core.arrayref(callargs[1], callargs[2], callargs[3])
        elseif length(callargs) == 4
            return Core.arrayref(callargs[1], callargs[2], callargs[3], callargs[4])
        elseif length(callargs) == 5
            return Core.arrayref(callargs[1], callargs[2], callargs[3], callargs[4], callargs[5])
        else
            return Core.arrayref(callargs...)
        end
    else
        error("builtin $f not handled yet")
    end
end

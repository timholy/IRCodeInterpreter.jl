module IRCodeInterpreter

using Core: CodeInfo, MethodInstance, SSAValue, SlotNumber, Argument, GotoNode, GotoIfNot, ReturnNode, PhiNode
using Base.Meta: isexpr
using Base: mapany

include("types.jl")
include("utils.jl")
include("interpret.jl")
include("construct.jl")

end

using IRCodeInterpreter
using Test

@testset "IRCodeInterpreter.jl" begin
    function summer(A::AbstractArray{T}) where T
        s = zero(T)
        for a in A
            s += a
        end
        return s
    end

    a = [1.2f0, 0.7f0]
    @test IRCodeInterpreter.@interpret summer(a) == 1.2f0 + 0.7f0
end

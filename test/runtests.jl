using MultiIndexArrays
using Test

@testset "MultiIndexArrays.jl" begin
    include("multi_index_axis_tests.jl")
    include("multi_index_array_tests.jl")
    include("multi_index_lazy_array_tests.jl")
end

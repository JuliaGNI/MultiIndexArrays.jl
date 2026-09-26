using SafeTestsets

const GROUPS = isempty(ARGS) ? ["core", "slow"] : ARGS

if "core" in GROUPS
    @safetestset "Aqua" include("quality/aqua.jl")
    @safetestset "Multi-index axis" include("multi_index_axis.jl")
    @safetestset "Multi-index array" include("multi_index_array.jl")
    @safetestset "Multi-index lazy array" include("multi_index_lazy_array.jl")
    @safetestset "Indices" include("indices.jl")
end

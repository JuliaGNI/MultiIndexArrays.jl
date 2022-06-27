module MultiIndexArrays

include("multi_index_axis.jl")
include("multi_index_array.jl")
include("multi_index_lazy_array.jl")

export AbstractMultiIndexArray
export MultiIndexAxis
export MultiIndexArray
export MultiIndexLazyArray

end

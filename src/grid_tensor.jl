### Grid Tensor

"""
    GridTensor(tensor::MultiIndexLazyArray, w::Integer)

A rank-`N` lazy array over a single grid, with a stencil of width `w`. It holds a
`MultiIndexLazyArray` — the coefficient function and the grid that `size` and `getindex`
use — and `w`, the width of the stencil that [`stencil_indices`](@ref) returns for it.

The axes of `tensor` must all be the same grid, because a grid tensor has one grid, and `w` must
be non-negative; each raises an `ArgumentError`. `GridTensor` keeps `Base`'s `OneTo` axes, so its
indices are the linear indices of that grid, in each of the index forms that
`MultiIndexLazyArray` takes. `Array(gt)` materialises it, `parent(gt)` is the array it
holds, and `gt[n]` is the `n`th entry of `Array(gt)`.

```julia
julia> gt = GridTensor(MultiIndexLazyArray(Float64, (I, J, K) -> 1.0, (2, 3), (2, 3), (2, 3)), 1);

julia> size(gt)
(6, 6, 6)

julia> gt[1, 2, 3]
1.0
```
"""
struct GridTensor{DT, N, MT <: MultiIndexLazyArray{DT, N}} <: AbstractArray{DT, N}
    tensor::MT
    width::Int

    # the checks live in the inner constructor, so that neither a parameterized nor an ordinary
    # call can build a tensor over several grids, or with a negative width
    function GridTensor{DT, N, MT}(tensor::MT, w::Integer) where {DT, N,
            MT <: MultiIndexLazyArray{DT, N}}
        allequal(axes(tensor)) || throw(ArgumentError(
            "a GridTensor is over one grid, but the axes of the lazy array are $(axes(tensor))"))
        w ≥ 0 || throw(ArgumentError("the stencil width must be non-negative, got $w"))
        return new{DT, N, MT}(tensor, Int(w))
    end
end

function GridTensor(tensor::MultiIndexLazyArray{DT, N}, w::Integer) where {DT, N}
    return GridTensor{DT, N, typeof(tensor)}(tensor, w)
end

Base.size(gt::GridTensor) = size(gt.tensor)

Base.parent(gt::GridTensor) = gt.tensor

Base.materialize(gt::GridTensor) = Base.materialize(parent(gt))

# one method for all three index forms, so that no pair of them ties at `N = 0`, and one index
# for a linear index into `Array(gt)`, which `AbstractArray` answers itself
Base.@propagate_inbounds function Base.getindex(gt::GridTensor{DT, N},
        inds::Vararg{Union{CartesianIndex, Tuple, Integer}, N}) where {DT, N}
    parent(gt)[inds...]
end

function stencil_indices(gt::GridTensor, i::Integer)
    stencil_indices(i, gt.width, size(axes(parent(gt), 1)))
end

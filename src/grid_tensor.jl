### Grid Tensor

"""
    GridTensor{DT, N}(f, sizes::NTuple{D, Int}, w::Integer)

A rank-`N` lazy array over the single grid of extents `sizes`, with a stencil of width `w`. Each
index of `gt[i, j, k]` is a node of the grid, given as its linear index, its `CartesianIndex` or
its tuple of coordinates, and the entry is `f(I, J, K)` of the `CartesianIndex`es of the nodes,
converted to `DT`. A negative `w` raises an `ArgumentError`.

`size(gt)` is `(n, …, n)` for the `n` nodes of the grid, `Array(gt)` materialises it, and
[`stencil_indices`](@ref) returns the stencil of width `w` around a node.

```julia
julia> gt = GridTensor{Float64, 3}((I, J, K) -> 1.0, (2, 3), 1);

julia> size(gt)
(6, 6, 6)

julia> gt[1, 2, 3]
1.0
```
"""
struct GridTensor{DT, N, F, D} <: AbstractArray{DT, N}
    f::F
    grid::CartesianIndices{D, NTuple{D, Base.OneTo{Int}}}
    width::Int

    function GridTensor{DT, N}(f, sizes::NTuple{D, Int}, w::Integer) where {DT, N, D}
        w ≥ 0 || throw(ArgumentError("the stencil width must be non-negative, got $w"))
        return new{DT, N, typeof(f), D}(f, CartesianIndices(sizes), Int(w))
    end
end

Base.size(gt::GridTensor{DT, N}) where {DT, N} = ntuple(_ -> length(gt.grid), Val(N))

# The node of an index, in each of its three forms; a node off the grid raises a `BoundsError`.
_node(grid::CartesianIndices, i::Integer) = grid[i]
_node(grid::CartesianIndices, I::CartesianIndex) = (checkbounds(grid, I); I)
_node(grid::CartesianIndices, I::Tuple) = _node(grid, CartesianIndex(I))

# One method takes the three index forms, so that no two methods tie at `N = 0`. `AbstractArray`
# answers a single linear index itself.
function Base.getindex(gt::GridTensor{DT, N},
        inds::Vararg{Union{CartesianIndex, Tuple, Integer}, N}) where {DT, N}
    return convert(DT, gt.f(map(i -> _node(gt.grid, i), inds)...))
end

stencil_indices(gt::GridTensor, i::Integer) = stencil_indices(i, gt.width, size(gt.grid))

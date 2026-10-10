### Indices

"""
    multiindex(i::Integer, sizes::Tuple)
    multiindex(i::Integer, ax::MultiIndexAxis)
    multiindex(i, nx, nv)

Convert the linear index `i` to the `CartesianIndex` it denotes on a grid of extents `sizes`,
on the axis `ax`, or on the `nx × nv` grid. The first dimension runs fastest. Inverse of
[`linearindex`](@ref). An index outside the grid raises a `BoundsError`.
"""
multiindex(i::Integer, sizes::Tuple) = CartesianIndices(sizes)[i]
multiindex(i::Integer, ax::MultiIndexAxis) = ax.cartes_indices[i]
multiindex(i, nx, nv) = multiindex(i, (nx, nv))

"""
    linearindex(I::CartesianIndex, sizes::Tuple)
    linearindex(I::CartesianIndex, ax::MultiIndexAxis)
    linearindex(I, nx, nv)

Convert the `CartesianIndex` `I` to its linear index on a grid of extents `sizes`, on the
axis `ax`, or on the `nx × nv` grid. Inverse of [`multiindex`](@ref). An index outside the
grid raises a `BoundsError`.
"""
linearindex(I::CartesianIndex, sizes::Tuple) = LinearIndices(sizes)[I]
linearindex(I::CartesianIndex, ax::MultiIndexAxis) = ax.linear_indices[I]
linearindex(I, nx, nv) = linearindex(I, (nx, nv))

# Given a linear index i, convert it to a CartesianIndex (i₁, i₂) on the nx × nv grid
# Find the indices in the stencil (width w) around i: (i₁ ± w, i₂ ± w)
# Convert these back to linear indices and return them in a Vector of (2w+1)^2 entries
# Boundaries are periodic
function _stencil_indices(i::Int, w::Int, nx, nv)
    indices = zeros(Int, (2*w+1)^2)
    ij = Tuple(multiindex(i, nx, nv))
    k = 1
    for d1 in (-w):w, d2 in (-w):w

        indices[k] = linearindex(CartesianIndex(mod1.(ij .+ (d1, d2), (nx, nv))), nx, nv)
        k += 1
    end
    return indices
end

# The stencil is a lazy iterator: it holds the Cartesian index of the centre, the width and the
# extents of the grid, and it computes one neighbour per `iterate`, so a call allocates nothing.
struct StencilIndices{D}
    centre::CartesianIndex{D}
    width::Int
    sizes::NTuple{D, Int}
end

Base.length(s::StencilIndices{D}) where {D} = (2 * s.width + 1)^D
Base.eltype(::Type{<:StencilIndices}) = Int
Base.IteratorSize(::Type{<:StencilIndices}) = Base.HasLength()

# The linear index of the neighbour at the offset `offs`, whose every component the periodic grid
# wraps back into it. The first dimension runs fastest, as `LinearIndices` has it.
@inline function _stencil_index(s::StencilIndices{D}, offs::NTuple{D, Int}) where {D}
    index, stride = 1, 1
    @inbounds for d in 1:D
        index += (mod1(s.centre[d] + offs[d], s.sizes[d]) - 1) * stride
        stride *= s.sizes[d]
    end
    return index
end

# The next offset in the order of `(-w):w` per direction, the first direction outermost: step the
# last direction that has not reached `w`, and start the directions after it again at `-w`. The
# offset after the last one is `nothing`.
@inline function _next_offset(offs::NTuple{D, Int}, w::Int) where {D}
    for d in D:-1:1
        offs[d] < w || continue
        return ntuple(i -> i < d ? offs[i] : (i == d ? offs[d] + 1 : -w), Val(D))
    end
    return nothing
end

function Base.iterate(s::StencilIndices{D}) where {D}
    offs = ntuple(_ -> -s.width, Val(D))
    return _stencil_index(s, offs), offs
end

function Base.iterate(s::StencilIndices{D}, offs::NTuple{D, Int}) where {D}
    next = _next_offset(offs, s.width)
    next === nothing && return nothing
    return _stencil_index(s, next), next
end

"""
    stencil_indices(i::Integer, w::Integer, sizes::NTuple{D, Int})
    stencil_indices(gt::GridTensor, i::Integer)

The linear indices of the periodic stencil of width `w` around the linear index `i`, as a lazy
iterator of `(2w+1)^D` entries on the grid of extents `sizes`. The offsets run over `(-w):w` in
each direction, the first direction outermost and the last innermost, and each one wraps around
the grid, so a neighbour of a node on an edge is a node on the opposite edge. The first dimension
of the grid runs fastest, as it does for [`multiindex`](@ref). An `i` outside the grid raises a
`BoundsError`, and a negative `w` an `ArgumentError`.

`stencil_indices(gt, i)` is the stencil of the width and on the grid of the
[`GridTensor`](@ref) `gt`.

```julia
julia> collect(stencil_indices(1, 1, (2, 3))) == [6, 2, 4, 5, 1, 3, 6, 2, 4]
true
```
"""
function stencil_indices(i::Integer, w::Integer, sizes::NTuple{D, Int}) where {D}
    w ≥ 0 || throw(ArgumentError("the stencil width must be non-negative, got $w"))
    return StencilIndices(multiindex(i, sizes), Int(w), sizes)
end

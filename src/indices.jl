### Indices

"""
    isvalid(I::CartesianIndex, sizes::Tuple)
    isvalid(I::CartesianIndex, nx, nv)

Return `true` if every component `I[d]` lies in `1:sizes[d]`.

This is `MultiIndexArrays.isvalid`, a function of its own, and not a method of `Base.isvalid`.
It is not exported, as the name clashes with `Base.isvalid`; call it qualified or import it
with `using MultiIndexArrays: isvalid`.
"""
function isvalid(I::CartesianIndex{N}, sizes::NTuple{N, Integer}) where {N}
    all(map((i, n) -> 1 ≤ i ≤ n, Tuple(I), sizes))
end

isvalid(I::CartesianIndex, nx, nv) = isvalid(I, (nx, nv))

function multiindex(i, nx, nv)
    @assert i ≥ 1 && i ≤ nx*nv
    CartesianIndex(mod1(i, nx), div(i-1, nx) + 1)
end

function linearindex(I, nx, nv)
    i, j = Tuple(I)
    @assert i ≥ 1 && i ≤ nx
    @assert j ≥ 1 && j ≤ nv
    (j-1) * nx + i
end

"""
    multiindex(i::Integer, sizes::Tuple)
    multiindex(i::Integer, ax::MultiIndexAxis)

Convert the linear index `i` to the `CartesianIndex` it denotes on a grid of extents `sizes`,
or on the axis `ax`. The first dimension runs fastest. Inverse of [`linearindex`](@ref).
"""
multiindex(i::Integer, sizes::Tuple) = CartesianIndices(sizes)[i]
multiindex(i::Integer, ax::MultiIndexAxis) = ax.cartes_indices[i]

"""
    linearindex(I::CartesianIndex, sizes::Tuple)
    linearindex(I::CartesianIndex, ax::MultiIndexAxis)

Convert the `CartesianIndex` `I` to its linear index on a grid of extents `sizes`, or on the
axis `ax`. Inverse of [`multiindex`](@ref).
"""
linearindex(I::CartesianIndex, sizes::Tuple) = LinearIndices(sizes)[I]
linearindex(I::CartesianIndex, ax::MultiIndexAxis) = ax.linear_indices[I]

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

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

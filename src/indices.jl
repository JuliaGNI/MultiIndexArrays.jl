### Indices

function Base.isvalid(I::CartesianIndex, nx, nv)
    I[1] ≥ 1 && I[1] ≤ nx &&
        I[2] ≥ 1 && I[2] ≤ nv
end

function multiindex(i, nx, nv)
    @assert i ≥ 1 && i ≤ nx*nv
    CartesianIndex(mod1(i, nx), div(i-1, nx) + 1)
end

function linearindex(I, nx, nv)
    i, j = Tuple(I)
    @assert i ≥ 1 && i ≤ nx
    @assert j ≥ 1 && i ≤ nv
    (j-1) * nx + i
end

# Given a linear index i, convert it to a CartesianIndex (i₁, i₂, … )
# Find the indices in the stencil (width w) around i: (i₁ ± w₁, i₂ ± w₂, … )
# Convert these back to linear indices and return them in a Tuple with (2w-1)^d - 1 entries
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

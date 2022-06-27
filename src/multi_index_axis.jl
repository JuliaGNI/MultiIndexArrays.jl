
struct MultiIndexAxis{N, CI <: CartesianIndices{N}, LI <: LinearIndices{N}} <: AbstractArray{CartesianIndices{N},N}
    cartes_indices::CI
    linear_indices::LI

    function MultiIndexAxis(cartes_indices::CartesianIndices{N}) where {N}
        linear_indices = LinearIndices(cartes_indices)
        new{N, typeof(cartes_indices), typeof(linear_indices)}(cartes_indices, linear_indices)
    end
end

MultiIndexAxis(inds::Vararg{AbstractUnitRange}) = MultiIndexAxis(CartesianIndices(inds))
MultiIndexAxis(sizes::Vararg{Integer}) = MultiIndexAxis([UnitRange(1,s) for s in sizes]...)

Base.:(==)(ax1::MultiIndexAxis, ax2::MultiIndexAxis) = ax1.cartes_indices == ax2.cartes_indices

Base.axes(ax::MultiIndexAxis) = ax.cartes_indices.indices
Base.axes(ax::MultiIndexAxis, i) = axes(ax)[i]

Base.length(ax::MultiIndexAxis) = length(ax.cartes_indices)
Base.size(ax::MultiIndexAxis) = size(ax.linear_indices)
Base.size(ax::MultiIndexAxis, i) = size(ax.linear_indices, i)

Base.getindex(ax::MultiIndexAxis, i::Integer) = ax.cartes_indices[i]
Base.getindex(ax::MultiIndexAxis, ind::CartesianIndex) = ax.linear_indices[ind]
Base.getindex(ax::MultiIndexAxis, indices::Vararg{Integer}) = ax[CartesianIndex(indices)]

_to_multi_index_axes(axs::Tuple) = MultiIndexAxis(axs...)

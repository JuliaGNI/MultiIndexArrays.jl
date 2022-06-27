
abstract type AbstractMultiIndexArray{T,N} <: AbstractArray{T,N} end

struct MultiIndexArray{T, N, AT <: AbstractArray{T,N}, AX <: NTuple{N, <: MultiIndexAxis}} <: AbstractMultiIndexArray{T,N}
    parent::AT
    axes::AX

    function MultiIndexArray(parent::AbstractArray{T,N}, axs::NTuple{N,MultiIndexAxis}) where {T,N}
        @assert all(length(axs[i]) == size(parent,i) for i in 1:N)
        new{T, N, typeof(parent), typeof(axs)}(parent, axs)
    end
end

MultiIndexArray(parent::AbstractArray{T,N}, axs::Vararg{MultiIndexAxis,N}) where {T,N} = MultiIndexArray(parent, axs)
MultiIndexArray(parent::AbstractArray{T,N}, axs::Vararg{NTuple{M,Int},N}) where {T,N,M} = MultiIndexArray(parent, _to_multi_index_axes.(axs))
MultiIndexArray(parent::AbstractArray{T,N}, axs::Vararg{NTuple{M,AbstractUnitRange},N}) where {T,N,M} = MultiIndexArray(parent, _to_multi_index_axes.(axs))

Base.:(==)(mia1::MultiIndexArray, mia2::MultiIndexArray) = 
                mia1.parent == mia2.parent &&
                mia1.axes == mia2.axes

Base.parent(mia::MultiIndexArray) = mia.parent

Base.axes(mia::MultiIndexArray) = mia.axes
Base.axes(mia::MultiIndexArray, i) = mia.axes[i]

Base.size(mia::MultiIndexArray, args...) = size(mia.parent, args...)


function Base.getindex(mia::MultiIndexArray{T,N}, inds::Vararg{CartesianIndex,N}) where {T,N}
    mia.parent[(axes(mia, i)[inds[i]] for i in eachindex(inds))...]
end

function Base.getindex(mia::MultiIndexArray{T,N}, inds::Vararg{Tuple,N}) where {T,N}
    mia[(CartesianIndex(i) for i in inds)...]
end

function Base.getindex(mia::MultiIndexArray{T,N}, inds::Vararg{Integer,N}) where {T,N}
    mia.parent[inds...]
end



struct MultiIndexLazyArray{DT, N, FT <: Base.Callable, AX <: NTuple{N, <: MultiIndexAxis}} <: AbstractMultiIndexArray{DT,N}
    f::FT
    axes::AX

    function MultiIndexLazyArray(T, f, axs::NTuple{N,MultiIndexAxis}) where {N}
        new{T, N, typeof(f), typeof(axs)}(f, axs)
    end
end

MultiIndexLazyArray(T, f::Base.Callable, axs::Vararg{MultiIndexAxis,N}) where {N} = MultiIndexLazyArray(T, f, axs)
MultiIndexLazyArray(T, f::Base.Callable, axs::Vararg{NTuple{M,Int},N}) where {N,M} = MultiIndexLazyArray(T, f, _to_multi_index_axes.(axs))
MultiIndexLazyArray(T, f::Base.Callable, axs::Vararg{NTuple{M,AbstractUnitRange},N}) where {N,M} = MultiIndexLazyArray(T, f, _to_multi_index_axes.(axs))

Base.:(==)(mila1::MultiIndexLazyArray, mila2::MultiIndexLazyArray) = 
                mila1.f == mila2.f &&
                mila1.axes == mila2.axes

Base.axes(mila::MultiIndexLazyArray) = mila.axes
Base.axes(mila::MultiIndexLazyArray, i) = mila.axes[i]

Base.size(mila::MultiIndexLazyArray) = Tuple(length(ax) for ax in mila.axes)
Base.size(mila::MultiIndexLazyArray, i) = length(mila.axes[i])


function Base.getindex(mila::MultiIndexLazyArray{T,N}, inds::Vararg{CartesianIndex,N}) where {T,N}
    mila.f(inds...)
end

function Base.getindex(mila::MultiIndexLazyArray{T,N}, inds::Vararg{Tuple,N}) where {T,N}
    mila[(CartesianIndex(i) for i in inds)...]
end

function Base.getindex(mila::MultiIndexLazyArray{T,N}, inds::Vararg{Integer,N}) where {T,N}
    mila[(axes(mila, i)[inds[i]] for i in eachindex(inds))...]   
end

function Base.materialize(mila::MultiIndexLazyArray{T,N}) where {T,N}
    mia = zeros(T, size(mila)...)

    for ind in CartesianIndices(mia)
        mia[ind] = mila[Tuple(ind)...]
    end

    MultiIndexArray(mia, axes(mila))
end



# function Base.getindex(mila::MultiIndexLazyArray{DT,N}, indices::Vararg{CartesianIndex,N}) where {DT,N}
#     @boundscheck checkbounds(mila, indices)
#     # for i in eachindex(indices)
#     #     @assert isvalid(indices[i], mila.multisizes[i])
#     # end

#     mila.f(indices...)
# end

# function getindex(mila::MultiIndexLazyArray{DT,N}, indices::Vararg{Int,N}) where {DT,N}
#     multiindices = (multiindex(indices[i], mila.multisizes[i]) for i in eachindex(indices, mila.multisizes))

#     mila[multiindices...]
# end

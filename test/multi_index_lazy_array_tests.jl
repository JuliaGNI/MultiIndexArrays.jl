
const nx = 10
const nv = 24

const T = Float64

_parent = rand(nx, nv)

f = (i, j) -> _parent[i, j]

MultiIndexLazyArray(T, f, (MultiIndexAxis(1:nx), MultiIndexAxis(1:nv)))
MultiIndexLazyArray(T, f, MultiIndexAxis(1:nx), MultiIndexAxis(1:nv))
MultiIndexLazyArray(T, f, (1:nx,), (1:nv,))
MultiIndexLazyArray(T, f, (nx,), (nv,))

@test MultiIndexLazyArray(T, f, (MultiIndexAxis(1:nx), MultiIndexAxis(1:nv))) ==
      MultiIndexLazyArray(T, f, MultiIndexAxis(1:nx), MultiIndexAxis(1:nv)) ==
      MultiIndexLazyArray(T, f, (1:nx,), (1:nv,)) ==
      MultiIndexLazyArray(T, f, (nx,), (nv,))

mila = MultiIndexLazyArray(T, f, (nx,), (nv,))

@test mila[1, 1] == _parent[1, 1]
@test mila[1, nv] == _parent[1, nv]
@test mila[nx, 1] == _parent[nx, 1]
@test mila[nx, nv] == _parent[nx, nv]

@test length(mila) == nx*nv

@test size(mila) == (nx, nv)
@test size(mila, 1) == nx
@test size(mila, 2) == nv

mia = Base.materialize(mila)

@test mila[1, 1] == mia[1, 1]
@test mila[1, nv] == mia[1, nv]
@test mila[nx, 1] == mia[nx, 1]
@test mila[nx, nv] == mia[nx, nv]

@test parent(mia) == _parent

_f = (ind) -> _parent[Tuple(ind)...]

mila = MultiIndexLazyArray(T, _f, (nx, nv))

@test mila[(1, 1)] == _parent[1, 1]
@test mila[(1, nv)] == _parent[1, nv]
@test mila[(nx, 1)] == _parent[nx, 1]
@test mila[(nx, nv)] == _parent[nx, nv]

@test length(mila) == nx*nv

@test size(mila) == (nx*nv,)
@test size(mila, 1) == nx*nv

# __parent = vec(_parent)

# g = i -> __parent[i]

# MultiIndexLazyArray(T, g, (MultiIndexAxis(1:nx, 1:nv)))
# MultiIndexLazyArray(T, g, MultiIndexAxis(1:nx, 1:nv))
# MultiIndexLazyArray(T, g, (1:nx, 1:nv))
# MultiIndexLazyArray(T, g, (nx, nv))

# @test MultiIndexLazyArray(T, g, (MultiIndexAxis(1:nx, 1:nv))) ==
#       MultiIndexLazyArray(T, g, MultiIndexAxis(1:nx, 1:nv)) ==
#       MultiIndexLazyArray(T, g, (1:nx, 1:nv)) ==
#       MultiIndexLazyArray(T, g, (nx, nv))

# mila = MultiIndexLazyArray(T, g, MultiIndexAxis(1:nx, 1:nv))

# @test mila[(1,1)] == _parent[1,1]
# @test mila[(1,nv)] == _parent[1,nv]
# @test mila[(nx,1)] == _parent[nx,1]
# @test mila[(nx,nv)] == _parent[nx,nv]

@testset "Bounds checking" begin
    local g = (I, J) -> _parent[I] + _parent[J]
    local m = MultiIndexLazyArray(T, g, MultiIndexAxis(nx, nv), MultiIndexAxis(nx, nv))

    @test checkbounds(Bool, m, CartesianIndex(nx, nv), CartesianIndex(1, 1))
    @test !checkbounds(Bool, m, CartesianIndex(nx + 1, 1), CartesianIndex(1, 1))
    @test checkbounds(Bool, m, nx * nv, 1)
    @test !checkbounds(Bool, m, nx * nv + 1, 1)

    @test m[CartesianIndex(nx, nv), CartesianIndex(1, 1)] == _parent[nx, nv] + _parent[1, 1]
    @test_throws BoundsError m[CartesianIndex(nx + 1, 1), CartesianIndex(1, 1)]
    @test_throws BoundsError m[CartesianIndex(1, 1), CartesianIndex(1, nv + 1)]
    @test_throws BoundsError m[CartesianIndex(0, 1), CartesianIndex(1, 1)]

    @test m[(nx, nv), (1, 1)] == _parent[nx, nv] + _parent[1, 1]
    @test_throws BoundsError m[(nx + 1, 1), (1, 1)]
    @test_throws BoundsError m[(1, 1), (1, 0)]

    @test m[nx * nv, 1] == _parent[nx, nv] + _parent[1, 1]
    @test_throws BoundsError m[nx * nv + 1, 1]
    @test_throws BoundsError m[1, 0]

    # the error names the lazy array, not an axis or the parent array behind `g`
    local thrown = f -> try
        f()
    catch e
        e
    end
    @test thrown(() -> m[CartesianIndex(nx + 1, 1), CartesianIndex(1, 1)]).a === m
    @test thrown(() -> m[(nx + 1, 1), (1, 1)]).a === m
    @test thrown(() -> m[nx * nv + 1, 1]).a === m

    # checkbounds accepts the index forms that getindex accepts, and not a mix of them
    local e_mixed = thrown(() -> checkbounds(Bool, m, 1, CartesianIndex(1, 1)))
    @test e_mixed isa Exception
    @test typeof(e_mixed) == typeof(thrown(() -> m[1, CartesianIndex(1, 1)]))
end

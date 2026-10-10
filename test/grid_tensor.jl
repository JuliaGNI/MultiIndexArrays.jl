using MultiIndexArrays
using Test

# On Julia 1.10, a documented binding is one that `Docs.meta` holds; Julia 1.11 and later also
# provide `Docs.hasdoc`.
function hasdoc(mod, sym)
    return isdefined(Docs, :hasdoc) ? Docs.hasdoc(mod, sym) :
           haskey(Docs.meta(mod), Docs.Binding(mod, sym))
end

# the cases of the stored reference data: `test/data/poisson_tensor_<DT>_<nx>x<nv>.txt`, written
# by `test/helpers/generate_poisson_tensor_reference.jl`
const CASES = ((Float32, 3, 4), (Float32, 4, 5), (Float64, 3, 4), (Float64, 4, 5))

# The number of nonzero entries of each case, which is the number of lines of its data file: a
# dropped line changes `ref` and the tensor together, so only a count against this constant sees a
# truncated file.
const ENTRIES = Dict((Float32, 3, 4) => 288, (Float32, 4, 5) => 480,
    (Float64, 3, 4) => 288, (Float64, 4, 5) => 480)

# Read a case into a dense `nx·nv × nx·nv × nx·nv` array, with the number of entries read. The
# file holds the nonzero entries of
# `Array(PoissonTensor(DT, nx, nv, Arakawa(nx, nv, DT(0.5), DT(0.25))))` as `<i> <j> <k> <value>`,
# one per line, with the three indices linear on the `nx × nv` grid.
function reference(DT, nx, nv)
    local N = nx * nv
    local ref = zeros(DT, N, N, N)
    local entries = 0
    for line in eachline(joinpath(@__DIR__, "data", "poisson_tensor_$(DT)_$(nx)x$(nv).txt"))
        local i, j, k, value = split(line)
        ref[parse(Int, i), parse(Int, j), parse(Int, k)] = parse(DT, value)
        entries += 1
    end
    return ref, entries
end

# The tensor and the pieces its checks use. `f` closes over the local `ref` and `L`, so that
# `@inferred` sees through it.
function grid_tensor_case(DT, nx, nv, w)
    local (ref, entries) = reference(DT, nx, nv)
    local L = LinearIndices((nx, nv))
    local f = (I, J, K) -> ref[L[I], L[J], L[K]]
    local lazy = MultiIndexLazyArray(DT, f, (nx, nv), (nx, nv), (nx, nv))
    return (; ref, entries, lazy, gt = GridTensor(lazy, w), nx, nv, N = nx * nv)
end

function check_grid_tensor(DT, nx, nv)
    local c = grid_tensor_case(DT, nx, nv, 1)
    local gt, ref, N = c.gt, c.ref, c.N
    local grid = CartesianIndices((nx, nv))

    @testset "$DT on $nx × $nv" begin
        @test eltype(gt) == DT
        @test size(gt) == (N, N, N)
        @test count(!iszero, ref) > 0
        @test c.entries == ENTRIES[(DT, nx, nv)]

        # the entries of the reference `PoissonTensor`, exactly
        @test Array(gt) isa Array{DT, 3}
        @test Array(gt) == ref
        @test Base.materialize(gt) isa MultiIndexArray
        @test parent(Base.materialize(gt)) == ref

        # the three index forms agree, and each one throws off the grid
        for (i, j, k) in ((1, 1, 1), (N, N, N), (N, 1, N), (2, nx + 1, nv))
            local I, J, K = grid[i], grid[j], grid[k]
            @test gt[I, J, K] == gt[i, j, k] == ref[i, j, k]
            @test gt[(I[1], I[2]), (J[1], J[2]), (K[1], K[2])] == gt[i, j, k]
        end
        @test_throws BoundsError gt[CartesianIndex(nx + 1, 1), CartesianIndex(1, 1),
            CartesianIndex(1, 1)]
        @test_throws BoundsError gt[(1, nv + 1), (1, 1), (1, 1)]
        @test_throws BoundsError gt[N + 1, 1, 1]
        @test_throws BoundsError gt[1, 0, 1]

        # and each error names the lazy array the tensor holds, not the reference array behind
        # `f`, which is the error a `getindex` that forwards under `@inbounds` would raise
        local thrown(e) =
            try
                e()
            catch err
                err
            end
        for e in (() -> gt[CartesianIndex(nx + 1, 1), CartesianIndex(1, 1),
            CartesianIndex(1, 1)],
            () -> gt[(1, nv + 1), (1, 1), (1, 1)],
            () -> gt[N + 1, 1, 1],
            () -> gt[1, 0, 1])
            local err = thrown(e)
            @test err isa BoundsError && err.a === parent(gt)
        end

        # the locality interface: the tensor's own width and grid
        @test size(axes(parent(gt), 1)) == (nx, nv)
        for w in (1, 2)
            local t = GridTensor(c.lazy, w)
            for i in 1:N
                @test collect(stencil_indices(t, i)) ==
                      collect(stencil_indices(i, w, (nx, nv)))
            end
        end
        @test collect(stencil_indices(GridTensor(c.lazy, 0), 7)) == [7]

        # the type is stable
        @test @inferred(size(gt)) == (N, N, N)
        @test @inferred(gt[2, 3, 5]) == ref[2, 3, 5]
        local stencil = @inferred stencil_indices(gt, 7)
        @test collect(stencil) == collect(stencil_indices(7, 1, (nx, nv)))

        # `Base`'s two fallbacks: the linear index of `Array(gt)`, and the `OneTo` axes
        @test axes(gt) == (Base.OneTo(N), Base.OneTo(N), Base.OneTo(N))
        @test gt[1] == Array(gt)[1]
        @test gt[N ^ 3] == Array(gt)[N ^ 3]

        # an `Int32` index and an `Int32` width, and a width that is not part of equality
        @test gt[Int32(2), Int32(3), Int32(5)] == gt[2, 3, 5]
        @test typeof(GridTensor(c.lazy, Int32(1))) == typeof(gt)
        @test gt == GridTensor(c.lazy, 2)
    end
    return nothing
end

@testset "Grid tensor" begin
    for (DT, nx, nv) in CASES
        check_grid_tensor(DT, nx, nv)
    end

    # Every entry is distinct and exact in `Float32`, so a permuted, shifted or reflected index map
    # changes the result; the reference data above is invariant under each of these.
    @testset "the index map, on distinct entries: $DT on $sizes" for DT in (Float32, Float64),
        sizes in ((3, 4), (4, 5))

        local L = LinearIndices(sizes)
        local N = prod(sizes)
        local grid = CartesianIndices(sizes)
        local f = (I, J, K) -> DT(L[I] + 100 * L[J] + 10_000 * L[K])
        local gt = GridTensor(MultiIndexLazyArray(DT, f, sizes, sizes, sizes), 1)
        local expected = [DT(i + 100j + 10_000k) for i in 1:N, j in 1:N, k in 1:N]
        @test Array(gt) == expected
        for (i, j, k) in ((1, 2, 3), (N, 1, 2), (2, N, sizes[1] + 1))
            @test gt[grid[i], grid[j], grid[k]] == expected[i, j, k]
            @test gt[Tuple(grid[i]), Tuple(grid[j]), Tuple(grid[k])] == expected[i, j, k]
        end
    end

    @testset "an entry has the element type, whatever the coefficient function returns" begin
        local gt = GridTensor(
            MultiIndexLazyArray(Float32, (I, J, K) -> 0.1, (2, 3), (2, 3), (2, 3)), 1)
        local I = CartesianIndex(1, 2)
        @test gt[1, 2, 3] isa Float32
        @test gt[I, I, I] isa Float32
        @test gt[(1, 2), (1, 2), (1, 2)] isa Float32
        @test gt[1] isa Float32
        @test gt[1, 2, 3] == Array(gt)[1, 2, 3] == 0.1f0
    end

    @testset "the constructor checks its arguments" begin
        local lazy = MultiIndexLazyArray(Float64, (I, J, K) -> 1.0, (3, 4), (3, 4), (3, 4))
        @test GridTensor(lazy, 0) isa GridTensor
        @test_throws ArgumentError GridTensor(lazy, -1)

        # three unequal axes, and two equal axes followed by a third that differs: the first two
        # agree in the second shape, so a check that compares only them accepts it
        for sizes in (((3, 4), (4, 3), (3, 4)), ((3, 4), (3, 4), (4, 3)))
            @test_throws ArgumentError GridTensor(
                MultiIndexLazyArray(Float64, (I, J, K) -> 1.0, sizes...), 1)
        end

        # the parameterized constructor takes the same two checks
        local unequal = MultiIndexLazyArray(
            Float64, (I, J, K) -> 1.0, (3, 4), (4, 3), (3, 4))
        @test_throws ArgumentError GridTensor{Float64, 3, typeof(lazy)}(lazy, -1)
        @test_throws ArgumentError GridTensor{Float64, 3, typeof(unequal)}(unequal, 1)

        # the parent is a lazy array: nothing else is a grid tensor
        @test_throws MethodError GridTensor(MultiIndexArray(zeros(2, 2), (2, 2)), 1)
        @test_throws MethodError GridTensor(zeros(2, 2, 2), 1)
    end

    @testset "the interface is public" begin
        @test :GridTensor in names(MultiIndexArrays)
        @test :stencil_indices in names(MultiIndexArrays)
        @test hasdoc(MultiIndexArrays, :GridTensor)
        @test hasdoc(MultiIndexArrays, :stencil_indices)
    end

    @testset "no GridTensor method is ambiguous" begin
        @test isempty(filter(p -> occursin("GridTensor", string(p[1].sig, p[2].sig)),
            Test.detect_ambiguities(MultiIndexArrays)))
    end

    @testset "the stencil iteration allocates nothing" begin
        # a fresh process with `--check-bounds=auto`, because `julia_cmd()` carries the
        # parent process's bounds setting, which the later flag overrides
        local prog = """
            # A test runner can pass on a `JULIA_LOAD_PATH` without the active project, and
            # `--project` alone then does not make this package loadable.
            pushfirst!(LOAD_PATH, "@")
            using MultiIndexArrays

            allocations(f::F, a::A) where {F, A} = (f(a); minimum((@allocated f(a)) for _ in 1:5))

            Base.JLOptions().check_bounds == 0 || error("this program measures allocations")

            const LAZY = MultiIndexLazyArray(Float64, (I, J, K) -> 1.0, (4, 5), (4, 5), (4, 5))
            const GT1 = GridTensor(LAZY, 1)
            const GT2 = GridTensor(LAZY, 2)
            const GRID = CartesianIndices((4, 5))

            for (label, f, a) in (
                    ("stencil_indices(i, 1, sizes)", i -> stencil_indices(i, 1, (4, 5)), 7),
                    ("stencil_indices(i, 2, sizes)", i -> stencil_indices(i, 2, (4, 5)), 7),
                    ("sum(stencil_indices(i, 1, sizes))", i -> sum(stencil_indices(i, 1, (4, 5))), 7),
                    ("sum(stencil_indices(i, 2, sizes))", i -> sum(stencil_indices(i, 2, (4, 5))), 7),
                    ("stencil_indices(gt, i), w = 1", i -> stencil_indices(GT1, i), 7),
                    ("stencil_indices(gt, i), w = 2", i -> stencil_indices(GT2, i), 7),
                    ("sum(stencil_indices(gt, i)), w = 1", i -> sum(stencil_indices(GT1, i)), 7),
                    ("sum(stencil_indices(gt, i)), w = 2", i -> sum(stencil_indices(GT2, i)), 7),
                    ("gt[i, j, k]", i -> GT1[i, 3, 5], 2),
                    ("gt[I, J, K]", i -> GT1[GRID[i], GRID[3], GRID[5]], 2),
                    ("gt[(i, j), (j, k), (k, i)]", i -> GT1[(i, 1), (3, 1), (1, 2)], 2),
                    ("gt[n]", i -> GT1[i], 2))
                @assert allocations(f, a) <= 0 "\$label allocated"
            end
            @assert collect(stencil_indices(7, 1, (4, 5))) isa Vector{Int}
            @assert collect(stencil_indices(7, 2, (4, 5))) isa Vector{Int}
            # the barrier above stays silent, or it is not a barrier; this control shows it sees
            # an allocation when there is one
            @assert allocations(collect, stencil_indices(7, 1, (4, 5))) > 0 "the barrier sees no allocation"
            """
        local cmd = `$(Base.julia_cmd()) --startup-file=no --check-bounds=auto --project=$(Base.active_project()) -e $prog`
        @test success(cmd)
    end
end

using MultiIndexArrays
using MultiIndexArrays: multiindex, linearindex, _stencil_indices
using Test

@testset "Indices" begin
    # a non-square grid, with the first extent the larger, so that swapping i and j shows
    local n₁, n₂ = 5, 3
    local ax = MultiIndexAxis(n₁, n₂)

    # the Cartesian index of each linear index on the 5 × 3 grid, first component fastest
    local table = [(1, 1), (2, 1), (3, 1), (4, 1), (5, 1),
        (1, 2), (2, 2), (3, 2), (4, 2), (5, 2),
        (1, 3), (2, 3), (3, 3), (4, 3), (5, 3)]

    @testset "the package defines no isvalid, and Base.isvalid is not extended" begin
        @test MultiIndexArrays.isvalid === Base.isvalid
        @test !hasmethod(Base.isvalid, Tuple{CartesianIndex{2}, Int, Int})
        @test !hasmethod(Base.isvalid, Tuple{CartesianIndex{2}, Tuple{Int, Int}})
    end

    @testset "multiindex and linearindex against a table of the 5 × 3 grid" begin
        for (i, t) in enumerate(table)
            I = CartesianIndex(t)
            @test multiindex(i, ax) == I
            @test multiindex(i, (n₁, n₂)) == I
            @test multiindex(i, n₁, n₂) == I
            @test linearindex(I, ax) == i
            @test linearindex(I, (n₁, n₂)) == i
            @test linearindex(I, n₁, n₂) == i
        end
    end

    @testset "out-of-range conversions throw" begin
        @test_throws BoundsError multiindex(0, ax)
        @test_throws BoundsError multiindex(n₁ * n₂ + 1, ax)
        @test_throws BoundsError multiindex(n₁ * n₂ + 1, (n₁, n₂))
        @test_throws BoundsError multiindex(0, n₁, n₂)
        @test_throws BoundsError multiindex(n₁ * n₂ + 1, n₁, n₂)
        @test_throws BoundsError linearindex(CartesianIndex(n₁ + 1, 1), ax)
        @test_throws BoundsError linearindex(CartesianIndex(1, n₂ + 1), (n₁, n₂))
        @test_throws BoundsError linearindex(CartesianIndex(n₁ + 1, 1), n₁, n₂)
        @test_throws BoundsError linearindex(CartesianIndex(1, n₂ + 1), n₁, n₂)
    end

    @testset "_stencil_indices on the periodic 5 × 3 grid" begin
        # the 3 × 3 stencil around the corner (1, 1), worked out by hand, second offset fastest
        @test _stencil_indices(1, 1, n₁, n₂) == [15, 5, 10, 11, 1, 6, 12, 2, 7]
        @test _stencil_indices(7, 0, n₁, n₂) == [7]

        # every node and width, against the grid of linear indices shifted periodically by
        # each offset; w = 2 wraps the second direction more than once
        local L = LinearIndices((n₁, n₂))
        for w in 0:2, (i, t) in enumerate(table)

            @test _stencil_indices(i, w, n₁, n₂) ==
                  [circshift(L, (-d1, -d2))[t...] for d1 in (-w):w for d2 in (-w):w]
        end
    end

    @testset "stencil_indices wraps around every edge and corner" begin
        # the stencil of the four corners and of one cell on each edge of the 4 × 5 grid, and of
        # the corners and two interior cells of the 3 × 4 grid, where a width of 1 covers the
        # whole first direction. Worked out by hand, first offset outermost and second innermost
        local by_hand = Dict(
            (4, 5) => Dict(
                1 => [20, 4, 8, 17, 1, 5, 18, 2, 6],
                4 => [19, 3, 7, 20, 4, 8, 17, 1, 5],
                17 => [16, 20, 4, 13, 17, 1, 14, 18, 2],
                20 => [15, 19, 3, 16, 20, 4, 13, 17, 1],
                2 => [17, 1, 5, 18, 2, 6, 19, 3, 7],
                9 => [8, 12, 16, 5, 9, 13, 6, 10, 14],
                12 => [7, 11, 15, 8, 12, 16, 5, 9, 13],
                18 => [13, 17, 1, 14, 18, 2, 15, 19, 3]),
            (3, 4) => Dict(
                1 => [12, 3, 6, 10, 1, 4, 11, 2, 5],
                3 => [11, 2, 5, 12, 3, 6, 10, 1, 4],
                10 => [9, 12, 3, 7, 10, 1, 8, 11, 2],
                12 => [8, 11, 2, 9, 12, 3, 7, 10, 1],
                4 => [3, 6, 9, 1, 4, 7, 2, 5, 8],
                9 => [5, 8, 11, 6, 9, 12, 4, 7, 10]))

        for ((nx, nv), stencils) in by_hand, (i, expected) in stencils

            @test collect(stencil_indices(i, 1, (nx, nv))) == expected
        end
    end

    @testset "stencil_indices agrees with _stencil_indices entry by entry" begin
        # every node and width on two non-square grids, in the old function's order: the first
        # offset outermost and the second innermost, so a swapped loop order fails here
        for (nx, nv) in ((4, 5), (5, 3)), w in 0:2, i in 1:(nx * nv)
            @test collect(stencil_indices(i, w, (nx, nv))) == _stencil_indices(i, w, nx, nv)
        end
    end

    @testset "stencil_indices, its length and its edges" begin
        @test length(stencil_indices(1, 0, (4, 5))) == 1
        @test length(stencil_indices(1, 2, (4, 5))) == 25
        @test eltype(stencil_indices(7, 1, (4, 5))) == Int
        @test collect(stencil_indices(1, 1, (4, 5))) isa Vector{Int}

        # the centre is computed eagerly, so an index off the grid throws without iterating
        @test_throws BoundsError stencil_indices(0, 1, (4, 5))
        @test_throws BoundsError stencil_indices(21, 1, (4, 5))
        @test_throws ArgumentError stencil_indices(1, -1, (4, 5))

        # the length is an `Int`, so the widest stencil that fits in one is accepted and a wider
        # one is refused rather than wrapped around by the arithmetic of `length`
        @test length(stencil_indices(1, (typemax(Int) - 1) ÷ 2, (4,))) == typemax(Int)
        @test_throws OverflowError stencil_indices(1, (typemax(Int) - 1) ÷ 2 + 1, (4,))
        @test_throws OverflowError stencil_indices(1, typemax(Int), (1, 1))

        # any integer index and width; the extents stay `Int`
        @test collect(stencil_indices(Int32(7), Int32(1), (4, 5))) ==
              collect(stencil_indices(7, 1, (4, 5)))
        @test_throws MethodError stencil_indices(7, 1, (Int32(4), Int32(5)))
    end
end

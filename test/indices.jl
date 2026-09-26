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
end

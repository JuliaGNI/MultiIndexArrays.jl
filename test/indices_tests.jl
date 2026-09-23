using MultiIndexArrays: isvalid, multiindex, linearindex

@testset "Indices" begin
    # a non-square grid, with the first extent the larger, so that swapping i and j shows
    local n₁, n₂ = 5, 3
    local ax = MultiIndexAxis(n₁, n₂)

    @testset "isvalid does not extend Base.isvalid" begin
        @test isvalid !== Base.isvalid
        @test !hasmethod(Base.isvalid, Tuple{CartesianIndex{2}, Int, Int})
        @test !hasmethod(Base.isvalid, Tuple{CartesianIndex{2}, Tuple{Int, Int}})
    end

    @testset "isvalid" begin
        @test isvalid(CartesianIndex(1, 1), (n₁, n₂))
        @test isvalid(CartesianIndex(n₁, n₂), (n₁, n₂))
        @test !isvalid(CartesianIndex(0, 1), (n₁, n₂))
        @test !isvalid(CartesianIndex(1, 0), (n₁, n₂))
        @test !isvalid(CartesianIndex(n₁ + 1, 1), (n₁, n₂))
        @test !isvalid(CartesianIndex(1, n₂ + 1), (n₁, n₂))
        @test !isvalid(CartesianIndex(n₂ + 1, n₁), (n₁, n₂))
        @test isvalid(CartesianIndex(n₁, n₂), n₁, n₂)
        @test !isvalid(CartesianIndex(n₂, n₁), n₁, n₂)
        @test isvalid(CartesianIndex(2, 3, 4), (2, 3, 4))
        @test !isvalid(CartesianIndex(2, 3, 5), (2, 3, 4))
    end

    @testset "multiindex and linearindex are inverse over a full sweep" begin
        # the expected values come from Base's column-major CartesianIndices and LinearIndices
        for (i, I) in enumerate(CartesianIndices((n₁, n₂)))
            @test multiindex(i, ax) == I
            @test multiindex(i, (n₁, n₂)) == I
            @test multiindex(i, n₁, n₂) == I
            @test linearindex(I, ax) == i
            @test linearindex(I, (n₁, n₂)) == i
            @test linearindex(I, n₁, n₂) == i
            @test multiindex(linearindex(I, ax), ax) == I
            @test multiindex(linearindex(I, (n₁, n₂)), (n₁, n₂)) == I
        end
    end

    @testset "out-of-range conversions throw" begin
        @test_throws BoundsError multiindex(0, ax)
        @test_throws BoundsError multiindex(n₁ * n₂ + 1, ax)
        @test_throws BoundsError multiindex(n₁ * n₂ + 1, (n₁, n₂))
        @test_throws BoundsError linearindex(CartesianIndex(n₁ + 1, 1), ax)
        @test_throws BoundsError linearindex(CartesianIndex(1, n₂ + 1), (n₁, n₂))
    end
end

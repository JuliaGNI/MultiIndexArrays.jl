# Known issues

## KI-1 · missing test · `==` on `MultiIndexAxis` is not tested for inequality

No test compares two unequal axes. The mutant `ax1.cartes_indices == ax2.cartes_indices` → `true`
in `src/multi_index_axis.jl` survives the test suite.

## KI-2 · missing test · `==` on `MultiIndexLazyArray` is not tested for a different `f`

No test compares two lazy arrays with different `f`. The mutant `mila1.f == mila2.f &&` → `true &&`
in `src/multi_index_lazy_array.jl` survives the test suite.

### K1 · `MultiIndexLazyArray` refuses a callable struct as its coefficient function.

- location: `src/multi_index_lazy_array.jl:2`
- evidence: `MultiIndexLazyArray` declares its coefficient function `f::FT <: Base.Callable`, and
  `Base.Callable` is `Union{Function, Type}`, so a struct with a call method is refused although
  `f(I, J, K)` answers for it. GeometricBrackets' `Arakawa`, which `PoissonTensor` wraps, is such a
  struct, so wrapping GeometricBrackets' `Arakawa` in a closure is required. Present on `main` at
  `9ff99f2`.

  ```
  julia> struct Pairs end; (::Pairs)(I, J, K) = Float64(I + J + K);
  julia> MultiIndexLazyArray(Float64, Pairs(), (3, 4), (3, 4), (3, 4))
  ERROR: MethodError: no method matching MultiIndexLazyArray(::Type{Float64}, ::Pairs, ::Tuple{Int64, Int64}, ::Tuple{Int64, Int64}, ::Tuple{Int64, Int64})
    Closest candidates are:
      MultiIndexLazyArray(::Any, !Matched::Union{Function, Type}, ::NTuple{M, Int64}...) where {N, M}
  julia> MultiIndexLazyArray(Float64, (I, J, K) -> Float64(I + J + K), (3, 4), (3, 4), (3, 4))
  MultiIndexLazyArray{Float64, 3, var"#1#2", NTuple{3, MultiIndexAxis}}
  ```
- kind: defect
- found: 2026-10-10

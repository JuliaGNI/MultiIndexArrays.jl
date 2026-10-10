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
  julia> MultiIndexLazyArray(Float64, (I, J, K) -> Float64(I + J + K), (3, 4), (3, 4), (3, 4)) isa MultiIndexLazyArray
  true
  ```
- kind: defect
- found: 2026-10-10

### K2 · `_stencil_indices` builds a second, allocating copy of the stencil.

- location: `src/indices.jl:33`
- evidence: `_stencil_indices(i, w, nx, nv)` fills a fresh `Vector{Int}` of `(2w+1)^2` entries with
  `zeros` on every call, while `stencil_indices` iterates the same stencil lazily and without
  allocation. ReducedBasisMethods (`src/reduced_tensor.jl:27`) and VlasovMethods
  (`src/gridbased/reduced_tensors.jl:47,103,151,209`) import `_stencil_indices` and call it inside
  their loops, so a fix changes their call sites too.
- kind: defect
- found: #13

### K3 · The Aqua `unbound_args` mark fails the nightly job as an unexpected pass.

- location: `test/quality/aqua.jl:7`
- evidence: `unbound_args = (broken = true,)` records issue #4, and the mark holds on `min`, `1`
  and `pre`. On nightly Aqua finds no unbound type parameters, so the job fails
  (CI run 37980393359 on `9ff99f2`):

  ```
  Unbound type parameters: Error During Test at …/Aqua/yUvBM/src/unbound_args.jl:25
   Unexpected Pass
   Expression: isempty(unbounds)
  Some tests did not pass: 9 passed, 0 failed, 1 errored, 1 broken.
  ```

  Fixing the four methods of issue #4 and dropping the mark closes it; `broken = false` alone
  turns the required jobs red.
- kind: defect
- found: #13

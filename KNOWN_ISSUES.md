# Known issues

## KI-1 · missing test · `==` on `MultiIndexAxis` is not tested for inequality

No test compares two unequal axes. The mutant `ax1.cartes_indices == ax2.cartes_indices` → `true`
in `src/multi_index_axis.jl` survives the test suite.

## KI-2 · missing test · `==` on `MultiIndexLazyArray` is not tested for a different `f`

No test compares two lazy arrays with different `f`. The mutant `mila1.f == mila2.f &&` → `true &&`
in `src/multi_index_lazy_array.jl` survives the test suite.

## Upstream

### KI-3 · upstream · `MultiIndexLazyArray` refuses a callable coefficient function

`MultiIndexLazyArray` declares its coefficient function `f::FT <: Base.Callable`, and
`Base.Callable` is `Union{Function, Type}`, so a struct with a call method is refused although
`f(I, J, K)` answers for it. GeometricBrackets' `Arakawa`, which `PoissonTensor` wraps, is such a
struct, so wrapping it takes a closure. Present on `main` at `9ff99f2`.

- location: `src/multi_index_lazy_array.jl:2`
- problem: `MultiIndexLazyArray` refuses a callable struct, so P8's interchange with
  `PoissonTensor` wraps `Arakawa` in a closure.
- evidence:
  ```
  julia> struct Pairs end; (::Pairs)(I, J, K) = Float64(I + J + K);
  julia> MultiIndexLazyArray(Float64, Pairs(), (3, 4), (3, 4), (3, 4))
  ERROR: MethodError: no method matching MultiIndexLazyArray(::Type{Float64}, ::Pairs, ::Tuple{Int64, Int64}, ::Tuple{Int64, Int64}, ::Tuple{Int64, Int64})
    Closest candidates are:
      MultiIndexLazyArray(::Any, !Matched::Union{Function, Type}, ::NTuple{M, Int64}...) where {N, M}
  julia> MultiIndexLazyArray(Float64, (I, J, K) -> Float64(I + J + K), (3, 4), (3, 4), (3, 4))
  MultiIndexLazyArray{Float64, 3, var"#1#2", NTuple{3, MultiIndexAxis}}
  ```
- kind: upstream
- found: 2026-10-10, the round 1a critic of part P10

### KI-4 · upstream · `mutate.jl --warm` reads UNKNOWN for a list whose mutants add a method

The warm runner restores a worker by including the mutated file again, which cannot remove a
method that a mutant added; every later verdict from that worker then reads UNKNOWN, with
`fails after the mutant <n> was restored`. A list whose mutants add a method therefore reports
UNKNOWN whatever the tests do, and a real survivor is hidden among them.

- location: `Harness/scripts/mutate.jl`
- problem: `mutate.jl --warm` reads UNKNOWN for a list whose mutants add a method.
- evidence:
  ```
  $ julia --startup-file=no Harness/scripts/mutate.jl <worktree> --warm .claude/scratch/warm-list.toml grid_tensor.jl indices.jl multi_index_lazy_array.jl
  4 CAUGHT, 0 SURVIVED, 22 UNKNOWN, 0 INVALID, of 26 mutants
  ...: fail .scratch/mutants/.../test/grid_tensor.jl fails after the mutant 23 was restored
  ```
  `--list`, which runs each mutant cold, gives a verdict for every mutant of the same list.
- kind: upstream
- found: 2026-10-10, the round 1a critic of part P10

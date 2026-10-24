# Release Notes

All notable changes to MultiIndexArrays.jl.

This package is pre-1.0, so *every* minor release is potentially breaking in the sense of
[SemVer](https://semver.org) for `0.x` versions. The sections below name what actually
changed, so that a compat-only bump can be told apart from a rename or a change in results.

The first release, `v0.1.0`, is not written up: its record is `git log` and the tag. It
is named as a gap rather than reconstructed, because a changelog assembled after the fact
loses the reasoning that makes it worth keeping.

## [Unreleased] — targeting 0.1.3

### Changed

- **Julia 1.12 is the floor** (`[compat] julia = "1.12"`, from 1.10). A breaking change under
  this package's pre-1.0 convention: a caller on Julia 1.10 or 1.11 can no longer install this
  version. The package's code does not change. The test suite drops two workarounds that
  existed only for Julia 1.10: a `hasdoc` helper that fell back on `Docs.meta`, now
  `Docs.hasdoc`, and a closure in `test/grid_tensor.jl` that captured `zero(DT)` because a
  closure capturing a type inferred `Any`; it captures `DT` now.

## [0.1.2] — 2026-10-12

### New Features

- **`GridTensor`, a lazy grid tensor with a stencil width.** `GridTensor(tensor, w)` wraps a
  rank-`N` `MultiIndexLazyArray` over one grid, and a stencil width `w`, as an
  `AbstractArray{DT, N}` with `Base`'s `OneTo` axes. `size`, `getindex` (in each of the three index
  forms of the lazy array, and by linear index), `parent` and `Array` work on it. The constructor
  raises `ArgumentError` when the axes of the lazy array are not all the same grid, or when `w` is
  negative.

- **`stencil_indices`, the periodic stencil as a lazy iterator.** `stencil_indices(i, w, sizes)`
  and `stencil_indices(gt, i)` return an iterator over the `(2w+1)^D` linear indices of the
  periodic stencil of width `w` around node `i`, the first direction outermost. It allocates
  nothing. The older `_stencil_indices` stays internal and 2-D only, and the sibling packages keep
  importing it by name.

### Bug Fixes

- **`size` of a `MultiIndexLazyArray` infers.** `size(mila)` now returns `map(length, mila.axes)`
  rather than a generator's tuple, so `@inferred size(mila)` passes where its return type was
  `Tuple{Vararg{Int}}`. The sizes it returns are unchanged.

### Changed

- **CI coverage and cache.** CI uploads coverage from the `Julia 1 - ubuntu-latest` job instead of `Julia min`, and a test job saves the Julia cache only when it succeeds.
- **Test suite restructured with separate dependencies.** Test files renamed to match `src/` layout (removing `_tests` suffix) and organized into individual self-contained modules. Test dependencies (`Aqua`, `Random`, `SafeTestsets`, `Test`) moved to `test/Project.toml`. New code-quality suite `test/quality/aqua.jl` runs Aqua.test_all; 15 ambiguities between vararg methods (issue #3) and 4 unbound-argument methods (issue #4) marked broken. Same 215 tests, plus 9 passing and 2 broken Aqua checks.

## [0.1.1] — 2026-09-23

### New Features

- **Index conversion and stencil helpers.** `multiindex` and `linearindex` convert between
  linear and Cartesian indices on a grid, with the first dimension running fastest.
  `_stencil_indices` collects the periodic `(2w+1)²` stencil around a point on an `nx × nv`
  grid. These come from `ReducedBasisMethods`' grid-based bracket tensors, so that
  `GeometricBrackets`, `VlasovMethods` and `ReducedBasisMethods` can share this one copy.
  The conversion functions are not exported — reach them as `using MultiIndexArrays: multiindex`.
  `_stencil_indices` is internal; the sibling packages import it by name. `ReducedBasisMethods`
  also provided `isvalid` for index validation; callers now use `I in CartesianIndices(sizes)`
  instead.

- **Generic conversions between linear and Cartesian indices.** `multiindex(i, sizes::Tuple)`
  and `multiindex(i, ax::MultiIndexAxis)` convert a linear index to a `CartesianIndex`, with the
  first dimension running fastest. `linearindex(I::CartesianIndex, sizes::Tuple)` and
  `linearindex(I::CartesianIndex, ax::MultiIndexAxis)` convert a `CartesianIndex` to a linear
  index; each pair forms an inverse. All forms raise `BoundsError` for indices outside the grid.
  The `(nx, nv)` variants now raise `BoundsError` instead of the `AssertionError` that
  `ReducedBasisMethods`' copy raised; they also no longer incorrectly reject valid indices when
  nx > nv.

- **`checkbounds` for `MultiIndexLazyArray`, and `@inbounds` in every `getindex` form.**
  `Base.checkbounds(Bool, ...)` now works with both `CartesianIndex` and `Integer` index
  forms, accepting all of one type; mixing types raises the same exception as `getindex`. All
  three `getindex` forms—`CartesianIndex`, `Tuple`, and `Integer`—are marked
  `@propagate_inbounds`, so a caller's `@inbounds` block elides the check in every form. An
  in-bounds `getindex` still allocates nothing.

### Bug Fixes

- **Bounds checking for `MultiIndexLazyArray.getindex`.** `getindex` now bounds-checks the index
  before passing it to the callable. In v0.1.0, an out-of-range `CartesianIndex` reached the
  callable unchecked, and an out-of-range `Integer` index raised `BoundsError` naming the axis's
  `CartesianIndices` instead of the array.

### Breaking Changes

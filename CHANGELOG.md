# Release Notes

All notable changes to MultiIndexArrays.jl.

This package is pre-1.0, so *every* minor release is potentially breaking in the sense of
[SemVer](https://semver.org) for `0.x` versions. The sections below name what actually
changed, so that a compat-only bump can be told apart from a rename or a change in results.

The first release, `v0.1.0`, is not written up: its record is `git log` and the tag. It
is named as a gap rather than reconstructed, because a changelog assembled after the fact
loses the reasoning that makes it worth keeping.

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

# Release Notes

All notable changes to MultiIndexArrays.jl.

This package is pre-1.0, so *every* minor release is potentially breaking in the sense of
[SemVer](https://semver.org) for `0.x` versions. The sections below name what actually
changed, so that a compat-only bump can be told apart from a rename or a change in results.

This file was started on 2026-08-31 and deliberately holds no entries. One version was
released before it, `v0.1.0`, and it is not written up here: the record of that history is
`git log` and the tag. It is named as a gap rather than reconstructed, because a changelog
assembled after the fact loses exactly the reasoning that makes it worth keeping. The
`[Unreleased]` target below is provisional — confirm it when the first entry is written.

## [Unreleased] — targeting 0.2.0

### New Features

- **`multiindex`, `linearindex` and `_stencil_indices` for a periodic two-dimensional grid.**
  They convert between a linear index and a `CartesianIndex` over an `nx × nv` grid, and
  collect the periodic `(2w+1)²` stencil around a linear index. These come from
  `ReducedBasisMethods`' grid-based bracket tensors, so that `GeometricBrackets`, `VlasovMethods`
  and `ReducedBasisMethods` can share this one copy. None of them is exported — reach them as
  `using MultiIndexArrays: multiindex`.

- **Generic conversions between linear and Cartesian indices, and a predicate for validity.**
  `multiindex(i, sizes::Tuple)` and `multiindex(i, ax::MultiIndexAxis)` convert a linear index
  to a `CartesianIndex`, with the first dimension running fastest. `linearindex(I::CartesianIndex,
  sizes::Tuple)` and `linearindex(I::CartesianIndex, ax::MultiIndexAxis)` convert a `CartesianIndex`
  to a linear index; each pair forms an inverse. The `sizes::Tuple` and `MultiIndexAxis` forms
  raise `BoundsError` when indices fall outside the grid; the `(nx, nv)` forms raise `AssertionError`.
  Also new: `MultiIndexArrays.isvalid(I::CartesianIndex, sizes::Tuple)` and
  `isvalid(I::CartesianIndex, nx, nv)`, a non-exported predicate that returns `true` if every
  component of `I` lies in range. This is a function of its own, not a method of `Base.isvalid`;
  callers migrating from `ReducedBasisMethods`' copy (which extended `Base.isvalid`) must import it
  with `using MultiIndexArrays: isvalid`.

- **Bounds checking for `MultiIndexLazyArray`:** `Base.checkbounds` now works with both
  `CartesianIndex` and `Integer` index forms, and `getindex` on a lazy array now bounds-checks
  before passing the index to the callable. Before, a `CartesianIndex` reached the callable
  unchecked, and an `Integer` index raised `BoundsError` naming the axis's `CartesianIndices`
  rather than the array. Now both raise `BoundsError` naming the array. An in-bounds `getindex`
  still allocates nothing.

### Bug Fixes

### Breaking Changes

## Open Issues

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
  collect the periodic `(2w+1)²` stencil around a linear index. They arrive verbatim from
  `ReducedBasisMethods/src/gridbased/bracket_tensors.jl`, which is where the phase-space
  bracket tensors of that package used to keep them; `PoissonBrackets`, `VlasovMethods` and
  `ReducedBasisMethods` now share this one copy. None of them is exported — reach them as
  `using MultiIndexArrays: multiindex`.

### Bug Fixes

### Breaking Changes

## Open Issues

The indexing helpers above arrived unrepaired, so that the move reviews as a pure relocation.
Two defects came with them, and neither is fixed here:

- `Base.isvalid(I::CartesianIndex, nx, nv)` is **type piracy**: it adds a method to a `Base`
  function on `Base` types, so loading this package changes `isvalid` for every caller in the
  session.
- `linearindex` asserts `j ≥ 1 && i ≤ nv`, which tests `i` where it means `j`.

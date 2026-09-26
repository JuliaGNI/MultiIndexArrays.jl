# Known issues

## KI-1 · missing test · `==` on `MultiIndexAxis` is not tested for inequality

No test compares two unequal axes. The mutant `ax1.cartes_indices == ax2.cartes_indices` → `true`
in `src/multi_index_axis.jl` survives `test/multi_index_axis.jl`, on `origin/main` and on the
test-migration branch (`mutate.jl`, SURVIVED).

## KI-2 · missing test · `==` on `MultiIndexLazyArray` is not tested for a different `f`

No test compares two lazy arrays with different `f`. The mutant `mila1.f == mila2.f &&` → `true &&`
in `src/multi_index_lazy_array.jl` survives, on `origin/main` and on the test-migration branch
(critic round 1a, `mutate.jl`).

## KI-3 · docs · wrong line numbers in issue #3

Issue #3 gives the lazy-array constructors as `src/multi_index_lazy_array.jl:8, :13, :16, :20`.
Critic round 1a reads them at lines 12, 15, 18 and 21. The issue text needs a correction.

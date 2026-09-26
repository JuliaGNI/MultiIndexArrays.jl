# Known issues

## KI-1 · missing test · `==` on `MultiIndexAxis` is not tested for inequality

No test compares two unequal axes. The mutant `ax1.cartes_indices == ax2.cartes_indices` → `true`
in `src/multi_index_axis.jl` survives the test suite.

## KI-2 · missing test · `==` on `MultiIndexLazyArray` is not tested for a different `f`

No test compares two lazy arrays with different `f`. The mutant `mila1.f == mila2.f &&` → `true &&`
in `src/multi_index_lazy_array.jl` survives the test suite.

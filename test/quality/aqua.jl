using Aqua
using MultiIndexArrays
using Test

Aqua.test_all(MultiIndexArrays;
    ambiguities = (broken = true,),     # issue #3
    unbound_args = (broken = true,))    # issue #4

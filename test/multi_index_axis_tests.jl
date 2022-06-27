
@test MultiIndexAxis(5, 23, 45, 63) == 
      MultiIndexAxis(1:5, 1:23, 1:45, 1:63) ==
      MultiIndexAxis(CartesianIndices((1:5, 1:23, 1:45, 1:63)))

@test MultiIndexAxis(-5:5, 0:10, 1:100) ==
      MultiIndexAxis(CartesianIndices((-5:5, 0:10, 1:100)))


mi = MultiIndexAxis(1:10, 1:100)

@test length(mi) == 1000
@test size(mi) == (10,100)
@test size(mi,1) == 10
@test size(mi,2) == 100

@test mi[1] == CartesianIndex(1,1)
@test mi[495] == CartesianIndex(5,50)
@test mi[991] == CartesianIndex(1,100)
@test mi[1000] == CartesianIndex(10,100)

@test mi[1,1] == mi[CartesianIndex(1,1)] == 1
@test mi[5,50] == mi[CartesianIndex(5,50)] == 495
@test mi[1,100] == mi[CartesianIndex(1,100)] == 991
@test mi[10,100] == mi[CartesianIndex(10,100)] == 1000

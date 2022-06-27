

const nx = 10
const nv = 24

_parent = rand(nx, nv)

@test MultiIndexArray(_parent, (MultiIndexAxis(1:nx), MultiIndexAxis(1:nv))) ==
      MultiIndexArray(_parent, MultiIndexAxis(1:nx), MultiIndexAxis(1:nv)) ==
      MultiIndexArray(_parent, (1:nx,), (1:nv,)) ==
      MultiIndexArray(_parent, (nx,), (nv,))

mia = MultiIndexArray(_parent, (nx,), (nv,))

@test mia.parent == _parent

@test mia[1,1] == _parent[1,1]
@test mia[1,nv] == _parent[1,nv]
@test mia[nx,1] == _parent[nx,1]
@test mia[nx,nv] == _parent[nx,nv]


__parent = vec(_parent)

@test MultiIndexArray(__parent, (MultiIndexAxis(1:nx, 1:nv))) ==
      MultiIndexArray(__parent, MultiIndexAxis(1:nx, 1:nv)) ==
      MultiIndexArray(__parent, (1:nx, 1:nv)) ==
      MultiIndexArray(__parent, (nx, nv))

mia = MultiIndexArray(__parent, MultiIndexAxis(1:nx, 1:nv))

@test mia.parent == __parent

@test mia[(1,1)] == _parent[1,1]
@test mia[(1,nv)] == _parent[1,nv]
@test mia[(nx,1)] == _parent[nx,1]
@test mia[(nx,nv)] == _parent[nx,nv]

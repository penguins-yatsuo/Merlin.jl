const T = Float64

function aaa()
  CuArray()
end

@testset "functions" for i = 1:5

  x = Var(rand(T,10,5))
  for f in [sigmoid, tanh]
    @test checkgrad(() -> f(x), x)
  end

  #cux = Var(CuArray(x.value))
  #for f in [sigmoid, tanh]
  #  y = f(x)
  #  cuy = f(cux)
  #  @test checkdiff(y, Array(cuy))
  #end

  x1 = Var(rand(T,10,5,2))
  x2 = Var(rand(T,10,5,2))
  x3 = Var(rand(T,10,5,2))
  for dim = 1:3
    @test checkgrad(() -> concat(dim,x1,x2,x3), x1, x2, x3)
  end

  x = Var(rand(T,10,5))
  f = Linear(T, 10, 7)
  #f.b = param(rand(T, size(f.b.value)))
  @test checkgrad(() -> f(x), f.w, x)

  #x = rand(1:10,3,2)
  #f = Lookup(Float32, 10, 5)
  #args = f(x).args
  #@test checkgrad(() -> f(x), args...)

  x1 = Var(rand(T,10,5))
  x2 = Var(rand(T,10,5))
  x3 = Var(rand(T,10,1))
  for op in [+,-,.*]
    @test checkgrad(() -> op(x1,x2), x1, x2)
    @test checkgrad(() -> op(x1,x3), x1, x3)
    @test checkgrad(() -> op(x3,x1), x1, x3)
  end
  x4 = Var(rand(T,5,7))
  @test checkgrad(() -> x1*x4, x1, x4)

  x = Var(rand(T,10,5))
  @test checkgrad(() -> reshape(x,2,5,5), x)

  x = Var(rand(T,10,5))
  @test checkgrad(() -> softmax(x,2), x)
  @test checkgrad(() -> logsoftmax(x,2), x)

  p = Var([1:5;])
  x = Var(rand(Float32,10,5))
  @test checkgrad(() -> softmax_crossentropy(p,x,2), x)

  x = Var(rand(T,10,5))
  for dim = 1:ndims(x.value)
    @test checkgrad(() -> sum(x,dim), x)
  end
end

workspace()
using Merlin
using Merlin.Caffe
using CUDA
using Base.LinAlg.BLAS
using Base.Test
using HDF5

function bench()
  a = rand(Float32,100)
  b = rand(Float32,100)
  for i = 1:100000
    s = Array(Float32,3)
    for k = 1:3
      s[k] = a[k]
    end
  end
end
@time bench()

Data(name=:a)
x = Data(rand(Float32,10,5))
l = Linear(Float32,10,3)
y = l(x)

g = @graph begin
  x = Data(name=:x)
  x = Linear(Float32,10,4)(x)
  x = relu(x)
  x = Linear(Float32,4,3)(x)
end
y = g(:x=>rand(Float32,10,5))
gradient!(y)

x = Data(rand(Float32,10,5))
@checkgrad g(:x=>x) [x]
y = g(:x => rand(Float32,10,5))

Merlin.gradient!(y)

x = Data(rand(Float32,10,5))
l = Linear(Float32,10,4)
y = l(x)
relu(y)

Merlin.gradient!(y)

@checkgrad l(x) [x]

x = rand(Float32,5,4,3,2)
y = Merlin.window2((1,1), w,x)
yy = Merlin.window3((1,1), w,x)

function bench()
  x = rand(Float32,100,100,3,30)
  w = rand(Float32,2,2,3,4)
  for i = 1:100
    #Merlin.softmax_mocha(x,2)
    Merlin.window2((1,1), w,x)
  end
end
@time bench()

y = zeros(x)
Merlin.softmax_mocha(x,1)
y

y2 = similar(x)
softmax(x) - y

data_x = [Var(rand(Float32,10,5)) for i=1:100] # input data
data_y = [Var([1,2,3]) for i=1:100] # correct labels

opt = SGD(0.0001)
for epoch = 1:10
  println("epoch: $(epoch)")
  loss = fit(f, softmax_crossentropy, opt, data_x, data_y)
  println("loss: $(loss)")
end

path = "C:/Users/hshindo/Desktop/aa.h5"
gru = GRU(Float32, 10)
Merlin.save(Dict("1"=>gru), path)

x = Var(rand(Float32,5,4,3,2))
f = Conv(Var(rand(Float32,2,2,3,4)), stride=(1,1), pad=(0,0))
y = f(x)

embeds = param(rand(Float32, 5, 10))
embeds.value
x = Var(rand(1:10,2,1))
x.value
y = lookup(embeds,x)

y.value

gradient!(y)
embeds.grad


embeds.value

v = Vector{Float32}(randn(10))
a = CuArray(v)


CuArray{Float32,1}(randn(10))
super(AbstractFloat)
f = Lookup(CuArray{Float32},10000,100)
# f = Lookup(CuVector{Float32},10000,100)
x = Var(rand(1:1000,5,3))
y = f(x)
y.value

f.w

Array(y.value)

ff = Merlin.@gradcheck f(x) (x,)

a = Merlin.@testest () (x,x)
a[2]

macro aaa(x)
  x
end
function ddd()
  a = 2
  @aaa (a,a)
end
ddd()

nprocs()
path = "C:/Users/hshindo/Desktop/nin_imagenet.caffemodel"
g = Caffe.load(path)
g.nodes

function bench()
  for i = 1:10000
    @simd for j = 1:10000
      a = rand(Float32)
    end
    #rand(Float32,100,100)
    #a * b
  end
end
@time bench()

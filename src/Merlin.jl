module Merlin

using Base.Threads
info("# CPU threads: $(nthreads())")

if haskey(ENV,"Merlin_CUDA") && ENV["Merlin_CUDA"]
    using LibCUDA

    const TEMP_CUDA = LibCUDA.AtomicMalloc()

end

export Functor
abstract type Functor end

const UniArray{T,N} = Union{Array{T,N},CuArray{T,N}}
const UniVector{T} = UniArray{T,1}
const UniMatrix{T} = UniArray{T,2}

include("config.jl")
include("add.jl")
include("var.jl")
include("graph.jl")
include("test.jl")
include("initializer.jl")
include("optimizer.jl")
include("iterators.jl")

for name in [
    "activation/crelu",
    "activation/elu",
    "activation/leaky_relu",
    "activation/relu",
    "activation/selu",
    "activation/sigmoid",
    "activation/swish",
    "activation/tanh",

    "loss/crossentropy",
    "loss/l2",
    "loss/mse",
    "loss/softmax_crossentropy",

    "reduction/max",
    "reduction/mean",
    "reduction/sum",

    "argmax",
    "blas",
    "concat"
    ]
    include("functions/$name.jl")
end

include("datasets/Datasets.jl")
#include("caffe/Caffe.jl")

end

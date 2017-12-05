export Var
export zerograd, batch, batchsize, isvoid, isparam, gradient!, nbatchdims

doc"""
    Var

Variable struct.

`Var` contains the following members:
* data
* batchdims
* f
* args
* grad
"""
mutable struct Var
    data
    batchdims
    f
    args
    grad
end

function Var(data, batchdims=nothing, f=nothing, args=(); grad=nothing)
    if batchdims == nothing && isa(data,Array)
        batchdims = [size(data,ndims(data))]
    end
    Var(data, batchdims, f, args, grad)
end
zerograd(data) = Var(data, grad=zeros(data))

Base.size(x::Var) = size(x.data)
Base.size(x::Var, i::Int) = size(x.data, i)
Base.length(x::Var) = length(x.data)
Base.ndims(x::Var) = ndims(x.data)
Base.eltype(x::Var) = eltype(x.data)
Base.strides(x::Var) = strides(x.data)
Base.stride(x::Var, i::Int) = stride(x.data, i)
nbatchdims(x::Var) = length(x.batchdims)
isvoid(x) = x == nothing

doc"""
    batchsize(x::Var)
    batchsize(x::Var, i::Int)
    batchsize(x::Node)
    batchsize(x::Node, i::Int)
"""
batchsize(x::Var) = x.batchdims
batchsize(x::Var, i::Int) = x.batchdims[i]
batchsize(x::Node; name="") = Node(batchsize, (x,), name)
batchsize(x::Node, i::Int; name="") = Node(batchsize, (x,i), name)

function Base.unsafe_wrap(x::Var, i::Int)
    s = stride(x, ndims(x))
    ind = x.batchinds[i]
    p = pointer(x.data, s*(ind-1)+1)
    unsafe_wrap(Array, p, (front...,d))

    m = prod(front)
    cumdim = 0
    ys = Array{T,N}[]
    for d in splitdims

        y = unsafe_wrap(Array, p, (front...,d))
        push!(ys, y)
        cumdim += d
    end
end

function broadcast_batch(xs::Var...)
    cumdims = zeros(Int, length(xs))
    strides = map(x -> stride(x,ndims(x)), xs)
    ys = Tuple[]
    for i = 1:maximum(nbatchdims,xs)
        a = ntuple(length(xs)) do k
            x = xs[k]
            s = strides[k]
            ind = cumdims[k]
            nbatchdims(x) == 1 && return x.data
            p = pointer(x.data, s*ind+1)
            unsafe_wrap(Array, p, (front...,d))
        end
        f(xs...)
    end
    cat(ys)
end

doc"""
    isparam(x::Var)::Bool

Returns whether `x` is a parameter or not
"""
isparam(x::Var) = !isvoid(x.grad) && isempty(x.args)

doc"""
    topsort

Topological sort.
"""
function topsort{T}(tops::T...)
    sorted = T[]
    dict = ObjectIdDict()
    function visit(v::T)
        haskey(dict,v) && return
        dict[v] = v
        for arg in v.args
            if isa(arg, T)
                visit(arg)
            elseif isa(arg, Vector{T})
                foreach(visit, arg)
            end
        end
        push!(sorted, v)
    end
    foreach(visit, tops)
    sorted
end

doc"""
    gradient!(top::Var)

Compute gradients.
"""
function gradient!(top::Var)
    sorted = topsort(top)
    isvoid(top.grad) && (top.grad = ones(top.data))
    for v in sorted
        if !isempty(v.args) && isvoid(v.grad)
            v.grad = zeros(v.data)
        end
    end
    for i = length(sorted):-1:1
        v = sorted[i]
        isvoid(v.grad) && continue
        isvoid(v.f) || addgrad!(v, v.f, v.args...)
    end
    filter(isparam, sorted)
end

doc"""
    batch(data::Vector{Var}, batchsize::Int)
    batch(data::Vector{NTuple{N,Var}}, batchsize::Int) where N

Create batch from variables.
"""
function batch(data::Vector{Var}, batchsize::Int)
    batches = Var[]
    for i = 1:batchsize:length(data)
        T = eltype(data[i])
        N = ndims(data[i])
        batch = T[]
        batchdims = Int[]
        for k = i:min(i+batchsize-1,length(data))
            append!(batch, data[k].data)
            append!(batchdims, data[k].batchdims)
        end
        batch = reshape(batch, Base.front(size(data[i]))..., sum(batchdims))
        push!(batches, Var(batch,batchdims))
    end
    batches
end

function batch(data::Vector{NTuple{N,Var}}, batchsize::Int) where N
    res = []
    for i = 1:N
        vars = map(x -> x[i], data)
        batches = batch(vars, batchsize)
        push!(res, batches)
    end
    collect(zip(res...))
end

import Base: reshape, merge, repmat

doc"""
    reshape(x, dims::Tuple, batchdims::Vector{Int})

# Example
```julia
T = Float32
x = Var(rand(T,10,5))
y = reshape(x, (2,5), [2,3])
```
"""
function reshape(x::Var, dims::Tuple, batchdims::Vector{Int})
    y = reshape(x.data, dims)
    sum(batchdims) == size(y,ndims(y)) || throw("Invalid batchdims: $(size(y)) and $batchdims")
    Var(y, batchdims, reshape, (x,))
end

reshape(x::Node, dims::Tuple, batchdims::Vector{Int}; name="") = Node(reshape, (x,dims), name)

function addgrad!(y::Var, ::typeof(reshape), x::Var)
    if !isvoid(x.grad)
        T = eltype(x)
        BLAS.axpy!(T(1), y.grad, x.grad)
    end
end

doc"""
    merge(x::Var)
"""
merge(x::Var) = reshape(x, size(x), [sum(x.batchdims)])

merge(x::Node; name="") = Node(merge, (x,), name)

function repmat(x::Var, m::Int, n=1)
    y = repmat(x.data, m, n)
    Var(y, )
end

repmat(x::Node; name="") = Node(repmat, (x,), name)

#=
function promote_size(x::Var)
    dims = x.batchdims
    all(d -> d == dims[1], dims) || return x
    s = Base.front(size(x))..., dims[1], size(x,ndims(x))÷dims[1]
    reshape(x, s, [s[end]])
end

function promote_size(x::Array, batchdims::Vector{Int})
    dims = batchdims
    all(d -> d == dims[1], dims) || return x
    s = Base.front(size(x))..., dims[1], size(x,ndims(x))÷dims[1]
    reshape(x, s)
end
=#

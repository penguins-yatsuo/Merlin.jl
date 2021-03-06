export Linear
export linear

struct Linear
    w::Var
    b::Var
end

"""
    Linear(T::Type, insize::Int, outsize::Int, [init_w=Xavier()], [init_b=Fill(0)])

Linear function (a.k.a. affine transformation).

```math
f(x) = w^{T}x + b
```
where ``w`` is a weight matrix and ``b`` is a bias vector.

```julia
T = Float32
x = Var(rand(T,10,5))
f = Linear(T,10,7)
y = f(x)
```
"""
function Linear(::Type{T}, insize::Int, outsize::Int;
    init_w=Xavier(), init_b=Fill(0)) where T

    w = init_w(T, insize, outsize)
    b = init_b(T, outsize)
    Linear(param(w), param(b))
end
(f::Linear)(x) = linear(x, f.w, f.b)

function linear(x::Var, w::Var, b::Var)
    configure!(x, w, b)
    T = eltype(x)
    if ndims(x) == 1
        y = BLAS.gemv('T', w.data, x.data)
        add!(y, b.data)
    elseif ndims(x) == 2
        y = BLAS.gemm('T', 'N', w.data, x.data)
        y .+= b.data
        ysize = size(y,1), size(x,2)
    else
        throw("Invalid ndims of x: $(ndims(x))")
    end
    Var(y, (linear,x,w,b))
end
function linear(xs::Vector{Var}, w, b)
    y = linear(concat(2,xs), w, b)
    s = map(x -> size(y,1,x,2), xs)
    split(y, 2, s)
end
linear(x::Node, w, b) = Node(linear, x, w, b)

function addgrad!(y::Var, ::typeof(linear), x::Var, w::Var, b::Var)
    T = eltype(x)
    if ndims(x) == 1
        gy = reshape(y.grad, length(y.grad), 1)
        xx = reshape(x.data, length(x.data), 1)
        isvoid(w.grad) || BLAS.gemm!('N', 'T', T(1), xx, gy, T(1), w.grad)
        isvoid(x.grad) || BLAS.gemv!('N', T(1), w.data, y.grad, T(1), x.grad)
        isvoid(b.grad) || BLAS.axpy!(T(1), y.grad, b.grad)
    elseif ndims(x) == 2
        isvoid(x.grad) || BLAS.gemm!('N', 'N', T(1), w.data, y.grad, T(1), x.grad)
        isvoid(w.grad) || BLAS.gemm!('N', 'T', T(1), x.data, y.grad, T(1), w.grad)
        isvoid(b.grad) || BLAS.axpy!(T(1), sum(y.grad,2), b.grad)
    else
        throw("Invalid ndims of x: $(ndims(x))")
    end
end

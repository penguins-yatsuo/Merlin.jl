export Linear, linear

type Linear
    w::Var
    b::Var
end

"""
    Linear(w::Var, b::Var)
    Linear(T::Type, indim::Int, outdim::Int)

Compute linear function (a.k.a. affine transformation).

* indim: inout dimension
* outdim: output dimension

```math
f(x) = W^{T}x + b
```
where ``W`` is a weight matrix and ``b`` is a bias vector.

```julia
T = Float32
x = Var(rand(T,10,5))
f = Linear(T,10,7)
y = f(x)
```
"""
function Linear{T}(::Type{T}, indim::Int, outdim::Int)
    r = T(sqrt(6/(indim+outdim)))
    w = uniform(T, -r, r, outdim, indim)
    b = fill(T(0), outdim)
    Linear(zerograd(w), zerograd(b))
end

function (f::Linear)(x::Var)
    w, b = f.w, f.b
    y = w.data * x.data
    broadcast!(+, y, y, b.data)
    function df(gy)
        T = eltype(gy)
        isvoid(x.grad) || BLAS.gemm!('T', 'N', T(1), w.data, gy, T(1), x.grad)
        isvoid(w.grad) || BLAS.gemm!('N', 'T', T(1), gy, x.data, T(1), w.grad)
        isvoid(b.grad) || BLAS.axpy!(T(1), sum(gy,2), b.grad)
    end
    Var(y, df, (x,w,b))
end
(f::Linear)(x::Var{Void}) = Var(Void(), f, (x,))

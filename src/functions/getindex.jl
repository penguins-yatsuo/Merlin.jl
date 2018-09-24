import Base.getindex

"""
    getindex(x::Var, inds...)

```julia
x = Var(rand(Float32,10,5))
y = x[1:3]
y = x[2:2]
```
Note that `y = x[i]` throws an error since `y` is not a vector but a scholar.
Instead, use `y = x[i:i]`.
"""
function getindex(x::Var, I::Tuple)
    isnothing(x.data) && return Var(nothing,getindex,(x,I))
    configure!(x)
    Var(x.data[I...], ∇getindex!, (x,I))
end
getindex(x::Var, inds...) = getindex(x, inds)

function ∇getindex!(y::Var, x::Var, I::Tuple)
    isnothing(x.grad) && return
    addto!(x.grad, I, y.grad)
end

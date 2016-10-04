import Base.exp

"""
    exp
"""
@graph function exp(x::Var)
    y = exp(x.data)
    df(gy) = isconst(x) || (x.grad = ∇exp!(x.grad, y, gy))
    Var(y, [x], df)
end

function ∇exp!{T}(gx::Array{T}, y::Array{T}, gy::Array{T})
    @inbounds @simd for i = 1:length(gx)
        gx[i] += gy[i] * y[i]
    end
    gx
end

∇exp!{T<:Number}(gx::T, y::T, gy::T) = gx + gy * y

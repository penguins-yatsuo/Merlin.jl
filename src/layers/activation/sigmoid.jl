export sigmoid

Var(:Sigmoid)

"""
    sigmoid(x)
"""
sigmoid(x::Var) = Sigmoid(sigmoid(x.data), nothing, x)
sigmoid(x::ExprNode) = ExprNode(sigmoid, x)

function backward!(v::Sigmoid)
  hasgrad(v.x) || return
  ∇sigmoid!(v[1].data, v[1].grad, v.data, v.grad)
end

function sigmoid{T}(x::Array{T})
  y = similar(x)
  @inbounds @simd for i = 1:length(x)
    y[i] = 1 / (1 + exp(-x[i]))
  end
  y
end

sigmoid(x::CuArray) = activation!(CUDNN_ACTIVATION_SIGMOID, x, similar(x))

function ∇sigmoid!{T}(x::Array{T}, gx::Array{T}, y::Array{T}, gy::Array{T})
  @inbounds @simd for i = 1:length(gx)
    gx[i] += gy[i] * y[i] * (T(1) - y[i])
  end
end

function ∇sigmoid!(x::CuArray, gx::CuArray, y::CuArray, gy::CuArray)
  ∇activation!(CUDNN_ACTIVATION_SIGMOID, y, gy, x, gx, beta=1.0)
end

export softmax, logsoftmax

"""
    softmax(x, dim::Int)

Softmax function over the given dimension.

```math
f(x) = \exp(x) \over \sum \exp(x)
```
"""
function softmax(x::Var)
    y = isvoid(x.data) ? nothing : softmax(x.data)
    Var(y, (softmax,x))
end

function softmax(x::Vector{T}) where T
    y = similar(x)
    maxv = x[1]
    @inbounds for i = 1:length(x)
        maxv = max(maxv, x[i])
    end
    z = T(0)
    @inbounds for i = 1:length(x)
        y[i] = exp(x[i] - maxv)
        z += y[i]
    end
    z == T(0) && throw("z == 0")
    invz = 1 / z
    @inbounds for i = 1:length(x)
        y[i] *= invz
    end
    y
end

function softmax(x::Matrix{T}) where T
    y = similar(x)
    @inbounds for j = 1:size(x,2)
        maxv = x[1,j]
        for i = 1:size(x,1)
            maxv = max(maxv, x[i,j])
        end
        z = T(0)
        for i = 1:size(x,1)
            y[i,j] = exp(x[i,j] - maxv)
            z += y[i,j]
        end
        z == T(0) && throw("z == 0")
        invz = 1 / z
        for i = 1:size(x,1)
            y[i,j] *= invz
        end
    end
    y
end

function addgrad!(y::Var, ::typeof(softmax), x::Var)
    isvoid(x.grad) || ∇softmax!(y.data, y.grad, x.grad)
end

function ∇softmax!(y::Vector{T}, gy::Vector{T}, gx::Vector{T}) where T
    sum = T(0)
    @inbounds for i = 1:length(y)
        sum += gy[i] * y[i]
    end
    @inbounds for i = 1:length(y)
        gx[i] += y[i] * (gy[i]-sum)
    end
end

function ∇softmax!(y::Matrix{T}, gy::Matrix{T}, gx::Matrix{T}) where T
    @inbounds for j = 1:size(y,2)
        sum = T(0)
        for i = 1:size(y,1)
            sum += gy[i,j] * y[i,j]
        end
        for i = 1:size(y,1)
            gx[i,j] += y[i,j] * (gy[i,j]-sum)
        end
    end
end

"""
    logsoftmax(x)

Logarithm of softmax function.
"""
function logsoftmax(x::Var)
    y = isvoid(x.data) ? nothing : logsoftmax(x.data)
    Var(y, (logsoftmax,x))
end

function logsoftmax(x::Matrix{T}) where T
    y = similar(x)
    max = maximum(x, 1)
    @inbounds for j = 1:size(x,2)
        sum = T(1e-10)
        for i = 1:size(x,1)
            sum += exp(x[i,j] - max[j])
        end
        logz = log(sum)
        for i = 1:size(x,1)
            y[i,j] = x[i,j] - max[j] - logz
        end
    end
    y
end

function addgrad!(y::Var, ::typeof(logsoftmax), x::Var)
    isvoid(x.grad) || ∇logsoftmax!(y.data, y.grad, x.grad)
end

function ∇logsoftmax!(y::Matrix{T}, gy::Matrix{T}, gx::Matrix{T}) where T
    @inbounds for j = 1:size(y,2)
        sum = T(0)
        for i = 1:size(y,1)
            sum += gy[i,j]
        end
        for i = 1:size(y,1)
            gx[i,j] += gy[i,j] - exp(y[i,j]) * sum
        end
    end
end

export dot
import Base: exp, log, broadcast, transpose
import Base: +, -, *, /, ^

"""
    exp(x)
"""
function exp(x::Var)
    configure!(x)
    Var(exp(x.data), (exp,x))
end
exp(x::Array) = exp.(x)

function addgrad!(y::Var, ::typeof(exp), x::Var)
    isvoid(x.grad) && return
    ∇exp!(y.data, y.grad, x.grad)
end

function ∇exp!(y::Array{T}, gy::Array{T}, gx::Array{T}) where T
    @inbounds for i = 1:length(gx)
        gx[i] += gy[i] * y[i]
    end
end

"""
    log(x)
"""
function log(x::Var)
    configure!(x)
    Var(log(x.data), (log,x))
end
log(x::Array) = log.(x)

function addgrad!(y::Var, ::typeof(log), x::Var)
    isvoid(x.grad) && return
    ∇log!(y.grad, x.data, x.grad)
end

function ∇log!(gy::Array{T}, x::Array{T}, gx::Array{T}) where T
    @inbounds for i = 1:length(gx)
        gx[i] += gy[i] / x[i]
    end
end

"""
    transpose(x)
"""
function transpose(x::Var)
    y = transpose(x.data)
    Var(y, (transpose,x))
end

function addgrad!(y::Var, ::typeof(transpose), x::Var)
    isvoid(x.grad) && return
    addto!(transpose(y.grad), x.grad)
end

"""
    +(x1::Var, x2::Var)
    +(a::Number, x::Var)
    +(x::Var, a::Number)
"""
function +(x1::Var, x2::Var)
    configure!(x1, x2)
    Var(x1.data + x2.data, (+,x1,x2))
end
+(x1::Union{Number,Array}, x2::Var) = Var(x1) + x2
+(x1::Var, x2::Union{Number,Array}) = x1 + Var(x2)

function addgrad!(y::Var, ::typeof(+), x1::Var, x2::Var)
    T = eltype(y)
    isvoid(x1.grad) || addto!(x1.grad, y.grad)
    isvoid(x2.grad) || addto!(x2.grad, y.grad)
end

"""
    -(x1, x2)
"""
function -(x1::Var, x2::Var)
    configure!(x1, x2)
    Var(x1.data - x2.data, (-,x1,x2))
end
-(a::Number, x::Var) = Var(a) - x
-(x::Var, a::Number) = x - Var(a)

function addgrad!(y::Var, ::typeof(-), x1::Var, x2::Var)
    T = eltype(y)
    isvoid(x1.grad) || addto!(x1.grad, y.grad)
    isvoid(x2.grad) || axpy!(T(-1), y.grad, x2.grad)
end

function -(x::Var)
    configure!(x)
    Var(-x.data, (-,x))
end

function addgrad!(y::Var, ::typeof(-), x::Var)
    T = eltype(y)
    isvoid(x.grad) || axpy!(T(-1), y.grad, x.grad)
end

"""
    .+(x1::Var, x2::Var)
"""
function broadcast(::typeof(+), x1::Var, x2::Var)
    configure!(x1, x2)
    Var(x1.data .+ x2.data, (broadcast,+,x1,x2))
end

function addgrad!(y::Var, ::typeof(broadcast), ::typeof(+), x1::Var, x2::Var)
    isvoid(x1.grad) || ∇broadcast_plus!(y.grad, x1.grad)
    isvoid(x2.grad) || ∇broadcast_plus!(y.grad, x2.grad)
end

function ∇broadcast_plus!(gy::Array{T}, gx::Array{T}) where T
    dims = Int[]
    for i = 1:ndims(gy)
        size(gx,i) == 1 && size(gy,i) > 1 && push!(dims,i)
    end
    axpy!(T(1), sum(gy,dims=dims), gx)
end

"""
    .-(x1::Var, x2::Var)
"""
function broadcast(::typeof(-), x1::Var, x2::Var)
    configure!(x1, x2)
    Var(x1.data .- x2.data, (broadcast,-,x1,x2))
end

function addgrad!(y::Var, ::typeof(broadcast), ::typeof(-), x1::Var, x2::Var)
    isvoid(x1.grad) || ∇broadcast_plus!(y.grad, x1.grad)
    isvoid(x2.grad) || ∇broadcast_minus!(y.grad, x2.grad)
end

function ∇broadcast_minus!(gy::Array{T}, gx::Array{T}) where T
    dims = Int[]
    for i = 1:ndims(gy)
        size(gx,i) == 1 && size(gy,i) > 1 && push!(dims,i)
    end
    axpy!(T(-1), sum(gy,dims=dims), gx)
end

"""
    *(A::Var, B::Var)
"""
function *(A::Var, B::Var)
    configure!(A, B)
    Var(A.data * B.data, (*,A,B))
end

function addgrad!(C::Var, ::typeof(*), A::Var, B::Var)
    T = eltype(C)
    isvoid(A.grad) || gemm!('N', 'T', T(1), C.grad, B.data, T(1), A.grad)
    isvoid(B.grad) || gemm!('T', 'N', T(1), A.data, C.grad, T(1), B.grad)
end

"""
    dot(x1::Var, x2::Var)
"""
function dot(x1::Var, x2::Var)
    configure!(x1, x2)
    Var(x1.data .* x2.data, (dot,x1,x2))
end

function addgrad!(y::Var, ::typeof(dot), x1::Var, x2::Var)
    isvoid(x1.grad) || ∇dot!(y.grad, x2.data, x1.grad)
    isvoid(x2.grad) || ∇dot!(y.grad, x1.data, x2.grad)
end

function ∇dot!(gy::Array{T}, x2::Array{T}, gx1::Array{T}) where T
    g = gy .* x2
    dims = Int[]
    for i = 1:ndims(gy)
        size(gx1,i) == 1 && size(g,i) > 1 && push!(dims,i)
    end
    axpy!(T(1), sum(g,dims=dims), gx1)
end

"""
    /(x1::Var, a)
"""
function /(x::Var, a::Number)
    configure!(x)
    y = Var(x.data/a, (x,))
    y.∇! = () -> begin
        T = eltype(x)
        isvoid(x.grad) || ∇divide!(y.grad, x.grad, T(a))
    end
    y
end

function ∇divide!(gy::Array{T}, gx::Array{T}, a::T) where T
    @inbounds for i = 1:length(gy)
        gx[i] += gy[i] / a
    end
end

"""
    ^(x::Var, a::Number)
"""
function ^(x::Var, a::Number)
    configure!(x)
    Var(x.data^a, (^,x,a))
end

function addgrad!(y::Var, ::typeof(^), x::Var, a::Number)
    T = eltype(x)
    isvoid(x.grad) || ∇elempow!(T(a), x.data, x.grad, y.data, y.grad)
end

function ∇elempow!(a::T, x::Array{T}, gx::Array{T}, y::Array{T}, gy::Array{T}) where T
   @inbounds for i = 1:length(gx)
       gx[i] += gy[i] * a * y[i] / x[i]
   end
end

@generated function ∇elemtimes!(gy::CuArray{T,N}, x2::CuArray{T,N}, gx1::CuArray{T,N}) where {T,N}
    f = CuFunction("""
    __global__ void f(Array<$T,$N> gy, Array<$T,$N> x2, Array<$T,$N> gx1) {
        int idx = blockIdx.x * blockDim.x + threadIdx.x;
        if (idx < gy.length()) {
            gx1[idx] += gy[idx] * x2[idx];
        }
    }""")
    quote
        if size(x2) == size(gx1)
            $f(gy, x2, gx1, dx=length(gy))
        else
            gx = gy .* x2
            for i = 1:N
                size(gx1,i) == 1 && size(gx,i) > 1 && (gx = sum(gx,i))
            end
            axpy!(T(1), gx, gx1)
        end
    end
end

#=
@generated function ∇exp!(y::CuArray{T}, gy::CuArray{T}, gx::CuArray{T}) where T
    f = CuFunction("""
    __global__ void f($T *y, $T *gy, $T *gx, int length) {
        int idx = blockIdx.x * blockDim.x + threadIdx.x;
        if (idx < length) {
            gx[idx] += gy[idx] * y[idx];
        }
    }""")
    quote
        $f(y.ptr, gy.ptr, gx.ptr, length(y), dx=length(y))
    end
end

@generated function ∇log!(gy::CuArray{T}, x::CuArray{T}, gx::CuArray{T}) where T
    f = CuFunction("""
    __global__ void f($T *gy, $T *x, $T *gx, int length) {
        int idx = blockIdx.x * blockDim.x + threadIdx.x;
        if (idx < length) {
            gx[idx] += gy[idx] / x[idx];
        }
    }""")
    quote
        $f(gy.ptr, x.ptr, gx.ptr, length(gy), dx=length(gy))
    end
end

function ∇elemtimes!{T}(gy::Array{T}, x2::Array{T}, gx1::Array{T})
    ind_x2 = CartesianIndex(size(x2))
    ind_gx1 = CartesianIndex(size(gx1))
    @inbounds @simd for I in CartesianRange(size(gy))
        gx1[min(ind_gx1,I)] += gy[I] * x2[min(ind_x2,I)]
    end
end
=#

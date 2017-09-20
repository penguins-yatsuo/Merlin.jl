export Standardize
export standardize

struct Standardize
    scale::Var
    bias::Var
    runmean
    runvar
end

function Standardize{T}(::Type{T}, insize::Tuple)
    dim = 2
    dims = ntuple(i -> i == dim ? 1 : insize[i], length(insize))
    scale = Var(ones(T,dims), hasgrad=true)
    bias = Var(zeros(T,dims), hasgrad=true)
    runmean = zeros(T, dims)
    runvar = ones(T, dims)
    Standardize(scale, bias, runmean, runvar)
end
(f::Standardize)(x) = standardize(x, f.scale, f.bias, f.runmean, f.runvar)

function standardize(x::Var, scale::Var, bias::Var, runmean, runvar; eps=1e-4, decay=0.9)
    T = eltype(x.data)
    if config.train
        xmean = mean(x.data, 2)
        xvar = varm(x.data, xmean, 2, corrected = size(x.data,2) > 1)
        n = length(xmean)
        @. runmean = T(decay) * runmean + T(1-decay) * xmean
        @. runvar = T(decay) * runvar + T(1-decay) * xvar
        invstd = T(1) ./ sqrt.(xvar + T(eps))
        xhat = (x.data .- xmean) .* invstd
        data = xhat .* scale.data .+ bias.data
        Var(data, x.batchdims, standardize, (x,scale,bias,invstd,xhat))
    else
        data = (x.data .- runmean) ./ sqrt.(runvar + T(eps)) .* scale.data .+ bias.data
        Var(data, x.batchdims, standardize, (x,scale,bias))
    end
end

standardize(x::Node, scale, bias, runmean, runvar; name="standardize") = Node(standardize, x, scale, bias, runmean, runvar, name=name)

function standardize{T}(x::Matrix{T}; eps=1e-4)
    xmean = mean(x, 2)
    xvar = varm(x, xmean, 2, corrected = size(x.data,2) > 1)
    (x .- xmean) ./ sqrt.(xvar + T(eps))
end

function addgrad!(y::Var, ::typeof(standardize), x::Var, scale::Var, bias::Var, invstd, xhat)
    T = eltype(y.data)
    gscale = sum(y.grad .* xhat, 2)
    gbias = sum(y.grad, 2)

    if !isvoid(x.grad)
        n = size(x.data, 2)
        g = scale.data .* (y.grad .- (xhat .* gscale .+ gbias) / n) .* invstd
        BLAS.axpy!(T(1), g, x.grad)
    end
    isvoid(scale.grad) || BLAS.axpy!(T(1), gscale, scale.grad)
    isvoid(bias.grad) || BLAS.axpy!(T(1), gbias, bias.grad)
end

export embeddings, lookup

function embeddings(::Type{T}, insize::Int, outsize::Int; init_W=Normal(0,0.01)) where T
    W = init_W(T, outsize, insize)
    [zerograd(W[:,i]) for i=1:size(W,2)]
end

function lookup(embeds::Vector{Var}, x::Var)
    y = lookup(embeds, x.data)
    xs = map(i -> embeds[i], vec(x.data))
    Var(y, (lookup,xs))
end
lookup(embeds::Node, x::Node; name="") = Node(lookup, (embeds,x), name)

function lookup(embeds::Vector{Var}, x::Array{Int})
    e1 = embeds[1].data
    n = length(e1)
    y = similar(e1, n, size(x)...)
    for i = 1:length(x)
        yi = (i-1) * n + 1
        copy!(y, yi, embeds[x[i]].data, 1, n)
    end
    y
end

function lookup(w::Matrix{T}, x::Array{Int}) where T
    n = size(w, 1)
    y = Array{T}(n, size(x)...)
    for i = 1:length(x)
        yi = (i-1) * n + 1
        wi = (x[i]-1) * n + 1
        copy!(y, yi, w, wi, n)
    end
    y
end

function addgrad!(y::Var, ::typeof(lookup), xs::Vector{Var})
    T = eltype(y.data)
    n = length(xs[1].data)
    for i = 1:length(xs)
        isvoid(xs[i].grad) && continue
        py = pointer(y.grad, (i-1)*n+1)
        gx = xs[i].grad
        BLAS.axpy!(n, T(1), py, 1, pointer(gx), 1)
    end
end

export LSTM

doc"""
    LSTM(::Type{T}, insize::Int, outsize::Int, [init_W=Uniform(0.001), init_U=Orthogonal()])

Long Short-Term Memory network.

```math
\begin{align*}
\mathbf{f}_{t} & =\sigma_{g}(W_{f}\mathbf{x}_{t}+U_{f}\mathbf{h}_{t-1}+\mathbf{b}_{f})\\
\mathbf{i}_{t} & =\sigma_{g}(W_{i}\mathbf{x}_{t}+U_{i}\mathbf{h}_{t-1}+\mathbf{b}_{i})\\
\mathbf{o}_{t} & =\sigma_{g}(W_{o}\mathbf{x}_{t}+U_{o}\mathbf{h}_{t-1}+\mathbf{b}_{o})\\
\mathbf{c}_{t} & =\mathbf{f}_{t}\odot\mathbf{c}_{t-1}+\mathbf{i}_{t}\odot\sigma_{c}(W_{c}\mathbf{x}_{t}+U_{c}\mathbf{h}_{t-1}+\mathbf{b}_{c})\\
\mathbf{h}_{t} & =\mathbf{o}_{t}\odot\sigma_{h}(\mathbf{c}_{t})
\end{align*}
```

* ``x_t \in R^{d}``: input vector to the LSTM block
* ``f_t \in R^{h}``: forget gate's activation vector
* ``i_t \in R^{h}``: input gate's activation vector
* ``o_t \in R^{h}``: output gate's activation vector
* ``h_t \in R^{h}``: output vector of the LSTM block
* ``c_t \in R^{h}``: cell state vector
* ``W \in R^{h \times d}``, ``U \in R^{h \times h}`` and ``b \in R^{h}``: weight matrices and bias vectors
* ``\sigma_g``: sigmoid function
* ``\sigma_c``: hyperbolic tangent function
* ``\sigma_h``: hyperbolic tangent function

# 👉 Example
```julia
T = Float32
x = Var(rand(T,100,10))
f = LSTM(T, 100, 100)
h = f(x)
```
"""
struct LSTM
    W::Var
    U::Var
    b::Var
    h0::Var
    c0::Var
end

function LSTM(::Type{T}, insize::Int, outsize::Int; init_W=Uniform(0.001), init_U=Orthogonal()) where T
    W = init_W(T, insize, 4outsize)
    U = init_U(T, insize, 4outsize)
    b = zeros(T, 4outsize)
    b[1:outsize] = ones(T, outsize) # forget gate initializes to 1
    h0 = zeros(T, outsize)
    c0 = zeros(T, outsize)
    LSTM(zerograd(W), zerograd(U), zerograd(b), zerograd(h0), zerograd(c0))
end

function (lstm::LSTM)(x::Var)
    batchdims = x.batchdims
    cumdims = Array{Int}(length(batchdims)+1)
    cumdims[1] = 1
    for i = 1:length(batchdims)
        cumdims[i+1] = cumdims[i] + batchdims[i]
    end
    perm = sortperm(batchdims, rev=true)
    x = resize(x, [sum(batchdims)])
    h, c = lstm.h0, lstm.c0

    for t = 1:batchdims[perm[1]]
        xts = Var[]
        for p in perm
            i = cumdims[p] + t - 1
            i >= cumdims[p+1] && break
            push!(xts, x[:,i])
        end
        xt = concat(2, xts...)
        h, c = lstm(xt, h, c)
    end
    h
end

function (lstm::LSTM)(xt::Var, h::Var, c::Var)
    a = linear(xt, lstm.W, lstm.b)
    a = a .+ BLAS.gemv('T', 1, lstm.U, h)
    n = size(h.data, 1)
    f = sigmoid(a[1:n])
    i = sigmoid(a[n+1:2n])
    o = sigmoid(a[2n+1:3n])
    c = f .* c + i .* tanh(a[3n+1:4n])
    h = o .* tanh(c)
    h, c
end

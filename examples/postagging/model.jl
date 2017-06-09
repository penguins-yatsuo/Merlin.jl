function create_model(numtags::Int)
    T = Float32
    w = Lookup(T,10000,100)(x)

    c = Vector{Vector{Var}}
    x = Var()
    c = Lookup(T,100,10)(x)
    c = Conv1D(T,50,20,10)(h)
    c = max(h, 2)

    h = cat(1, w, c)
    h = Conv1D(T,750,300,150)(h)
    h = relu(h)
    h = Linear(T,300,numtags)(h)
    z = softmax(h)
    crossentropy(y, z)

    nn = For(1:length(data_x)) do i
        x, y = data_x[i], data_y[i]
        wc = For(1:length(x)) do k
            w = Lookup(T,10000,100)(x)
            c = Lookup(T,10000,100)(x)
            h = Conv1D(T,50,20,10))(h)
            c = max(h, 2)
            cat(1, w, c)
        end
        h = cat(1, w, c)
        h = Conv1D(T,750,300,150)(h)
        h = relu(h)
        h = Linear(T,300,numtags)(h)
        z = softmax(h)
        crossentropy(y, z)
    end
    compile(nn)
end

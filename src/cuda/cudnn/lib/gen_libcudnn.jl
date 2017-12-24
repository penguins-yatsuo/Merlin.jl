# Adapted from CUDArt.jl/wrap_cuda.jl
using Clang

# The following two likely need to be modified for the host system
includes = ["/usr/local/include",
            "/usr/include",
            "/usr/local/cuda/include",
            "/usr/lib/gcc/x86_64-linux-gnu/5.4.0/include",
            "/usr/lib/gcc/x86_64-linux-gnu/5.4.0/include-fixed"]
headers = ["/home/cl/shindo/lime/cudnn.h"]

# Customize how functions, constants, and structs are written
#const skip_expr = [:(const CUDART_DEVICE = __device__)]
#const skip_error_check = [:cudaStreamQuery,:cudaGetLastError,:cudaPeekAtLastError]
const skip_expr = []
const skip_error_check = []

function rewriter(ex::Expr)
    println(ex)
    if in(ex, skip_expr)
        return :()
    end
    # Empty types get converted to Void
    if ex.head == :type
        a3 = ex.args[3]
        if isempty(a3.args)
            objname = ex.args[2]
            return :(const $objname = Void)
        end
    end
    ex.head == :function || return ex
    decl, body = ex.args[1], ex.args[2]
    # omit types from function prototypes
    for i = 2:length(decl.args)
        a = decl.args[i]
        if typeof(a) == Expr && a.head == :(::)
            decl.args[i] = a.args[1]
        end
    end
    # Error-check functions that return a cudaError_t (with some omissions)
    ccallexpr = body.args[1]
    if ccallexpr.head != :ccall
        #println(ccallexpr.head)
        #error("Unexpected body expression: ", body)
    end
    rettype = ccallexpr.args[2]
    if rettype == :cudnnStatus_t
        fname = decl.args[1]
        if !in(fname, skip_error_check)
            body.args[1] = Expr(:call, :checkstatus, deepcopy(ccallexpr))
        end
    end
    ex
end
rewriter(A::Array) = [rewriter(a) for a in A]
rewriter(s::Symbol) = string(s)
rewriter(arg) = arg

context=wrap_c.init(output_file="libcudnn.jl",
                    common_file="libcudnn_types.jl",
                    header_library=x->"libcudnn",
                    headers = headers,
                    clang_includes=includes,
                    header_wrapped=(x,y)->contains(y,"cudnn"),
                    rewriter=rewriter)

context.options = wrap_c.InternalOptions(true,true)  # wrap structs, too

# Execute the wrap
run(context)

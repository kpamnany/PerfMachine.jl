module Sbatch
export Cluster, CaltechCentral
export sbatch, modules

abstract type Cluster end
struct CaltechCentral <: Cluster end

function sbatch end
function modules end

function modules(::CaltechCentral)
    ["julia/1.5.4 ", "cuda/10.2 ", "openmpi/4.0.4_cuda-10.2 "]
end

function sbatch(
    cluster::Cluster,
    script::String,
    project_dir = "",
    wait = true;
    exclusive = true,
    time = Time(0, 30, 0),
    nodes = 1,
    ntasks = 1,
    cpus_per_task = 1,
    gpu = 0,
    kwargs...,
)
    project = isempty(project_dir) ? "" : "--project=$(project_dir)"
    args = String[]
    exclusive && push!(args, "--exclusive")
    append!(args, [
        "--export=ALL",
        "--time=$(string(time))",
        "--nodes=$(nodes)",
        "--ntasks=$(ntasks)",
        "--cpus-per-task=$(cpus_per_task)",
    ])
    if gpu > 0
        push!(args, "--gres=gpu:$(gpu)")
        extra_arg = ""
    else
        extra_arg = "--disable-gpu"
    end
    append!(args, ["--$kw=$val" for (kw, val) in kwargs])

    ss, io = mktemp()
    println(io, "set -euo pipefail")
    println(io, "set -x")
    println(io, "export TICTOC_PRINT_RESULTS=1")
    println(io, "export OPENBLAS_NUM_THREADS=1")
    println(io, "module load $(modules(cluster)...)")
    println(io, "time mpiexec julia --color=no $(project) $(script) $(extra_arg)")
    close(io)

    sbatchcmd = `echo sbatch`
    append!(sbatchcmd.exec, args)
    append!(sbatchcmd.exec, `$ss`)

    # XXX: debug
    for wd in sbatchcmd.exec
        print(wd, " ")
    end
    println()

    _, jobid = rsplit(chomp(String(read(sbatchcmd))), limit = 2)
    return String(jobid)
end

end

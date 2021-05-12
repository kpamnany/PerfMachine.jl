# runner.jl
#
# Launch a series of runs to generate some performance logs

using DataFrames, Dates, OrderedCollections

    #CM_dir = joinpath(dirname(@__DIR__), "..", "ClimateMachine.jl")

function main(args::Array{String})
    df1 = parse_sbatch_log(args[1])
    sort!(df1, order(:name))
    df2 = parse_sbatch_log(args[2])
    sort!(df2, order(:name))
    @assert all(df1.name .== df2.name)
    dfd = df1.tottime ./ df2.tottime
    dfn = df1.name
    println(DataFrame(name = dfn, df1 = df1.tottime, df2 = df2.tottime, diff = dfd))
    return (dfd, dfn)
end


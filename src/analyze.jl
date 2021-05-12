# analyze.jl
#
# Parse TicToc output from an `sbatch` log.

using DataFrames, OrderedCollections

function parse_sbatch_log(filename::String)
    nranks = Dict{String, Float64}()
    ncalls = Dict{String, Float64}()
    tottime = Dict{String, Float64}()
    allocgb = Dict{String, Float64}()
    gctime = Dict{String, Float64}()

    lns = readlines(filename)
    for (i, ln) in enumerate(lns)
        startswith(ln, "tictoc__") || continue
        wds = split(ln, ",")
        name = wds[1]
        ncalls_i = parse(Int, wds[2])
        tottime_i = parse(Int, wds[3])
        allocgb_i = parse(Int, wds[4])
        gctime_i = parse(Int, wds[5])

        nranks[name] = get(nranks, name, 0) + 1
        ncalls[name] = get(ncalls, name, 0) + ncalls_i
        tottime[name] = get(tottime, name, 0) + tottime_i
        allocgb[name] = get(allocgb, name, 0) + allocgb_i
        gctime[name] = get(gctime, name, 0) + gctime_i
    end
    for name in keys(ncalls)
        tottime[name] <= 0 && continue
        tottime[name] /= (nranks[name] * ncalls[name] * 1e9)
        allocgb[name] /= (nranks[name] * ncalls[name] * 1e9)
        gctime[name] /= (nranks[name] * ncalls[name] * 1e9)
        ncalls[name] /= nranks[name]
    end
    df = DataFrame()
    df.name = collect(keys(ncalls))
    df.nranks = collect(values(nranks))
    df.ncalls = collect(values(ncalls))
    df.tottime = collect(values(tottime))
    df.allocgb = collect(values(allocgb))
    df.gctime = collect(values(gctime))
    return df
end


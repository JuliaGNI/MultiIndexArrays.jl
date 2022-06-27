using MultiIndexArrays
using Documenter

DocMeta.setdocmeta!(MultiIndexArrays, :DocTestSetup, :(using MultiIndexArrays); recursive=true)

makedocs(;
    modules=[MultiIndexArrays],
    authors="Michael Kraus",
    repo="https://github.com/JuliaGNI/MultiIndexArrays.jl/blob/{commit}{path}#{line}",
    sitename="MultiIndexArrays.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaGNI.github.io/MultiIndexArrays.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Library" => "library.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaGNI/MultiIndexArrays.jl",
    devbranch="main",
)

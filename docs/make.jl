using NeperStructureGenerator
using Documenter

DocMeta.setdocmeta!(NeperStructureGenerator, :DocTestSetup, :(using NeperStructureGenerator); recursive=true)

makedocs(;
    modules=[NeperStructureGenerator],
    authors="Said Harb",
    sitename="NeperStructureGenerator.jl",
    format=Documenter.HTML(;
        canonical="https://saidharb.github.io/NeperStructureGenerator.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "API" => "API.md",
        "Internals" => "devdocs.md",
    ],
)

deploydocs(;
    repo="github.com/saidharb/NeperStructureGenerator.jl",
    devbranch="main",
)

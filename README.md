# NeperStructureGenerator
[![experimental](http://badges.github.io/stability-badges/dist/experimental.svg)](http://github.com/badges/stability-badges)
This package is currently **Work in Progress**.

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://saidharb.github.io/NeperStructureGenerator.jl/dev/)
[![Build Status](https://github.com/saidharb/NeperStructureGenerator.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/saidharb/NeperStructureGenerator.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/saidharb/NeperStructureGenerator.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/saidharb/NeperStructureGenerator.jl)

`NeperStructureGenerator.jl` aims to facilitate generating microstructures with the software neper in julia.
Compared to using `neper_jll` directly, `NeperStructureGenerator.jl` provides the following advantages
* Julian style functions, e.g. `tesselate`, instead of system calls
* Dictionary-based neper configurations
* `TOML` files to record the specific settings used to generate a tesselation or a mesh
* A folder structure for organizing multiple meshes for the same tesselation

## Examples

#### Creating a tesselation

The following command will generate a default two-dimensional tesselation and save it under the default name. It returns the path to the tesselation.
```julia
t1 = NeperStructureGenerator.tesselate()
```

Using the path to the tesselation file, it is straightforward to create a default mesh.
```julia
m1 = NeperStructureGenerator.mesh(tess_path = t1)
```

To visualize the tesselation and the mesh, provide the directory containing both and an output directory.
```julia
NeperStructureGenerator.visualize_directory("path/to/output/dir", "path/to/mesh/and/tesselation/directory")
```
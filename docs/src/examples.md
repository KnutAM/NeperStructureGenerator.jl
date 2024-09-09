## Examples

1. Tesselation Example
You can generate a tessellation using the NeperStructureGenerator.tesselate function, providing it with specific parameters like number of cells, dimension, periodicity, and more. The default tesselation has the following parameters:

```julia
const tesselation_defaults = Dict(
    "id" => 1, # used as seed
    "n" => 10,
    "dim" => 2,
    "reg" => 0,
    "periodicity" => "none"
)
````
In order to generate a custom tesselation, create a new dictionary and pass it to `tesselate()`. Below is an example of how to generate a tessellation with 100 cells in 3D:

```julia 
using NeperStructureGenerator

tesselation_params = Dict("n" => 100, "dim" => 3, "periodicity" => "none")

NeperStructureGenerator.tesselate(tesselation_params)
```

This will generate a 3D tessellation with 100 cells.

2. Meshing Example

Once you have a tessellation, you can generate a mesh using the NeperStructureGenerator.mesh function.  The default mesh has the following parameters:
```julia 
const meshing_defaults = Dict( "cl" => 0.5, "order" => 1, "elttype" => "tet" )
```

In order to generate a custom mesh, create a new dictionary and pass it to `mesh()`. The following example shows how to create a custom mesh from the generated tessellation:

```julia
using NeperStructureGenerator

# Define custom meshing parameters
meshing_params = Dict("cl" => 0.1, "order" => 1, "elttype" => "tet")

# Create mesh from previously generated tessellation
NeperStructureGenerator.mesh(meshing_params)
```
This will produce a mesh with tetrahedral elements and a characteristic length of 0.1.

3. Visualize Tesselation Example

To visualize the generated tessellation, use the `NeperStructureGenerator.visualize_tesselation()` function. Here's an example:

```julia
using NeperStructureGenerator

# Visualize the tessellation from the directory
NeperStructureGenerator.visualize_tesselation("path/to/output/dir", "path/to/tessellation")
```
This command will create a visualization of the tessellation stored in the specified directory.

4. Visualize Mesh Example

To visualize a mesh, the `NeperStructureGenerator.visualize_mesh()` function can be used. Here's an example:

```julia
using NeperStructureGenerator

# Visualize the mesh from the directory
NeperStructureGenerator.visualize_mesh("path/to/output/dir", "path/to/mesh")
```
This will display the mesh located in the provided path.

Alternatively, provide a mesh name:
```julia
using NeperStructureGenerator

# Visualize the mesh from the directory
NeperStructureGenerator.visualize_mesh("path/to/output/dir", "path/to/tesselation/dir", "mesh_name")
```
This will display the mesh with the corresponding name in the tesselation directory

5. Visualize Directory Example

You can visualize all tessellations and meshes in a specific directory using the `NeperStructureGenerator.visualize_directory()` function. Here is how you can visualize all files in a directory:

```julia
using NeperStructureGenerator

# Visualize all structures in a directory
NeperStructureGenerator.visualize_directory("path/to/output/directory", "path/to/directory/to/be/visualized")
```
This command will automatically visualize all available tessellations and meshes found in the specified directory.


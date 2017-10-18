# freesurfer_to_3dprint
<img alt="Right Lateral" src="/images/right_lateral.png" width=400>
utilities to help in 3d printing of freesurfer surface images

This is in early stages. The goal is to have a defined pathway to start with a freesurfer recon-all output and end up with a 3d model ready for 3d printing in full color based on a chosen parcellation.

The first part has been quite easy for awhile as mris_convert can convert a surface image to an stl file which can be 3d printed, but I couldn't find any examples of getting the color informatino out, though it turns out to be not too difficult.

At the moment the stream is:
   1. mris_convert surface to ascii format
   2. generate a modified ctab file that has each color coded as a single 24 bit integer
   3. mris_convert to output the ascii format parcstats/annot option to get a color value per vertex
   4. combine these two differing formats into a single ascii format file
   5. use a modified srf2obj to output an stl with per-vertex color information (supported by meshmixer and some other software)
   6. run this obj file through a meshlab script to decimate the number of faces, run a few simple fixes, and then output an x3d file with per-vertex color information included, which is compatible with shapeways printing at least. A script is also provided to do texture mapping and output a texture image if that's required instead.
   
Original srf2obj script from Anderson Winkler at https://brainder.org/2012/05/08/importing-freesurfer-cortical-meshes-into-blender/

Credit for helping me figure out that meshlab can create the texture maps from per-vertex coloring from https://groups.google.com/forum/#!topic/skanect/HBoixK8rdLc (though this turns out to be unnecessary as shapeways and probably other places support per-vertex or per-face coloring, which I wasn't aware of initially so went down a rabbit hole of trying to figure out an automated way to UV map the colors on).

Data in the sample output folder were generated with two commands:

./fsto3d.sh -s ./sample_data/ma/

Without options, this creates the aparc colored file like this

<img alt="Right Lateral" src="/images/right_lateral.png" width=400>
<img alt="Left Medial" src="/images/left_medial.png" width=400>
<img alt="Anterior" src="/images/anterior.png" width=400>

and the following commands would generate lobe colored files

mri_annotation2label --subject ma --hemi lh --outdir ./label/ --lobesStrict lh.lobes

mri_annotation2label --subject ma --hemi rh --outdir ./label/ --lobesStrict rh.lobes

mri_annotation2label --subject ma --hemi lh --annotation lobes --ctab label/lobes.annot.ctab

./fsto3d.sh -s ./sample_data/ma/ -p lobes

<img alt="Left Lateral Lobes" src="/images/left_lateral_lobes.png" width=400>

Command Usage:
```
$ ./fsto3d.sh
Basic usage: fsto3d.sh -s /path/to/freesurfer/subject -u [pial|white|inflated] -p annotation

Required Options
-s   Sets the path to a freesurfer subject

Other options
-u   Which surface do you want to use. Default is pial
-p   Which annotation file to use. Default is aparc
-b   Hemisphere to process (lh or rh). Default is both
-m   Meshlab script file to apply to the mesh. Default is
     /home/slab/users/mangstad/repos/freesurfer_to_3dprint/meshlab/simplify_clean_vertex.mlx
-n   String to include in the name for the final files. Default is color
-h   Show this help information.
```

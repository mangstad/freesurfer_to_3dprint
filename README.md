# freesurfer_to_3dprint
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

and 

./fsto3d.sh -s ./sample_data/ma/ -p lobes

The lobes annotation and colortab files were generated from freesurfer like this:

mri_annotation2label --subject ma --hemi lh --outdir ./label/ --lobesStrict lh.lobes

mri_annotation2label --subject ma --hemi rh --outdir ./label/ --lobesStrict rh.lobes

mri_annotation2label --subject ma --hemi lh --annotation lobes --ctab label/lobes.annot.ctab


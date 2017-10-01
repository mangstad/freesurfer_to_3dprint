# freesurfer_to_3dprint
1;3201;0cutilities to help in 3d printing of freesurfer surface images

This is in extremely early stages. The goal is to have a defined pathway to start with a freesurfer recon-all output and end up with a 3d model ready for 3d printing along with having a texture map for the model colored based on a particular chosen parcellation.

Obviously the first part of this is pretty easy as mris_convert can convert a surface image to an stl file which could be 3d printed, but the texture map portion is more circuitous.

At the moment the plan is:
   1. mris_convert surface to ascii format
   2. generate a modified ctab file that has each color coded as a single 24 bit integer
   3. mris_convert to output the ascii format parcstats/annot option to get a color value per vertex
   4. combine these two differing formats into a single ascii format file
   5. use a modified srf2obj to output an stl with per-vertex color information (supported by meshmixer and some other software)
   6. import into blender? or might have to export as a ply file from meshmixer and import that into blender
   7. add a material to the mesh and check the paint vertex by color option
   8. render this image and bake the material to a texture
   9. save out that texture file for use with the model
   
Actually, seems like meshlab might be able to directly calculate a texture map from the per-vertex color, so steps 6-9 may be much simpler
https://groups.google.com/forum/#!topic/skanect/HBoixK8rdLc


just leaving this here for the moment to remind me how to generate lobe files 
mri_annotation2label --subject ma --hemi lh --outdir ./label/ --lobesStrict lh.lobes
mri_annotation2label --subject ma --hemi rh --outdir ./label/ --lobesStrict rh.lobes
mri_annotation2label --subject ma --hemi lh --annotation lobes --ctab label/lobes.annot.ctab


data in the sample output folder were generated with:
./fsto3d.sh -s ./sample_data/ma/
and
./fsto3d.sh -s ./sample_data/ma/ -p lobes

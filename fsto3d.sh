#!/bin/bash

SCRIPT=`basename ${BASH_SOURCE[0]}`
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

## Let's do some admin work to find out the variables to be used here
BOLD='\e[1;31m'         # Bold Red
REV='\e[1;32m'       # Bold Green
OFF=$(tput sgr0)

#Help function
function HELP {
    echo -e "${REV}Basic usage:${OFF} ${BOLD}$SCRIPT -s /path/to/freesurfer/subject -u [pial|white|inflated] -p annotation${OFF}"\\n
    echo -e "${REV}Required Options${OFF}"
    echo -e "${REV}-s ${OFF}  Sets the path to a freesurfer subject${BOLD}${OFF}"\\n
    echo -e "${REV}Other options${OFF}"
    echo -e "${REV}-u ${OFF}  Which surface do you want to use. Default is ${BOLD}${surf}${OFF}"
    echo -e "${REV}-p ${OFF}  Which annotation file to use. Default is ${BOLD}${parc}${OFF}"
    echo -e "${REV}-b ${OFF}  Hemisphere to process (lh or rh). Default is ${BOLD}${hemi}${OFF}"
    echo -e "${REV}-m ${OFF}  Meshlab script file to apply to the mesh. Default is \\n     ${BOLD}${mlx}${OFF}"
    echo -e "${REV}-n ${OFF}  String to include in the name for the final files. Default is ${BOLD}${name}${OFF}"
    echo -e "${REV}-h ${OFF}  Show this help information."
    exit 1
}

hemi="both"
mlx="${DIR}/meshlab/simplify_clean_vertex.mlx"
name="color"
surf="pial"
parc="aparc"

if [ $# -lt 2 ]; then
    HELP
fi

while getopts s:b:u:p:m:n:h FLAG; do
    case $FLAG in
	s)
	    path=$OPTARG
	    ;;
	b)
	    hemi=$OPTARG
	    ;;
	u)
	    surf=$OPTARG
	    ;;
	p)
	    parc=$OPTARG
	    ;;
	m)
	    mlx=$OPTARG
	    ;;
	n)
	    name=$OPTARG
	    ;;
	h)
	    HELP
	    ;;
	\?) #unrecognized option - show help
	    echo -e \\n"Option -${BOLD}$OPTARG${OFF} not allowed."
	    HELP
	    ;;
	*) #no options
	    HELP
	    ;;
    esac
done

#make 3d printing output folder
mkdir -p ${path}/3dp

LOG=${path}/3dp/fsto3d.log

#convert surface(s) to ASCII format
if [ $hemi = "both" ];
then
    mris_convert ${path}/surf/lh.${surf} ${path}/3dp/lh.${surf}.asc >> ${LOG}
    mris_convert ${path}/surf/rh.${surf} ${path}/3dp/rh.${surf}.asc >> ${LOG}
else
    mris_convert ${path}/surf/${hemi}.${surf} ${path}/3dp/${hemi}.${surf}.asc >> ${LOG}
fi

#convert ctab to better format with python utilities
python ${DIR}/fsto3d.py -a ${path}/label/${parc}.annot.ctab ${path}/3dp/${parc}.24bit.ctab >> ${LOG}

#convert surface(s) to ASCII format with color integer values
if [ $hemi = "both" ];
then
    mris_convert --annot ${path}/label/lh.${parc}.annot --parcstats ${path}/3dp/${parc}.24bit.ctab ${path}/surf/lh.${surf} ${path}/3dp/lh.${surf}.${parc}.asc >> ${LOG}
    mris_convert --annot ${path}/label/rh.${parc}.annot --parcstats ${path}/3dp/${parc}.24bit.ctab ${path}/surf/rh.${surf} ${path}/3dp/rh.${surf}.${parc}.asc >> ${LOG}
else    
    mris_convert --annot ${path}/label/${hemi}.${parc}.annot --parcstats ${path}/3dp/${parc}.24bit.ctab ${path}/surf/${hemi}.${surf} ${path}/3dp/${hemi}.${surf}.${parc}.asc >> ${LOG}
fi

#paste together the two ASCII files to get both vertex/face info and color info
if [ $hemi = "both" ];
then
    python ${DIR}/fsto3d.py -b ${path}/3dp/lh.${surf}.asc ${path}/3dp/lh.${surf}.${parc}.asc ${path}/3dp/lh.${surf}.${parc}.color.asc >> ${LOG}
    python ${DIR}/fsto3d.py -b ${path}/3dp/rh.${surf}.asc ${path}/3dp/rh.${surf}.${parc}.asc ${path}/3dp/rh.${surf}.${parc}.color.asc >> ${LOG}
else
    python ${DIR}/fsto3d.py -b ${path}/3dp/${hemi}.${surf}.asc ${path}/3dp/${hemi}.${surf}.${parc}.asc ${path}/3dp/${hemi}.${surf}.${parc}.color.asc >> ${LOG}
fi

#convert to vertex-colored obj file
if [ $hemi = "both" ];
then
    ${DIR}/srf2obj_color ${path}/3dp/lh.${surf}.${parc}.color.asc > ${path}/3dp/lh.${surf}.${parc}.${name}.obj 
    ${DIR}/srf2obj_color ${path}/3dp/rh.${surf}.${parc}.color.asc > ${path}/3dp/rh.${surf}.${parc}.${name}.obj 
else
    ${DIR}/srf2obj_color ${path}/3dp/${hemi}.${surf}.${parc}.color.asc > ${path}/3dp/${hemi}.${surf}.${parc}.${name}.obj 
fi

#now run meshlabserver script to reduce complexity, fix some potential issues, and convert vertex coloring to texture map
if [ $hemi = "both" ];
then
    cp ${mlx} ${path}/3dp/script.mlx
    sed -i "s/TEMP_TEXTURE/lh.${surf}.${parc}/" ${path}/3dp/script.mlx
    meshlabserver -i ${path}/3dp/lh.${surf}.${parc}.${name}.obj -s ${path}/3dp/script.mlx -o ${path}/3dp/lh.${surf}.${parc}.${name}.final.x3d -om vc fc fn wc wn wt >> ${LOG}
    rm ${path}/3dp/script.mlx
    
    cp ${mlx} ${path}/3dp/script.mlx
    sed -i "s/TEMP_TEXTURE/rh.${surf}.${parc}/" ${path}/3dp/script.mlx
    meshlabserver -i ${path}/3dp/rh.${surf}.${parc}.${name}.obj -s ${path}/3dp/script.mlx -o ${path}/3dp/rh.${surf}.${parc}.${name}.final.x3d -om vc fc fn wc wn wt >> ${LOG}
    rm ${path}/3dp/script.mlx
else
    cp ${mlx} ${path}/3dp/script.mlx
    sed -i "s/TEMP_TEXTURE/${hemi}.${surf}.${parc}/" ${path}/3dp/script.mlx
    meshlabserver -i ${path}/3dp/${hemi}.${surf}.${parc}.${name}.obj -s ${path}/3dp/script.mlx -o ${path}/3dp/${hemi}.${surf}.${parc}.${name}.final.x3d -om vc fc fn wc wn wt >> ${LOG}
    rm ${path}/3dp/script.mlx
fi

#cleanup intermediate files
rm ${path}/3dp/${parc}.24bit.ctab
rm ${path}/3dp/*.${surf}.${parc}.color.asc
rm ${path}/3dp/*.${surf}.${parc}.asc
rm ${path}/3dp/*.${surf}.asc

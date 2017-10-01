#!/bin/bash

SCRIPT=`basename ${BASH_SOURCE[0]}`
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

## Let's do some admin work to find out the variables to be used here
BOLD='\e[1;31m'         # Bold Red
REV='\e[1;32m'       # Bold Green

#Help function
function HELP {
    echo -e "${REV}Basic usage:${OFF} ${BOLD}$SCRIPT -d helloworld ${OFF}"\\n
    echo -e "${REV}The following switches are recognized. $OFF "
    echo -e "${REV}-p ${OFF}  --Sets the environment to use for installing python ${OFF}. Default is ${BOLD} /usr/bin ${OFF}"
    echo -e "${REV}-d ${OFF}  --Sets the directory whose virtualenv is to be setup. Default is ${BOLD} local folder (.) ${OFF}"
    echo -e "${REV}-v ${OFF}  --Sets the python version that you want to install. Default is ${BOLD} 2.7 ${OFF}"
    echo -e "${REV}-h${OFF}  --Displays this help message. No further functions are performed."\\n
    echo -e "Example: ${BOLD}$SCRIPT -d helloworld -p /opt/py27env/bin -v 2.7 ${OFF}"\\n
    exit 1
}

hemi="b"
mlx="${DIR}/meshlab/simplify_clean_texture.mlx"
name="color"

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
    esac
done

#make 3d printing output folder
mkdir ${path}/3dp

LOG=${path}/3dp/fsto3d.log

#convert surface(s) to ASCII format
if [ $hemi = "b" ];
then
    mris_convert ${path}/surf/lh.${surf} ${path}/3dp/lh.${surf}.asc >> ${LOG}
    mris_convert ${path}/surf/rh.${surf} ${path}/3dp/rh.${surf}.asc >> ${LOG}
else
    mris_convert ${path}/surf/${hemi}.${surf} ${path}/3dp/${hemi}.${surf}.asc >> ${LOG}
fi

#convert ctab to better format with python utilities
python ${DIR}/fsto3d.py -a ${path}/label/${parc}.annot.ctab ${path}/3dp/${parc}.24bit.ctab >> ${LOG}

#convert surface(s) to ASCII format with color integer values
if [ $hemi = "b" ];
then
    mris_convert --annot ${path}/label/lh.${parc}.annot --parcstats ${path}/3dp/${parc}.24bit.ctab ${path}/surf/lh.${surf} ${path}/3dp/lh.${surf}.${parc}.asc >> ${LOG}
    mris_convert --annot ${path}/label/rh.${parc}.annot --parcstats ${path}/3dp/${parc}.24bit.ctab ${path}/surf/rh.${surf} ${path}/3dp/rh.${surf}.${parc}.asc >> ${LOG}
else    
    mris_convert --annot ${path}/label/${hemi}.${parc}.annot --parcstats ${path}/3dp/${parc}.24bit.ctab ${path}/surf/${hemi}.${surf} ${path}/3dp/${hemi}.${surf}.${parc}.asc >> ${LOG}
fi

#paste together the two ASCII files to get both vertex/face info and color info
if [ $hemi = "b" ];
then
    python ${DIR}/fsto3d.py -b ${path}/3dp/lh.${surf}.asc ${path}/3dp/lh.${surf}.${parc}.asc ${path}/3dp/lh.${surf}.${parc}.color.asc >> ${LOG}
    python ${DIR}/fsto3d.py -b ${path}/3dp/rh.${surf}.asc ${path}/3dp/rh.${surf}.${parc}.asc ${path}/3dp/rh.${surf}.${parc}.color.asc >> ${LOG}
else
    python ${DIR}/fsto3d.py -b ${path}/3dp/${hemi}.${surf}.asc ${path}/3dp/${hemi}.${surf}.${parc}.asc ${path}/3dp/${hemi}.${surf}.${parc}.color.asc >> ${LOG}
fi

#convert to vertex-colored obj file
if [ $hemi = "b" ];
then
    ${DIR}/srf2obj_color ${path}/3dp/lh.${surf}.${parc}.color.asc > ${path}/3dp/lh.${surf}.${parc}.${name}.obj 
    ${DIR}/srf2obj_color ${path}/3dp/rh.${surf}.${parc}.color.asc > ${path}/3dp/rh.${surf}.${parc}.${name}.obj 
else
    ${DIR}/srf2obj_color ${path}/3dp/${hemi}.${surf}.${parc}.color.asc > ${path}/3dp/${hemi}.${surf}.${parc}.${name}.obj 
fi

#now run meshlabserver script to reduce complexity, fix some potential issues, and convert vertex coloring to texture map
if [ $hemi = "b" ];
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

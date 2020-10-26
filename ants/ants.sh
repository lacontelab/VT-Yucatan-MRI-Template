#!/bin/bash

#
# run ANTs template generation script for 58 skull-stripped pig brains
#

set -o errexit

TAR_GZ_URL='https://github.com/lacontelab/VT-Yucatan-MRI-Template/releases/download/v0.1.1/MRI_data_n70_AFNI_v0.1.tar.gz'
DATA_PATH='../data'

# if input/output directory does not exist, download data and create it 
if [ ! -d $DATA_PATH ]; then
  mkdir -p $DATA_PATH
  wget $TAR_GZ_URL
  tar -xzf $(basename $TAR_GZ_URL) --strip-components=1 -C $DATA_PATH
  rm -vf $(basename $TAR_GZ_URL) 
fi

# collect datasets and make sure it exists as .nii.gz
dsets=''
for id in $(cat ../ids_template_n58.txt); do 
  nii="../data/$id/t1_ss_acpc.nii.gz"
  if [ ! -f $nii ]; then
    # check if AFNI HEAD/BRIK exists
    brick="../data/$id/t1_ss+acpc"
    if [ -f ${brick}.HEAD ]; then
      echo Converting HEAD/BRIK to nii: $nii
      3dcopy $brick $nii
    else
       echo "ERROR: Can not find input dataset: $nii or: $brick"
       exit 1
    fi
  fi
  dsets="$dsets $nii"
done
      
echo $dsets
echo 

## command line options from  help:
## antsMultivariateTemplateConstruction2.sh
## -d 3  -> three dimensional 
## -i 3  -> iterations (default: 4)
## -k 1  -> number of modatlities
## -f 4x2x1 -> Shrink factors?
## -s 2x1x0vox  -> Smoothing factors
## -q 30x20x4  -> max iterations for each pairwise registration 
## -t SyN -> Type of transformation model used for registration
## -m CC  -> symilarity matric used for registration CC: cross-correlation
## -c 0  -> control for parallel computation
## -o MY 
## sub*avg.nii.gz

antsMultivariateTemplateConstruction2.sh -d 3 -i 3 -k 1 \
  -f 4x2x1 -s 2x1x0vox -q 30x20x4 -t SyN  -m CC -c 0 -o ANTS_n58 $dsets | tee -a ants.log 2>&1


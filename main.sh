#!/bin/bash

#############################################################################
#                                                                           #
# main.sh                                                                   #
#                                                                           #
# Top-level script to run VT-Yucatan-MRI-Template processing                #
#                                                                           #
# VT-Yucatan-MRI-Template is free software: you can redistribute it and/or  #
# modify it under the terms of the GNU General Public License as published  #
# by the Free Software Foundation, either version 3 of the License, or      # 
# (at your option) any later version.                                       #
#                                                                           #
# VT-Yucatan-MRI-Template is distributed in the hope that it will be        # 
# useful but WITHOUT ANY WARRANTY; without even the implied warranty of     #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             #
# GNU General Public License for more details.                              #
#                                                                           #
# You should have received a copy of the GNU General Public License         #
# along with this file.  If not, see <http://www.gnu.org/licenses/>.        #
#                                                                           #
#############################################################################

TAR_GZ_URL='https://github.com/lacontelab/VT-Yucatan-MRI-Template/releases/download/v0.1/MRI_data_n70_AFNI_v0.1.1.tar.gz'

# id of subject for initial alignment 
TEMPLATE_ID='8118' # median
#TEMPLATE_ID='8213'   # lightest 18.1 kg
#TEMPLATE_ID='53095'  # heaviest 30.3 kg

# output directory 
DATA_PATH=$(pwd)/data_${TEMPLATE_ID}

# set specific AFNI version
export PATH=/opt/afni/bin_AFNI_20.05.04/:$PATH

# exit at error
set -o errexit

# be verbose and print all commands
set -x

###############################################################################
###############################################################################
###############################################################################

# if input/output directory does not exist, download data and create it 
if [ ! -d $DATA_PATH ]; then
  mkdir -p $DATA_PATH
  wget $TAR_GZ_URL
  tar -xzf $(basename $TAR_GZ_URL) --strip-components=1 -C $DATA_PATH
  rm -vf $(basename $TAR_GZ_URL) 
fi

## segmentation into tissue types #############################################
## this is commented out by default, since data is released with tissue 
## tissue probability maps
#./run_GM_WM_CSF_segmentation.sh $DATA_PATH t1_ss acpc 

## iteration 0 ################################################################
# make sure initial subject for alignment is set up
./linear_alignment.sh ${DATA_PATH}/${TEMPLATE_ID} ${DATA_PATH}/${TEMPLATE_ID}/t1_ss+acpc

# linear alignment to initial subject
./run_linear_alignment.sh ids_template_n58.txt $DATA_PATH $DATA_PATH/templates/${TEMPLATE_ID}+tlrc 

# create initial template (TL0n58+tlrc)
TL_i0_prefix=${DATA_PATH}/templates/TL0n58
./create_template.sh ids_template_n58.txt $DATA_PATH t1_ss_un_linear_${TEMPLATE_ID}+tlrc $TL_i0_prefix

## iteration 1 ################################################################
TL_i1_prefix=${DATA_PATH}/templates/TL0L1n58
TNL_i1_prefix=${DATA_PATH}/templates/TL0N1n58
# linear
./run_linear_alignment.sh ids_template_n58.txt $DATA_PATH ${TL_i0_prefix}+tlrc
./create_template.sh ids_template_n58.txt $DATA_PATH t1_ss_un_linear_$(basename $TL_i0_prefix)+tlrc $TL_i1_prefix

# non-linear
./run_nonlinear_alignment.sh ids_template_n58.txt $DATA_PATH ${TL_i0_prefix}+tlrc
./create_template.sh ids_template_n58.txt $DATA_PATH t1_ss_un_nonlinear_$(basename $TL_i0_prefix)+tlrc $TNL_i1_prefix

# validate using out-of-template subjects (n=12) [optional]
./run_linear_alignment.sh ids_validation_n12.txt $DATA_PATH ${TL_i0_prefix}+tlrc
./run_nonlinear_alignment.sh ids_validation_n12.txt $DATA_PATH ${TL_i0_prefix}+tlrc

# extract landmark locations before and after alignment [optional] 
./extract_landmark_coordinates.sh ids_n70.txt $DATA_PATH $(basename ${TL_i0_prefix}) linear
./extract_landmark_coordinates.sh ids_n70.txt $DATA_PATH $(basename ${TL_i0_prefix}) nonlinear

## iteration 2 ################################################################
TL_i2_prefix=${DATA_PATH}/templates/TL0L1L2n58
TNL_i2_prefix=${DATA_PATH}/templates/TL0N1N2n58
# linear
./run_linear_alignment.sh ids_template_n58.txt $DATA_PATH ${TL_i1_prefix}+tlrc
./create_template.sh ids_template_n58.txt $DATA_PATH t1_ss_un_linear_$(basename $TL_i1_prefix)+tlrc $TL_i2_prefix

# non-linear
# Keep in mind: Need to run linear first. Non-linear uses linear as starting point 
./run_linear_alignment.sh ids_template_n58.txt $DATA_PATH ${TNL_i1_prefix}+tlrc
./run_nonlinear_alignment.sh ids_template_n58.txt $DATA_PATH ${TNL_i1_prefix}+tlrc
./create_template.sh ids_template_n58.txt $DATA_PATH t1_ss_un_nonlinear_$(basename $TNL_i1_prefix)+tlrc $TNL_i2_prefix

# validate using out-of-template subjects (n=12) [optional]
./run_linear_alignment.sh ids_validation_n12.txt $DATA_PATH ${TL_i1_prefix}+tlrc
./run_linear_alignment.sh ids_validation_n12.txt $DATA_PATH ${TNL_i1_prefix}+tlrc
./run_nonlinear_alignment.sh ids_validation_n12.txt $DATA_PATH ${TNL_i1_prefix}+tlrc

# extract landmark locations before and after alignment [optional] 
./extract_landmark_coordinates.sh ids_n70.txt $DATA_PATH $(basename ${TL_i1_prefix}) linear
./extract_landmark_coordinates.sh ids_n70.txt $DATA_PATH $(basename ${TNL_i1_prefix}) nonlinear

## iteration 3 ################################################################
TL_i3_prefix=${DATA_PATH}/templates/TL0L1L2L3n58
TNL_i3_prefix=${DATA_PATH}/templates/TL0N1N2N3n58
# linear
./run_linear_alignment.sh ids_template_n58.txt $DATA_PATH ${TL_i2_prefix}+tlrc
./create_template.sh ids_template_n58.txt $DATA_PATH t1_ss_un_linear_$(basename $TL_i2_prefix)+tlrc $TL_i3_prefix

# non-linear
# Keep in mind: Need to run linear first. Non-linear uses linear as starting point 
./run_linear_alignment.sh ids_template_n58.txt $DATA_PATH ${TNL_i2_prefix}+tlrc
./run_nonlinear_alignment.sh ids_template_n58.txt $DATA_PATH ${TNL_i2_prefix}+tlrc
./create_template.sh ids_template_n58.txt $DATA_PATH t1_ss_un_nonlinear_$(basename $TNL_i2_prefix)+tlrc $TNL_i3_prefix

# validate using out-of-template subjects (n=12) [optional]
./run_linear_alignment.sh ids_validation_n12.txt $DATA_PATH ${TL_i2_prefix}+tlrc
./run_linear_alignment.sh ids_validation_n12.txt $DATA_PATH ${TNL_i2_prefix}+tlrc
./run_nonlinear_alignment.sh ids_validation_n12.txt $DATA_PATH ${TNL_i2_prefix}+tlrc

# extract landmark locations before and after alignment [optional] 
./extract_landmark_coordinates.sh ids_n70.txt $DATA_PATH $(basename ${TL_i2_prefix}) linear
./extract_landmark_coordinates.sh ids_n70.txt $DATA_PATH $(basename ${TNL_i2_prefix}) nonlinear

#!/bin/bash

#############################################################################
#                                                                           #
# nonlinear_alignment.sh                                                    #
#                                                                           #
# Perform non-linear alignment with AFNI's 3dQwarp                          #
#                                                                           #
# This file is part of VT-Yucatan-MRI-Template                              #
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

## arguments 
SUB_DIR="$1"
TEMPLATE_DSET="$2"

## flags
RM_PRE=0    # remove data before analysis
RM_POST=1   # remove temporary data (rm_*) after analysis 

## defines
ANAT_DSET_PREFIX='t1'
# input datasets
ALIGN_PREFIX[0]='t1_ss_CSF_scale'
ALIGN_PREFIX[1]='t1_ss_WM_scale'
ALIGN_PREFIX[2]='t1_ss_GM_scale'
ALIGN_PREFIX[3]='voxel_AC'
ALIGN_PREFIX[4]='voxel_PC'
ALIGN_PREFIX[5]='voxel_HN'
INPUT_SPACE='acpc'

# used for naming of log files, etc
SCR_NAME="$(basename ${0%%.sh})"
BASE_DIR=$(pwd)

DATE_TIME2=$(date '+%Y%m%d_%H_%M')
DATE_TIME=$(date '+%Y/%m/%d %H:%M')

###############################################################################
### Initialization ############################################################
###############################################################################

# usage
n_args=2

if [ $# -ne $n_args ]; then
  echo
  echo -en "      Usage $0 <subject directory> <template dataset>\n"
  echo -en " ***  Need $n_args input arguments $# given!\n\n"
  exit 1
fi

# check if relative path is provided
if [ ${SUB_DIR:0:1} != '/' ]; then
  SUB_DIR=$(pwd)/$SUB_DIR
fi

if [ ! -d $SUB_DIR ]; then
  echo -en  "*** ERROR ($0): Subject directory: $SUB_DIR does not exist!\n" 
  exit 1
fi

# assign subject ID
subject_id=$(basename $SUB_DIR)

# check subject id and analysis name 
if [ -z "$subject_id" ]; then
  echo -en  "*** ERROR ($0): What happened? Subject ID not defined!\n" 
  exit 1
fi

if [ -z "$SCR_NAME" ]; then
  echo -en  "*** ERROR ($0): What happened? Script name not defined!\n"
  exit 1
fi

### Source definitions ########################################################
## source auxiliary functions
aux_file="$BASE_DIR/etc/auxiliary_functions.sh"
if [ -f $aux_file ]; then
  source $aux_file
else
  echo -en "  *** ERROR ($0): Could not source file: $aux_file\n"
  exit 1
fi

# print job to screen
info_message "***** Running ($0) for subject: $subject_id ***** "

# log file naming 
log_file="$SUB_DIR/../var/${SCR_NAME}_${subject_id}_${DATE_TIME2}.log"
info_message "Check log file: $log_file"

# log directory 
if [ ! -d $SUB_DIR/../var ]; then
  mkdir $SUB_DIR/../var
  echo -en "\n===== LOGFILE $subject_id $DATE_TIME ($SCR_NAME) ======\n\n" > $log_file 2>&1
  log_info_message "Crating directory for logs: $SUB_DIR/../var" "L0" "$log_file"
else
  echo -en "\n===== LOGFILE $subject_id $DATE_TIME ($SCR_NAME) ======\n\n" > $log_file 2>&1
fi

### Change directory ##########################################################
cd $SUB_DIR

### Remove old files ##########################################################
if [ $RM_PRE == 1 ]; then
  info_message "Cleaning up..."
  echo -en "*******************************************************************\n" >> $log_file 2>&1
  echo -en "Removing data files in: $out_dir_sub \n\n" >> $log_file 2>&1
  echo -en "Deleting:\n" >> $log_file 2>&1
  #rm -vf rm_* >> $log_file 2>&1

  echo -en "*******************************************************************\n\n" >> $log_file 2>&1
fi

###############################################################################
### Processing of anatomical ##################################################
################################################################################

# ****************************************
# Adapted from 3dQwarp -help:
# ****************************************
# 
# SAMPLE USAGE
# ------------
# * For registering a T1-weighted anat to a mildly blurry template at about
#   a 1x1x1 mm resolution (note that the 3dAllineate step, to give the
#   preliminary alignment, will also produce a dataset on the same 3D grid
#   as the TEMPLATE+tlrc dataset, which 3dQwarp requires):
# 
#     3dUnifize -prefix anatT1_U -input anatT1+orig
#     3dSkullStrip -input anatT1_U+orig -prefix anatT1_US -niter 400 -ld 40
#     3dAllineate -prefix anatT1_USA -base TEMPLATE+tlrc    \
#                 -source anatT1_US+orig -twopass -cost lpa \
#                 -1Dmatrix_save anatT1_USA.aff12.1D        \
#                 -autoweight -fineblur 3 -cmass
#     3dQwarp -prefix anatT1_USAQ -blur 0 3 \
#             -base TEMPLATE+tlrc -source anatT1_USA+tlrc
# 
#   You can then use the anatT1_USAQ_WARP+tlrc dataset to transform other
#   datasets (that were aligned with the input anatT1+orig) in the same way
#   using program 3dNwarpApply, as in
# 
#     3dNwarpApply -nwarp 'anatT1_USAQ_WARPtlrc anatT1_USA.aff12.1D' \
#                  -source NEWSOURCE+orig -prefix NEWSOURCE_warped
# 
#   For example, if you want a warped copy of the original anatT1+orig dataset
#   (without the 3dUnifize and 3dSkullStrip modifications), put 'anatT1' in
#   place of 'NEWSOURCE' in the above command.
# 
#   Note that the '-nwarp' option to 3dNwarpApply has TWO filenames inside
#   single quotes. This feature tells that program to compose (catenate) those
#   2 spatial transformations before applying the resulting warp. See the -help
#   output of 3dNwarpApply for more sneaky/cunning ways to make the program warp
#   datasets (and also see the example just below).


name=$(basename $TEMPLATE_DSET)
template_name=${name%%+tlrc}

in_prefix=${ANAT_DSET_PREFIX}_ss_un
xform_tpl_to_t1_affine="${template_name}_2_T1_affine.1D"

# check for input
if [ ! -f ${in_prefix}+${INPUT_SPACE}.HEAD ]; then
  log_error_exit "Input file: $in_prefix does not exist!" "$log_file"
fi

if [ ! -f ${TEMPLATE_DSET}.HEAD ]; then
  log_error_exit "Template dataset: $TEMPLATE_DSET does not exist!" "$log_file"
fi

# linear transform is calculated in linear alignment step
if [ ! -f ${xform_tpl_to_t1_affine} ]; then
  log_error_exit "Linear transformation matrix:  ${xform_tpl_to_t1_affine} does not exist!" "$log_file"
fi

## non-linear (qwarp) #########################################################
in_prefix=${ANAT_DSET_PREFIX}_ss_un
out_prefix=${ANAT_DSET_PREFIX}_ss_un_nonlinear_${template_name}
log_info_message ".. Non-linear alignment of: ${in_prefix}+${INPUT_SPACE} to: $TEMPLATE_DSET" "L1" "$log_file"

if [ ! -f ${out_prefix}+tlrc.HEAD ]; then
      3dQwarp -workhard -iwarp -blur 0 3 \
        -resample \
        -prefix $out_prefix \
        -base $TEMPLATE_DSET \
        -source ${in_prefix}+${INPUT_SPACE} \
        -iniwarp $xform_tpl_to_t1_affine >> $log_file 2>&1

        #-iwarp $xform_tpl_to_t1_qwarp \

  if [ $? -ne 0 ]; then
    log_error_exit "3dQwarp failed!" "$log_file"
  fi
else
   log_warning_message "Output file: ${out_prefix}+tlrc already exists!" "$log_file"
fi

# apply linear and non-linear transformations to datasets
for in_prefix in ${ALIGN_PREFIX[@]}; do

  out_prefix=${in_prefix}_nonlinear_${template_name}
  log_info_message ".. Applying linear and non-linear transformation to: ${in_prefix}+${INPUT_SPACE}" "L1" "$log_file"

  if [ ! -f ${in_prefix}+${INPUT_SPACE}.HEAD ]; then
    log_warning_message "Input file: ${in_prefix}+${INPUT_SPACE} does not exist!" "$log_file"
    continue
  fi

  if [ ! -f ${out_prefix}+tlrc.HEAD ]; then

    3dNwarpApply -prefix ${out_prefix} \
                 -master ${TEMPLATE_DSET} \
                 -nwarp "${ANAT_DSET_PREFIX}_ss_un_nonlinear_${template_name}_WARP+tlrc" \
                 -source ${in_prefix}+${INPUT_SPACE} >> $log_file 2>&1

    if [ $? -ne 0 ]; then
      log_error_exit "3dNWarpApply failed!" "$log_file"
    fi
  else
     log_warning_message "Output file: ${out_prefix}+tlrc already exists!" "$log_file"
  fi
done

###############################################################################
### Finish ####################################################################
###############################################################################

### Remove temporary files ####################################################
if [ $RM_POST == 1 ]; then
  info_message "Cleaning up..."
  echo -en "*******************************************************************\n" >> $log_file 2>&1
  echo -en "Removing data files in: $out_dir_sub \n\n" >> $log_file 2>&1
  echo -en "Deleting:\n" >> $log_file 2>&1
  rm -f rm_* >> $log_file 2>&1
  echo -en "*******************************************************************\n\n" >> $log_file 2>&1
fi

log_info_message "done" "L0" "$log_file"

exit 0


#!/bin/bash

#############################################################################
#                                                                           #
# GM_WM_CSF_segmentation.sh                                                 #
#                                                                           #
# Perform tissue segmentation using FSL FAST                                #
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
SUB_DIR=$1

## flags
RM_PRE=0    # remove data before analysis
RM_POST=1   # remove temporary data (rm_*) after analysis 

# input datasees
ANAT_DSET_PREFIX=$2
VIEW=$3

# used for naming of log files, etc
BASE_DIR=$(pwd)
SCR_NAME="$(basename ${0%%.sh})"
DATE_TIME=$(date '+%Y/%m/%d %H:%M')
DATE_TIME2=$(date '+%Y%m%d_%H_%M')

###############################################################################
### Initialization ############################################################
###############################################################################

# usage
n_args=3

if [ $# -ne $n_args ]; then
  echo
  echo -en "      Usage $0 <subject directory> <t1 prefix> <view (e.g. orig, acpc or tlrc)>\n"
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
  echo -en  "*** ERROR ($0): What happened?! subject ID is not defined\n" 
  exit 1
fi

if [ -z "$SCR_NAME" ]; then
  echo -en  "*** ERROR ($0): What happened?! Script name not defined?!\n"
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
  rm -vf rm_* >> $log_file 2>&1

  echo -en "*******************************************************************\n\n" >> $log_file 2>&1 
fi

input_prefix=${ANAT_DSET_PREFIX}

# check for input
if [ ! -f ${input_prefix}+${VIEW}.HEAD ]; then
  log_error_exit "Input file: ${input_prefix}+${VIEW}.HEAD does not exist!" "$log_file"
fi

# segment anatomical into WM, GM, and CSF ##########################################
log_info_message "Segmentation into WM, GM and CSF..." "L0" "$log_file"

input_nii=${ANAT_DSET_PREFIX}_${VIEW}.nii.gz
output_prefix=${ANAT_DSET_PREFIX}


if [ ! -f ${input_nii} ]; then
  log_info_message ".. Converting HEAD/BRIK to .nii" "L1" "$log_file"
  3dcopy ${input_prefix}+${VIEW} $input_nii >> $log_file 2>&1
fi

if [ ! -f ${output_prefix}_WM+${VIEW}.HEAD ] || \
   [ ! -f ${output_prefix}_GM+${VIEW}.HEAD ] || \
   [ ! -f ${output_prefix}_CSF+${VIEW}.HEAD ]; then

  rm -f rm_${output_prefix}_pve_?.nii.gz > /dev/null 2>&1

  # use FAST to segment the T1
  log_info_message ".. Segmentation" "L1" "$log_file"
  fast --channels=1 --type=1 --class=3 \
       --out=rm_${output_prefix} ${input_nii} >> $log_file 2>&1

  if [ $? -ne 0 ]; then
    log_error_exit "FSL's fast failed!" "$log_file"
  fi

  # copy to BRIK/HEAD
  log_info_message ".. Copy segmentation maps" "L1" "$log_file"

  # 0: CSF probability map
  3dcopy rm_${output_prefix}_pve_0.nii.gz ${output_prefix}_CSF+${VIEW} >> $log_file 2>&1 

  # 1: GM probability map
  3dcopy rm_${output_prefix}_pve_1.nii.gz ${output_prefix}_GM+${VIEW} >> $log_file 2>&1 

  # 2: WM probability map
  3dcopy rm_${output_prefix}_pve_2.nii.gz ${output_prefix}_WM+${VIEW} >> $log_file 2>&1 

else
  log_warning_message "Output files: ${output_prefix}_{WM,GM,CSF}+${VIEW} already exist!" "$log_file"
fi

# scale between 0 and 1
log_info_message "Scale segmentation potability maps between 0 and 1" "L0" "$log_file"
input_prefix=$output_prefix

for prefix in ${input_prefix}_CSF ${input_prefix}_GM ${input_prefix}_WM; do

  output_prefix=${prefix}_scale
  
  log_info_message " Scaling: ${prefix}" "L1" "$log_file"

  if [ ! -f ${output_prefix}+${VIEW}.HEAD ]; then
    min=''
    min=$(3dinfo -min ${prefix}+${VIEW} 2>/dev/null)
    if [ -z "$min" ]; then
      log_error_exit "Extracting minimum failed! " "$log_file"
    fi

    max=''
    max=$(3dinfo -max ${prefix}+${VIEW} 2>/dev/null)

    if [ -z "$max" ]; then
      log_error_exit "Extracting maximum failed! " "$log_file"
    fi

    diff=''
    diff=$(echo "scale=3; $max-($min)" | bc 2>/dev/null)

    if [ -z "$max" ]; then
      log_error_exit "Calculating max - $min failed!" "$log_file"
    fi

    3dcalc -prefix ${output_prefix} -float -a ${prefix}+${VIEW} -expr "(a-$min)/$diff" >> $log_file 2>&1

    if [ $? -ne 0 ]; then
      echo "ERROR: 3dcalc failed!"
      exit 1
    fi

  else
   log_warning_message "Output file: ${output_prefix}+${VIEW} already exists!" "$log_file"
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

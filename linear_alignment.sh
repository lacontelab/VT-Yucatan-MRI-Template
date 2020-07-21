#!/bin/bash

#############################################################################
#                                                                           #
# linear_alignment.sh                                                       #
#                                                                           #
# Perform intensity normalization and linear alignment with AFNI's          #
# 3dUnifize and 3dAllinate commands                                         #
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
TEMPLATE_DSET=$2

## flags
RM_PRE=0    # remove data before analysis
RM_POST=1   # remove temporary data (rm_*) after analysis 

## defines 
# input datasets
ANAT_DSET_PREFIX='t1'
ALIGN_PREFIX[0]='t1_ss_CSF_scale'
ALIGN_PREFIX[1]='t1_ss_WM_scale'
ALIGN_PREFIX[2]='t1_ss_GM_scale'
ALIGN_PREFIX[3]='voxel_AC'
ALIGN_PREFIX[4]='voxel_PC'
ALIGN_PREFIX[5]='voxel_HN'

# used for naming of log files, etc
BASE_DIR=$(pwd)
SCR_NAME="$(basename ${0%%.sh})"

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

if [ ! -f ${TEMPLATE_DSET}.HEAD ]; then
  echo -en  "*** ERROR ($0): Template dataset: $TEMPLATE_DSET does not exist!\n" 
  exit 1
fi

# separate path and directory name, this is used later to identify 
# if T1 as initial subject is processed. 
template_path=$(dirname $TEMPLATE_DSET)
template_dir=$(basename $template_path)

in_prefix=${ANAT_DSET_PREFIX}_ss

# check if template_path is defined
if [ ! -d "$template_path" ]; then
  echo -en  "*** ERROR ($0): What happened? Template path not defined!\n"
  exit 1
fi

# check if template_dir is defined
if [ -z "$template_dir" ]; then
  echo -en  "*** ERROR ($0): What happened? Template directory not defined!\n"
  exit 1
fi

# assign subject ID
subject_id=$(basename $SUB_DIR)
subject_id=$subject_id

# check if subject_id is defined
if [ -z "$subject_id" ]; then
  echo -en  "*** ERROR ($0): What happened? Subject ID not defined!\n"
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
  #rm -vf rm_* >> $log_file 2>&1

  echo -en "*******************************************************************\n\n" >> $log_file 2>&1 
fi

###############################################################################
### Processing of anatomical ##################################################
###############################################################################
in_prefix=${ANAT_DSET_PREFIX}_ss

# check for input
if [ ! -f ${in_prefix}+acpc.HEAD ]; then
  log_error_exit "Input file: $in_prefix does not exist!" "$log_file"
fi

# normalize signal intensities
out_prefix=${ANAT_DSET_PREFIX}_ss_un
log_info_message "Normalize intensities of: ${in_prefix}+acpc " "L0" "$log_file"
if [ ! -f ${out_prefix}+acpc.HEAD ]; then

  3dUnifize -prefix $out_prefix -input ${in_prefix}+acpc -nosquash >> $log_file 2>&1

  if [ $? -ne 0 ]; then
    log_error_exit "3dUnifize failed!" "$log_file"
  fi
else
  log_warning_message "Output file: ${out_prefix}+acpc already exists!" "$log_file"
fi

# simple code to check if current subject is "template subject"
if [ "$template_dir" != "templates" ]; then

  log_warning_message "Assuming this is the initial subject for alignment, since the template dataset is not stored in the \"templates\" directory." "$log_file"
  
  in_prefix=${ANAT_DSET_PREFIX}_ss_un
  out_prefix=${ANAT_DSET_PREFIX}_ss_un_linear_${template_dir}

  log_info_message ".. Copy:  ${in_prefix}+acpc to: ${out_prefix}+acpc" "L1" "$log_file"

  if [ ! -f ${out_prefix}+acpc.HEAD ]; then

    3dcopy ${in_prefix}+acpc ${out_prefix} >> $log_file 2>&1

    if [ $? -ne 0 ]; then
      log_error_exit "3dcopy failed!" "$log_file"
    fi

    # change to tlrc
    if [ ! -f ${out_prefix}+tlrc.HEAD ]; then
      3drefit -view tlrc ${out_prefix}+acpc >> $log_file 2>&1
    fi
  else
     log_warning_message "Output file: ${out_prefix}+acpc already exists!" "$log_file"
  fi

  if [ ! -d $SUB_DIR/../templates ]; then
    log_info_message ".. Creating directory for templates" "L1" "$log_file"
    mkdir  $SUB_DIR/../templates  >> $log_file 2>&1
  fi


  # also copy to template directory
  in_prefix=${ANAT_DSET_PREFIX}_ss_un
  out_prefix=$SUB_DIR/../templates/${template_dir}

  log_info_message ".. Copy:  ${in_prefix}+acpc to: ${out_prefix}+tlrc" "L1" "$log_file"
  if [ ! -f ${out_prefix}+acpc.HEAD ]; then
    3dcopy ${in_prefix}+acpc ${out_prefix} >> $log_file 2>&1

    if [ $? -ne 0 ]; then
      log_error_exit "3dcopy failed!" "$log_file"
    fi
  else
     log_warning_message "Output file: ${out_prefix}+acpc already exists!" "$log_file"
  fi

  # change to tlrc
  if [ ! -f ${out_prefix}+tlrc.HEAD ]; then
    3drefit -view tlrc ${out_prefix}+acpc >> $log_file 2>&1
  fi

  log_info_message "done" "L0" "$log_file"
  exit 0
fi
         
## linear alignment ############################################################
# figure template name
name=$(basename $TEMPLATE_DSET)
if [ ${name: -4} != 'tlrc' ]; then
 log_error_exit "Template dataset: $TEMPLATE_DSET be in +tlrc view" "$log_file"
fi

template_name=${name%%+tlrc}
log_info_message "Align data to template..." "L0" "$log_file"

in_prefix=${ANAT_DSET_PREFIX}_ss_un
out_prefix=${ANAT_DSET_PREFIX}_ss_un_linear_${template_name}
xform_tpl_to_t1_affine="${template_name}_2_T1_affine.1D"
log_info_message "Linear transform of: ${in_prefix}+acpc to: $TEMPLATE_DSET" "L0" "$log_file"

if [ ! -f ${out_prefix}+tlrc.HEAD ]; then
    3dAllineate \
      -twopass -cost lpa -autoweight -fineblur 3 -cmass \
      -prefix ${out_prefix} \
      -base $TEMPLATE_DSET \
      -1Dmatrix_save ${xform_tpl_to_t1_affine} \
      -input ${in_prefix}+acpc \
      -final wsinc5 >> $log_file 2>&1

  if [ $? -ne 0 ]; then
    log_error_exit "3dAllineate failed!" "$log_file"
  fi
else
   log_warning_message "Output file: ${out_prefix}+tlrc.HEAD already exists!" "$log_file"
fi

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

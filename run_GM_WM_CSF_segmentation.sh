#!/bin/bash

#############################################################################
#                                                                           #
# run_GM_WM_CSF_segmentation.sh                                             #
#                                                                           #
# Perform tissue segmentation using FSL FAST and GNU parallel for load      #
# balance.                                                                  #
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

# arguments
# output path
OUT_PATH=$1

ANAT_DSET_PREFIX=$2
VIEW=$3

# defines 
# !!! MAKE SURE THIS IS DEFINED CORRECTLY BASED ON YOUR MACHINE !!! 
MAX_LOAD='60%'  # maximum load 
MAX_CPU='20'    # maximum number of CPUs used

LIST_FILE=$(pwd)/ids_n70.txt
SCRIPT=$(pwd)/GM_WM_CSF_segmentation.sh

# if CONFIRM_JOB is set to anything but "DO_NOT_ASK", user will be prompted to 
# confirm job
CONFIRM_JOB=DO_NOT_ASK

###############################################################################
n_args=3
if [ $# -ne $n_args ]; then
  echo
  echo -en "      Usage $0 <output path> <anatomical prefix> <view>\n"
  echo -en " ***  Need $n_args input arguments $# given!\n\n"
  exit 1
fi

# check if file with dicom directories exist 
if [ ! -d "$OUT_PATH" ]; then
  echo "ERROR: Output path: $OUT_PATH does not exist!"
  exit 1
fi

# check if file with dicom directories exist 
if [ ! -f $LIST_FILE ]; then
  echo "ERROR: File: $LIST_FILE does not exist!"
  exit 1
fi

script_name="$(basename ${0%%.sh})"
joblist_file=$(pwd)/joblist_${script_name}.txt
jobdir=$(pwd)/jobs

if [ -f $joblist_file ]; then
  echo "ERROR: Job with joblist: $joblist_file already running!"
  exit 1
fi

if [ ! -d $jobdir ]; then
  mkdir $jobdir
fi

# create joblist
for id in $(cat $LIST_FILE); do
  echo  "$SCRIPT $OUT_PATH/$id $ANAT_DSET_PREFIX $VIEW > ${jobdir}/job_${script_name}_${id}.log 2>&1" >> $joblist_file
done

if [ "$CONFIRM_JOB" != "DO_NOT_ASK" ]; then
  echo About to run: 
  cat $joblist_file

  echo -en "\nAre you sure you want to continue? [Y/N]: "
  read -s -n 1 answer
  if [ "$answer" == "Y" ] || [ "$answer" == "y" ]; then
    echo -en "Yes\n\n"
  else
    echo -en "No\n\n"
    rm -f $joblist_file
    exit 0
  fi
else 
  echo Running: $0
fi

# run joblist 
parallel --jobs $MAX_CPU --load "$MAX_LOAD" --delay 4 < $joblist_file > ${jobdir}/parallel_${script_name}.log 2>&1 &

wait 
rm -f $joblist_file


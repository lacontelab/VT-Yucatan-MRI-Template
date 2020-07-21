#!/bin/bash

#############################################################################
#                                                                           #
# main.sh                                                                   #
#                                                                           #
# Create template by averaging datasets using AFNI's 3dmean command         #
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

# file with IDs
LIST_FILE=$1 
INPUT_PATH=$2
INPUT_DSET=$3
OUTPUT_PREFIX=$4

# usage
n_args=4

if [ $# -ne $n_args ]; then
  echo
  echo -en "      Usage $0 <list file> <input path> <input dset> <output prefix>\n"
  echo -en " ***  Need $n_args input arguments $# given!\n\n"
  exit 1
fi

if [ ! -f $LIST_FILE ]; then
  echo "ERROR: List file: $LIST_FILE does not exists!"
  exit 1
fi

if [ -f ${OUTPUT_PREFIX}+tlrc.HEAD ]; then
  echo "ERROR: Output dataset: ${OUTPUT_PREFIX}+tlrc already exists!"
  exit 1
fi
dsets=''
for id in $(cat $LIST_FILE); do
  if [ ! -f $INPUT_PATH/$id/${INPUT_DSET}.HEAD ]; then
    echo "ERROR ($0): Input dataset: $INPUT_PATH/$id/$INPUT_DSET does not exist!"
    exit 1
  fi
  dsets="$dsets $INPUT_PATH/$id/$INPUT_DSET"
done

3dMean -datum float -prefix ${OUTPUT_PREFIX} $dsets

if [ $? -ne 0 ]; then
  echo "ERROR: 3dMean failed!"
  exit 1
fi

echo Output: $OUTPUT_PREFIX

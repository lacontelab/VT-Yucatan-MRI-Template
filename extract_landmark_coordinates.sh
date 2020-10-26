#!/bin/bash

###############################################################################
#   
# Extract landmark coordinates before and after alignment
# 
###############################################################################

LIST_FILE=$1
DATA_PATH=$2

TEMPLATE_NAME=$3
ALIGNMENT_TYPE=$4

# landmark datasets
LMARK_PREFIX[0]=voxel_AC
LMARK_PREFIX[1]=voxel_PC
LMARK_PREFIX[2]=voxel_HN

OUTPUT_PATH=$DATA_PATH/results

# usage
n_args=4

if [ $# -lt $n_args ]; then
  echo
  echo -en "      Usage $0 <subject list> <data path> <template name> <alignment type [linear, nonlinear]>\n"
  echo -en " ***  Need $n_args input arguments $# given!\n\n"
  exit 1
fi
if [ ! -f $LIST_FILE ]; then
  echo "ERROR: File: $LIST_FILE does not exist!"
  exit 1
fi

if [ ! -d "$DATA_PATH" ]; then
  echo "ERROR: Output path: $DATA_PATH does not exist!"
  exit 1
fi

if [ ! -d "$OUTPUT_PATH" ]; then
  echo "INFO: Creating output path:  $OUTPUT_PATH"
  mkdir -p $OUTPUT_PATH
fi

if [ "$ALIGNMENT_TYPE" != 'linear' ] && [ "$ALIGNMENT_TYPE" != 'nonlinear' ]; then t
  echo "ERROR: ALIGNMENT_TYPE must be 'linear' or 'nonlinear'"
  exit 1
fi

# check if data is present before doing the hard work! 
m=0
for (( i=0; i<${#LMARK_PREFIX[@]}; i++ )); do
  echo "   Checking landmark: ${LMARK_PREFIX[$i]}"
  for id in $(cat $LIST_FILE); do
    printf "     Checking subject: $id\r"

    acpc_dset=$DATA_PATH/$id/${LMARK_PREFIX[$i]}+acpc
    acpc_file=$DATA_PATH/$id/${LMARK_PREFIX[$i]}_dump.1D
    t1_dset=$DATA_PATH/$id/t1_ss_un+acpc

    if [ ! -f ${acpc_dset}.HEAD ]; then
      echo -en "\n       Input dataset: $acpc_dset does not exist!\n"
      m=$((m+1))
    fi

    if [ ! -f ${t1_dset}.HEAD ]; then
      echo -en "\n      Input dataset: $t1_dset does not exist!\n"
      m=$((m+1))
    fi

    linear_dset=$DATA_PATH/$id/${LMARK_PREFIX[$i]}_linear_${TEMPLATE_NAME}+tlrc
    linear_xform=$DATA_PATH/$id/${TEMPLATE_NAME}_2_T1_affine.1D
    linear_file1=$DATA_PATH/$id/${LMARK_PREFIX[$i]}_linear_${TEMPLATE_NAME}_dump.1D
    linear_file2=$DATA_PATH/$id/${LMARK_PREFIX[$i]}_linear_${TEMPLATE_NAME}.1D

    if [ ! -f ${linear_dset}.HEAD ]; then
     echo -en "\n       Input dataset: $linear_dset does not exist!\n"
      m=$((m+1))
    fi

    if [ ! -f ${linear_xform} ]; then
     echo -en "\n       Linear xform: $linear_xform does not exist!\n"
      m=$((m+1))
    fi

    if [ $ALIGNMENT_TYPE == 'nonlinear' ]; then
      nonlinear_dset=$DATA_PATH/$id/${LMARK_PREFIX[$i]}_nonlinear_${TEMPLATE_NAME}+tlrc
      nonlinear_file=$DATA_PATH/$id/${LMARK_PREFIX[$i]}_nonlinear_${TEMPLATE_NAME}_dump.1D
      warp_center_file=$DATA_PATH/$id/${LMARK_PREFIX[$i]}_nonlinear_${TEMPLATE_NAME}_warp_center.1D
      
      if [ ! -f ${nonlinear_dset}.HEAD ]; then
       echo -en "\n      Input dataset: $nonlinear_dset does not exist!\n"
        m=$((m+1))
      fi
    fi
  done
  echo
done

if [ $m -ne 0 ]; then
  echo "ERROR: $m files missing. Can not continue."
  exit 1
fi

# loop over landmarks and initialize output .csv files
for (( i=0; i<${#LMARK_PREFIX[@]}; i++ )); do
  output_file=$OUTPUT_PATH/landmark_validation_${LMARK_PREFIX[$i]}_${TEMPLATE_NAME}.csv
  printf "%-10s,%-10s,%-10s,%-10s,%-10s,%-10s,%-10s,%-15s,%-15s,%-15s,%-15s,%-15s,%-15s,%-15s,%-15s,%-15s\n" \
    "SUBJECT ID" " " "ACPC" " " " " "lin" " " " " "nlin (max)" " " " " "nlin (ave)" " " " " "nlin(w. ave)" " " \
    > $output_file

  printf "%-10s,%-10s,%-10s,%-10s,%-10s,%-10s,%-10s,%-15s,%-15s,%-15s,%-15s,%-15s,%-15s,%-15s,%-15s,%-15s\n" \
    " "  "x" "y" "z" "x" "y" "z" "x" "y" "z" "x" "y" "z" "x" "y" "z" >> $output_file
done

# loop over subjects
for id in $(cat $LIST_FILE); do

  echo "################################################################################"
  echo Processing subject: $id
  echo "################################################################################"

  # loop over landmarks 
  for (( i=0; i<${#LMARK_PREFIX[@]}; i++ )); do
    echo --------------------------------------------------------------------------------
    echo Processing landmark: ${LMARK_PREFIX[$i]}
    echo --------------------------------------------------------------------------------
    output_file=$OUTPUT_PATH/landmark_validation_${LMARK_PREFIX[$i]}_${TEMPLATE_NAME}.csv

    echo "--- ${LMARK_PREFIX[$i]} --- ACPC ----------------------------------------------"
    ###########################################################################
    # extract coordinates in ACPC (starting point)
    ###########################################################################
    acpc_dset=$DATA_PATH/$id/${LMARK_PREFIX[$i]}+acpc
    acpc_file=$DATA_PATH/$id/${LMARK_PREFIX[$i]}_dump.1D
    t1_dset=$DATA_PATH/$id/t1_ss_un+acpc

    if [ ! -f ${acpc_dset}.HEAD ]; then
      echo "ERROR: Input dataset: $acpc_dset does not exist!"
      exit 1
    fi

    if [ ! -f ${t1_dset}.HEAD ]; then
      echo "ERROR: Input dataset: $t1_dset does not exist!"
      exit 1
    fi

    3dmaskdump -noijk -xyz -mask $acpc_dset $t1_dset 1> $acpc_file

    acpc_xyz=($(cat $acpc_file | cut -d ' ' -f1-3))
    echo ${acpc_xyz[@]}

    echo "--- ${LMARK_PREFIX[$i]} --- LINEAR --------------------------------------------"
    ###########################################################################
    # extract coordinates after linear alignment to template 
    ###########################################################################
    linear_dset=$DATA_PATH/$id/${LMARK_PREFIX[$i]}_linear_${TEMPLATE_NAME[$t]}+tlrc
    linear_xform=$DATA_PATH/$id/${TEMPLATE_NAME[$t]}_2_T1_affine.1D
    linear_file1=$DATA_PATH/$id/${LMARK_PREFIX[$i]}_linear_${TEMPLATE_NAME[$t]}_dump.1D
    linear_file2=$DATA_PATH/$id/${LMARK_PREFIX[$i]}_linear_${TEMPLATE_NAME[$t]}.1D

    #TODO: When a single landmark voxel is aligned, the resulting dataset has "no voxels"
    # sometimes. This might be a bug. Does not seem to be a final interpolation issue

    #if [ ! -f ${linear_dset}.HEAD ]; then
    # echo "ERROR: Input dataset: $linear_dset does not exist!"
    # exit 1
    #fi

    ## calculate location based on dataset (interpolated onto grid)
    #3dmaskdump -noijk -xyz -mask $linear_dset $linear_dset 1> $linear_file1
    #linear_xyz1=$(cat $linear_file1 | cut -d ' ' -f1-3)
    #echo $linear_xyz1

    if [ ! -f ${linear_xform} ]; then
     echo "ERROR: Linear xform: $linear_xform does not exist!"
     exit 1
    fi

    # calculate location by applying matrix (not interpolated)
    cat_matvec $linear_xform -I > $DATA_PATH/$id/T1_2_${TEMPLATE_NAME[$t]}_affine.1D
    echo ${acpc_xyz[@]} | Vecwarp -matvec $DATA_PATH/$id/T1_2_${TEMPLATE_NAME[$t]}_affine.1D > $linear_file2

    #linear_xyz=($(cat $linear_file2 | cut -d ' ' -f1-3))
    linear_xyz=($(cat $linear_file2))
    echo ${linear_xyz[@]}

    if [ "$ALIGNMENT_TYPE" == 'nonlinear' ]; then
      echo "--- ${LMARK_PREFIX[$i]} --- NON-LINEAR-----------------------------------------"
      ###########################################################################
      # extract coordinates after non-linear alignment to template 
      ###########################################################################
      
      nonlinear_dset=$DATA_PATH/$id/${LMARK_PREFIX[$i]}_nonlinear_${TEMPLATE_NAME[$t]}+tlrc
      nonlinear_file=$DATA_PATH/$id/${LMARK_PREFIX[$i]}_nonlinear_${TEMPLATE_NAME[$t]}_dump.1D
      warp_center_file=$DATA_PATH/$id/${LMARK_PREFIX[$i]}_nonlinear_${TEMPLATE_NAME[$t]}_warp_center.1D
      
      if [ ! -f ${nonlinear_dset}.HEAD ]; then
       echo "ERROR: Input dataset: $nonlinear_dset does not exist!"
       exit 1
      fi

      # Caution: This will result in a point cloud. Final coordinates needs to be 
      # determined from that    
      3dmaskdump -noijk -xyz -mask $nonlinear_dset $nonlinear_dset 1> $nonlinear_file

      # using voxel with maximum intensity, average coordinate, and average coordinate weighted by intensity
      # to determine the coordinate (warp center)
      ./calculate_nonlinear_warp_center.py $nonlinear_file > $warp_center_file

      nonlinear_xyz1=($(cat $warp_center_file | sed -n -e 1p | cut -d ' ' -f1-3))
      nonlinear_xyz2=($(cat $warp_center_file | sed -n -e 2p | cut -d ' ' -f1-3))
      nonlinear_xyz3=($(cat $warp_center_file | sed -n -e 3p | cut -d ' ' -f1-3))
      
      echo ${nonlinear_xyz1[@]}
      echo ${nonlinear_xyz2[@]}
      echo ${nonlinear_xyz3[@]}
    else
      # set non-linear coordinates to zero if non-linear alignment does not exist/not requested
      nonlinear_xyz1=(0 0 0)
      nonlinear_xyz2=(0 0 0)
      nonlinear_xyz3=(0 0 0)
    fi
      
  # write to .csv
  printf "%-10s,%-10.4f,%-10.4f,%-10.4f,%-10.4f,%-10.4f,%-10.4f,%-15.4f,%-15.4f,%-15.4f,%-15.4f,%-15.4f,%-15.4f,%-15.4f,%-15.4f,%-15.4f\n" \
      "$id" ${acpc_xyz[0]} ${acpc_xyz[1]} ${acpc_xyz[2]} ${linear_xyz[0]} ${linear_xyz[1]} ${linear_xyz[2]} ${nonlinear_xyz1[0]} ${nonlinear_xyz1[1]} ${nonlinear_xyz1[2]} ${nonlinear_xyz2[0]} ${nonlinear_xyz2[1]} ${nonlinear_xyz2[2]} ${nonlinear_xyz3[0]} ${nonlinear_xyz3[1]} ${nonlinear_xyz3[2]} \
      >> $output_file

  done # loop over landmarks
done # loop over subjects

echo 
echo --------------------------------------------------------------------------
echo Results are here: $OUTPUT_PATH
echo --------------------------------------------------------------------------
echo

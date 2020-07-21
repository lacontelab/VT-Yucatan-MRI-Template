## VT-Yucatan-MRI-Template
This repository contains the shell scripts that were used to analyze the data published by **Norris et. al (2020), MRI Brain Templates of the Male Yucatan Minipig**, 
currenlty available as pre-print on [bioRxiv](https://www.biorxiv.org/). 

## Abstract ##
The pig is growing in popularity as an experimental animal because its gyrencephalic brain is similar to humans. 
Currently, however, there is a lack of appropriate brain templates to support functional and structural neuroimaging pipelines. 
The primary contribution of this work is an average volume from an iterative, non-linear registration of 70 five to seven month old male subjects. 
In addition several aspects of this study are unique, including the comparison of linear and non-linear template generation, the characterization 
of a large and homogeneous cohort, an analysis of effective resolution after averaging, and the evaluation of potential in-template bias as well as 
a comparison with a template from another minipig species using a “left-out” validation  set. 
We found that within our highly homogeneous cohort, non-linear registration produced better templates, but only marginally so. 
Although our T1-weighted data were resolution limited, we preserved effective resolution across the multi-subject average, 
produced templates that have high gray-white matter contrast and demonstrate superior registration accuracy compared to the only known alternative minipig template

## License ##
The code is distributed under [GNU General Public License](https://fsf.org/) and the [MRI data as well as derivatives](/lacontelab/VT-Yucatan-MRI-Template/releases) under the [Creative Commons](https://creativecommons.org/licenses/by-nc-sa/3.0/us) license.

## Requirements
MRI processing is perfomed with [AFNI](https://afni.nimh.nih.gov/) and [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki). [GNU Parallel](https://www.gnu.org/software/parallel/) is used for load balance.

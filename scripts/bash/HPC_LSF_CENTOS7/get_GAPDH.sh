#! /usr/bin/env bash

#set variables
projdir="/scratch/projects/fieberlab/ANV"
project="fieberlab"
targetdir="${projdir}/AplCal3.0_STAR"
SraAccList=$1

samples=`cat "${SraAccList}"`

for samp in ${samples}
do
echo "
#! /usr/bin/env bash
#BSUB -P ${project}
#BSUB -J ${experiment}_getGAPDH
#BSUB -e ${projdir}/logs/${samp}_getGAPDH.err
#BSUB -o ${projdir}/logs/${samp}_getGAPDH.out
#BSUB -W 24:00
#BSUB -n 4
#BSUB -q general

set -ue

#load samtools
module load samtools/1.3

#go to alignment dir
cd "${targetdir}"

#Aplysia GPDH
samtools index ${samp}_host_Aligned.sortedByCoord.out.bam
samtools view -h ${samp}_host_Aligned.sortedByCoord.out.bam NW_004797540.1:713676-723204 > ${samp}_host_Aligned_GAPDH.bam

" > ${targetdir}/${samp}_get_GAPDH.job

 bsub < ${targetdir}/${samp}_get_GAPDH.job
 rm ${targetdir}/${samp}_get_GAPDH.job

 done

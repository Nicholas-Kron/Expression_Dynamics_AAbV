#! /usr/bin/env bash

#set variables
projdir="/scratch/projects/fieberlab/ANV"
project="fieberlab"
targetdir="${projdir}/AplCal3.0_STAR"
SraAccList=$1

samples=`cat "${SraAccList}"`

#LOC101852563 twitchin
target_gene="twitchin"
gene_coords="NW_004797707.1:367362-593430"

for samp in ${samples}
do
echo "
#! /usr/bin/env bash
#BSUB -P ${project}
#BSUB -J ${experiment}_get_${target_gene}
#BSUB -e ${projdir}/logs/${samp}_get_${target_gene}.err
#BSUB -o ${projdir}/logs/${samp}_get_${target_gene}.out
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
samtools view -h ${samp}_host_Aligned.sortedByCoord.out.bam ${gene_coords} > ${samp}_host_Aligned_${target_gene}.bam

" > ${targetdir}/${samp}_get_${target_gene}.job

 bsub < ${targetdir}/${samp}_get_${target_gene}.job
 rm ${targetdir}/${samp}_get_${target_gene}.job

 done


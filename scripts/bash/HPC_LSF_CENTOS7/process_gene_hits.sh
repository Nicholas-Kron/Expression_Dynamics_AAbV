#!/bin/bash

projdir="/scratch/projects/fieberlab/ANV"
project="fieberlab"
targetdir="${projdir}/AplCal3.0_STAR"

SraAccList=$1
samples=`cat ${SraAccList}`


num_samples=`wc -l $1`

#LOC101852563 twitchin
target_gene="twitchin"
gene_coords="NW_004797707.1:367362-593430"

printf "Extracting reads that mapped to ${target_gene} in ${num_samples} samples... \n"

#go to alignment dir

[[ ! -d "${targetdir}" ]] && { printf "Could not find target directory, exiting...\n" ; exit 1; }



printf "Begin processing...\n"


printf "Run\tTotal\n" > ../alignment_stats/${target_gene}_count.txt

#execute for all sampels
for samp in ${samples}
do

echo "processing ${samp}..."

ALL=`samtools view -c ${targetdir}/${samp}_host_Aligned_${target_gene}.bam`

printf "${samp}\t${ALL}\n" >> ../alignment_stats/${target_gene}_count.txt

done

printf "All done!\n"


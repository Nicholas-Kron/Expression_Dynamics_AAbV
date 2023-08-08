#!/bin/bash

SraAccList=$1
samples=`cat ${SraAccList}`
target_dir=/Volumes/LaCie\ /Kron_2020_Aplysia/AplCal3.0_STAR

num_samples=`wc -l $1`

#LOC101852563 twitchin
target_gene="twitchin"
gene_coords="NW_004797707.1:367362-593430"

printf "Extracting reads that mapped to ${target_gene} in ${num_samples} samples... \n"

#go to alignment dir

[[ ! -d "${target_dir}" ]] && { printf "Could not find target directory, exiting...\n" ; exit 1; }



printf "Begin processing...\n"


printf "Run\tTotal\n" > ../alignment_stats/${target_gene}_count.txt

#execute for all sampels
for samp in ${samples}
do

echo "processing ${samp}..."

#Aplysia GPDH
samtools index "${target_dir}"/${samp}_host_Aligned.sortedByCoord.out.bam
printf "${samp} indexed, extracting ${target_gene} reads...\n"
samtools view -h -b "${target_dir}"/${samp}_host_Aligned.sortedByCoord.out.bam "${gene_coords}" > ../aligned/${samp}_host_Aligned_${target_gene}.bam
printf "${samp} ${target_gene} reads extracted!\n"

ALL=`samtools view -c ../aligned/${samp}_host_Aligned_${target_gene}.bam`

printf "${samp}\t${ALL}\n" >> ../alignment_stats/${target_gene}_count.txt

done

printf "All done!\n"

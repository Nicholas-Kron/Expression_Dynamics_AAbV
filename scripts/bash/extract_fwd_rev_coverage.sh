#! /usr/bin/env bash

## code adapted from https://www.biostars.org/p/92935/
set -ue

targetdir="../../data/alignment_stats"

# Get the bam file from the command line

#go to alignment dir
cd ../../data/bams

samples=`basename *_Aligned.sortedByCoord.out.bam | sed 's/_Aligned.sortedByCoord.out.bam//g'`


#execute for all sampels
for samp in ${samples}
do

if [[ ! `samtools view ${samp}_Aligned.sortedByCoord.out.bam` ]]
then
  echo "${samp} file has a header problem, skipping..."
  continue
fi

echo "processing ${samp}..."

# Forward strand.
#
# 1. alignments of the second in pair if they map to the forward strand
# 2. alignments of the first in pair if they map to the reverse  strand
#
samtools view -b -f 128 -F 16 ${samp}_Aligned.sortedByCoord.out.bam > ${samp}_fwd1.bam
samtools index ${samp}_fwd1.bam

samtools view -b -f 80 ${samp}_Aligned.sortedByCoord.out.bam > ${samp}_fwd2.bam
samtools index ${samp}_fwd2.bam

#
# Combine alignments that originate on the forward strand.
#
samtools merge -f ${samp}_fwd.bam ${samp}_fwd1.bam ${samp}_fwd2.bam
samtools index ${samp}_fwd.bam

rm ${samp}_fwd1.bam
rm ${samp}_fwd2.bam

# Reverse strand
#
# 1. alignments of the second in pair if they map to the reverse strand
# 2. alignments of the first in pair if they map to the forward strand
#
samtools view -b -f 144 ${samp}_Aligned.sortedByCoord.out.bam > ${samp}_rev1.bam
samtools index ${samp}_rev1.bam

samtools view -b -f 64 -F 16 ${samp}_Aligned.sortedByCoord.out.bam > ${samp}_rev2.bam
samtools index ${samp}_rev2.bam

#
# Combine alignments that originate on the reverse strand.
#
samtools merge -f ${samp}_rev.bam ${samp}_rev1.bam ${samp}_rev2.bam
samtools index ${samp}_rev.bam

rm ${samp}_rev1.bam
rm ${samp}_rev2.bam

samtools depth -aa -do ${samp}_fwd.bam -r NC_040711.1:1-35948 > ${targetdir}/${samp}_fwd_perBase_depth.tab
samtools depth -aa -do ${samp}_rev.bam -r NC_040711.1:1-35948 > ${targetdir}/${samp}_rev_perBase_depth.tab


done

echo "all done!"

#! /usr/bin/env bash

for FILE in *_Aligned.sortedByCoord.out.bam
do
NAME=`echo $FILE | sed 's/_Aligned.sortedByCoord.out.bam//g'`
echo "Processing ${FILE} with BEDtools..."
bedtools multicov -p \
-bams ${FILE} \
-bed ../annotation_data/modified_ANV_genome.bed > ../../data/alignment_stats/${NAME}_region_hits.txt
done

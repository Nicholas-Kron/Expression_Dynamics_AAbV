#! /usr/bin/env bash

for FILE in *_Aligned.sortedByCoord.out.bam
do
NAME=`echo $FILE | sed 's/_Aligned.sortedByCoord.out.bam//g'`
echo "Processing ${FILE} with RNASeQC..."

infer_experiment.py -i ${FILE} -r ../annotation_data/BED12_modified_ANV_genome.bed  &> ../strandedness/${NAME}_strandedness.txt

done


#infer_experiment.py -i SRR6871213_flipped_Aligned.sortedByCoord.out.bam -r ../annotation_data/BED12_modified_ANV_genome.bed


#infer_experiment.py -i SRR6871213_Aligned.sortedByCoord.out.bam -r ../annotation_data/BED12_modified_ANV_genome.bed

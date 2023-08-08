#! /usr/bin/env bash

printf "Run\tTotal\tForward\tReverse\n" > ../alignment_stats/prop_fwd_rev.txt

for FILE in *_Aligned.sortedByCoord.out.bam
do
SAMPLE=`echo ${FILE} | sed 's/_Aligned.sortedByCoord.out.bam//g' `

ALL=`samtools view -c ${SAMPLE}_Aligned.sortedByCoord.out.bam`
FWD=`samtools view -c ${SAMPLE}_Aligned.sortedByCoord.out_fwd.bam`
REV=`samtools view -c ${SAMPLE}_Aligned.sortedByCoord.out_rev.bam`

printf "${SAMPLE}\t${ALL}\t${FWD}\t${REV}\n" >> ../alignment_stats/prop_fwd_rev.txt

done

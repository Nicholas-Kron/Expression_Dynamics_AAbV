#! /usr/bin/env bash

projdir="/scratch/projects/fieberlab/ANV"
project="fieberlab"
targetdir="${projdir}/alignment_stats"
SraAccList=$1


module load samtools/1.3
module load bedtools/2.17.0

[ ! -d ${targetdir} ] && mkdir ${targetdir}

samples=`cat ${SraAccList}`

for samp in ${samples}
do

#get hit count to regions of interst

samtools index ${projdir}/aligned_anv/${samp}_Aligned.sortedByCoord.out.bam \

bedtools multicov -p \
-bams ${projdir}/aligned_anv/${samp}_Aligned.sortedByCoord.out.bam \
-bed ${projdir}/genomes/modified_ANV_genome.bed > ${targetdir}/${samp}_region_hits.txt

samtools depth -aa -do ${projdir}/aligned_anv/${samp}_Aligned.sortedByCoord.out.bam -r NC_040711.1:1-35948 > ${targetdir}/${samp}_perBase_depth.tab

done

for FILE in *_Aligned.sortedByCoord.out.bam
do
NAME=`echo $FILE | sed 's/_Aligned.sortedByCoord.out.bam//g'`
echo "Processing ${FILE} with BEDtools..."
bedtools multicov -p \
-bams ${FILE} \
-bed ../annotation_data/modified_ANV_genome.bed > ../../data/alignment_stats/${NAME}_region_hits.txt
done

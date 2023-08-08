#!/usr/bin/env bash

genome="/Users/Nick_Kron/Desktop/genomes/AplCal3.0/GCF_000002075.1_AplCal3.0_genomic.fna"
index="../genomes/AplCal3_STAR_Index"
gtffile="/Users/Nick_Kron/Desktop/genomes/AplCal3.0/GCF_000002075.1_AplCal3.0_genomic.gff"
targetdir="../aligned"
SraAccList=$1

samples=`cat ${SraAccList}`


for samp in ${samples}
do

#check for required input files
  [[ ! -f ../trimmed_reads/"${samp}".mate1.repaired.fastq.gz || ! -f ../trimmed_reads/"${samp}".mate2.repaired.fastq.gz ]] && ( printf "cleaned read files for "${samp}" not found!" && exit )
#clean out any old verions
  [ -d ${targetdir}/${samp} ] && rm -r ${targetdir}/${samp}
#make new one so STAR doesn't freak out
  [ ! -d ${targetdir}/${samp} ] && mkdir ${targetdir}/${samp}

[ -f ${targetdir}/${samp}_Aligned.sortedByCoord.out.bam ] && echo "this sample has already been aligned, skipping..." && continue

printf "Aligning ${samp} to host Genome using STAR...\n"

star \
--runThreadN 8 \
--genomeDir ${index}  \
--readFilesIn ../trimmed_reads/${samp}.mate1.repaired.fastq.gz \
../trimmed_reads/${samp}.mate2.repaired.fastq.gz \
--outFileNamePrefix ${targetdir}/${samp}/${samp}_host_ \
--readFilesCommand gunzip -c \
--outSAMtype BAM SortedByCoordinate \
--outReadsUnmapped Fastx \
--chimSegmentMin 12 \
--alignIntronMax 200000 \
--alignMatesGapMax 200000 \
--alignSJDBoverhangMin 10 \
--chimJunctionOverhangMin 12 \
--twopassMode Basic \
--twopass1readsN -1 \
--outSAMstrandField intronMotif

  mv ${targetdir}/${samp}/${samp}_host_Aligned.sortedByCoord.out.bam ../AplCal3.0_STAR
  mv ${targetdir}/${samp}/${samp}_host_Unmapped.out.mate1 ../unmapped_reads
  mv ${targetdir}/${samp}/${samp}_host_Unmapped.out.mate2 ../unmapped_reads
  mv ${targetdir}/${samp}/${samp}_host_Log.final.out ../STAR_logs/


done


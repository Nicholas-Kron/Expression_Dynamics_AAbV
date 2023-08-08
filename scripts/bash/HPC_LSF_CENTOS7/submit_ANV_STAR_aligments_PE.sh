#! /usr/bin/env bash

#STAR parameters from https://github.com/jnoms/virORF_direct/blob/master/bin/bash/star.sh from Nomburg et al 2020 https://github.com/jnoms/virORF_direct/blob/master/bin/bash/star.sh

#define variables for directories and files
projdir="/scratch/projects/fieberlab/ANV"
STARdir="/nethome/n.kron/local/STAR/2.6.0a/bin/Linux_x86_64_static"
project="fieberlab"
index="${projdir}/ANV_STAR"
gtffile="${projdir}/genomes/modified_ANV_genome.gtf"
targetdir="${projdir}/aligned_anv"
SraAccList=$1

#check to make sure SRA accession file exists
[ ! -f ${SraAccList} ] && echo "ERROR! SRA file does not exist! Exiting..." && exit

[ ! -d ${projdir}/logs/STAR_logs/ ] && mkdir ${projdir}/logs/STAR_logs/

[ ! -d ${projdir}/alignment_stats ] && mkdir ${projdir}/alignment_stats


[ -d ../cleaned_reads ] && echo "../cleaned_reads dir found. Proceeding..." || (echo "Error: Directory ../cleaned_reads does not exist, did you skip a step?\nExiting..." && exit)

[ ! -d ${index} ] && echo "STAR index not found, please build index first" && exit

[ ! -d ${targetdir} ] && echo "../unmapped_reads folder not detected. Making directory..." && mkdir "${targetdir}"

samples=`cat ${SraAccList}`

for samp in ${samples}
do

#check for required input files
  [[ ! -f ${projdir}/cleaned_reads/"${samp}".mate1.repaired.fastq.gz || ! -f ${projdir}/cleaned_reads/"${samp}".mate2.repaired.fastq.gz ]] && ( printf "cleaned read files for "${samp}" not found!" && exit )
#clean out any old verions
  [ -d ${targetdir}/${samp} ] && rm -r ${targetdir}/${samp}
#make new one so STAR doesn't freak out
  [ ! -d ${targetdir}/${samp} ] && mkdir ${targetdir}/${samp}

[ -f ${targetdir}/${samp}_Aligned.sortedByCoord.out.bam ] && echo "this sample has already been aligned, skipping..." && continue

#build script
echo "making STAR script for ${samp}..."
echo "
#! /usr/bin/env bash
#BSUB -P ${project}
#BSUB -J ${samp}_STAR_ANV
#BSUB -e ${projdir}/logs/${samp}_STAR_ANV.err
#BSUB -o ${projdir}/logs/${samp}_STAR_ANV.out
#BSUB -W 12:00
#BSUB -n 16
#BSUB -q bigmem

echo \"Aligning ${samp} to ANV Genome using STAR...\"

${STARdir}/STAR \
--runThreadN 16 \
--genomeDir ${index} \
--readFilesIn ${projdir}/cleaned_reads/${samp}.mate1.repaired.fastq.gz \
${projdir}/cleaned_reads/${samp}.mate2.repaired.fastq.gz \
--outFileNamePrefix ${targetdir}/${samp}_ \
--readFilesCommand gunzip -c \
--outSAMtype BAM SortedByCoordinate \
--outBAMsortingBinsN 200 \
--limitBAMsortRAM 10000000000 \
--outFilterType BySJout \
--outFilterMultimapNmax 20 \
--alignSJoverhangMin 8 \
--outSJfilterOverhangMin 12 12 12 12 \
--outSJfilterCountUniqueMin 1 1 1 1 \
--outSJfilterCountTotalMin 1 1 1 1 \
--outSJfilterDistToOtherSJmin 0 0 0 0 \
--outFilterMismatchNmax 999 \
--outFilterMismatchNoverReadLmax 0.04\
--scoreGapNoncan -4 \
--scoreGapATAC -4 \
--chimOutType WithinBAM HardClip \
--chimScoreJunctionNonGTAG 0 \
--alignSJstitchMismatchNmax -1 -1 -1 -1 \
--alignIntronMin 20 \
--alignIntronMax 1000000 \
--alignMatesGapMax 1000000


if [ -f ${targetdir}/${samp}_Log.final.out ]
then
  echo \"alignment successful! moving necessay files...\"
  mv ${targetdir}/${samp}_Log.final.out ${projdir}/logs/STAR_logs/
	mv ${targetdir}/${samp}_Log.progress.out ${projdir}/logs/STAR_logs/
	mv ${targetdir}/${samp}_Log.out ${projdir}/logs/STAR_logs/
	mv ${targetdir}/${samp}_SJ.out.tab ${projdir}/alignment_stats
	rmdir ${targetdir}/${samp}

fi

" > ${targetdir}/${samp}/${samp}_STAR.job
#submit script
bsub < ${targetdir}/${samp}/${samp}_STAR.job
#remove script
rm ${targetdir}/${samp}/${samp}_STAR.job

done

echo "All done!"

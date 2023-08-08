#! /usr/bin/env bash
projdir="/scratch/projects/fieberlab/ANV"
project="fieberlab"
targetdir="${projdir}/raw_reads"
SraAccList=$1

[ ! -d ${targetdir} ] && mkdir ${targetdir}

samples=`cat ${SraAccList}`

for samp in ${samples}
do

[[ -f ${targetdir}/${samp}.fastq.gz || ( -f ${targetdir}/${samp}_1.fastq.gz && -f ${targetdir}/${samp}_2.fastq.gz ) ]] && echo "read files for ${samp} already in /../raw_reads, skipping..." && continue

echo "making raw read download script for ${samp}"

echo "
#! /usr/bin/env bash
#BSUB -P ${project}
#BSUB -J ${samp}_download
#BSUB -e ${projdir}/logs/${samp}_download.err
#BSUB -o ${projdir}/logs/${samp}_download.out
#BSUB -W 12:00
#BSUB -n 3
#BSUB -q general

#load java
module load sra-sdk/2.9.6

cd ${targetdir}
fasterq-dump ${samp}

[ -f ${samp}.fastq ] && (echo \"succesfully downloaded SE read file of ${samp}, compressing with gzip...\" && gzip ${samp}.fastq )
[ -f ${samp}_1.fastq ] && (echo \"succesfully downloaded ${samp} 1, compressing with gzip...\" && gzip ${samp}_1.fastq )
[ -f ${samp}_2.fastq ] && (echo \"succesfully downloaded ${samp} 2, compressing with gzip...\" && gzip ${samp}_2.fastq )

" > ${targetdir}/${samp}_download.job

bsub < ${targetdir}/${samp}_download.job
rm ${targetdir}/${samp}_download.job

done

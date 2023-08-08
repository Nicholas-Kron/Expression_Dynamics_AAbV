#! /usr/bin/env bash
projdir="/scratch/projects/fieberlab/ANV"
project="fieberlab"
targetdir="${projdir}/unmapped_reads"
SraAccList=$1

#check if unmapped_reads exists
[ -d ../cleaned_reads ] && echo "../raw_reads found. Proceeding..." || (echo "Error: Directory ../cleaned_reads does not exist, did you skip a step?\nExiting..." && exit)

#check if cleaned reads folder exists, and if not, make one

[ ! -d ../unmapped_reads ] && echo "../unmapped_reads folder not detected. Making directory..." && mkdir ../unmapped_reads

[ ! -d ./ref ] && bbmap.sh ref=../genomes/GCF_000002075.1_AplCal3.0_genomic.fna.gz -Xmx40g

samples=`cat ${SraAccList}`

for samp in ${samples}
do

  [[ ! -f ${projdir}/cleaned_reads/"${samp}".mate1.repaired.fastq.gz || ! -f ${projdir}/cleaned_reads/"${samp}".mate2.repaired.fastq.gz ]] && ( printf "cleaned read files for "${samp}" not found!" && exit )

  #clean out any old versions
  rm ../unmapped_reads/${samp}*

echo "
#! /usr/bin/env bash
#BSUB -P ${project}
#BSUB -J ${samp}_extract_unmapped
#BSUB -e ${projdir}/logs/${samp}_extract_unmapped.err
#BSUB -o ${projdir}/logs/${samp}_extract_unmapped.out
#BSUB -W 24:00
#BSUB -n 8
#BSUB -q general

#load java
module load java/1.8.0_60
export _JAVA_OPTIONS=\"-Xmx4g -Xms1g\"

echo \"Mapping ${samp} to AplCal3 Genome using BBMAP... \"
echo \"Mapping PE files... \"

bbmap.sh \
in1=${projdir}/cleaned_reads/${samp}.mate1.repaired.fastq.gz \
in2=${projdir}/cleaned_reads/${samp}.mate2.repaired.fastq.gz \
outm=${targetdir}/${samp}.PE.mapped.fastq.gz \
outu=${targetdir}/${samp}.PE.unaligned.fastq.gz \
-Xmx40g \
1>${projdir}/logs/BBDUK_logs/${samp}_extract_unmapped.out \
2>${projdir}/logs/BBDUK_logs/${samp}_extract_unmapped.err

rm ${targetdir}/${samp}.PE.mapped.fastq.gz

if [ -f ${targetdir}/${samp}.PE.unaligned.fastq.gz ]
then
  echo \"Unmapped reads extracted, splitting into mate1 and mate2 files... \"
  reformat.sh \
  in=${targetdir}/${samp}.PE.unaligned.fastq.gz \
  out1=${targetdir}/${samp}.mate1.unaligned.fastq.gz  \
  out2=${targetdir}/${samp}.mate2.unaligned.fastq.gz \
  1>${projdir}/logs/BBDUK_logs/${samp}_splitting.out \
  2>${projdir}/logs/BBDUK_logs/${samp}_splitting.err
fi

if [ -f ${projdir}/cleaned_reads/${samp}.singletons.repaired.fastq.gz ]
then
  echo \"Mapping singletons files...) \"
  bbmap.sh \
  in=${projdir}/cleaned_reads/${samp}.singletons.repaired.fastq.gz \
  outu=${targetdir}/${samp}.singletons.unaligned.fastq.gz \
  -Xmx40g \
  1>${projdir}/logs/BBDUK_logs/${samp}_extract_unmapped_singletons.out \
  2>${projdir}/logs/BBDUK_logs/${samp}_extract_unmapped_singletons.err
fi

 " > ${targetdir}/${samp}_unmapped.job

 bsub < ${targetdir}/${samp}_unmapped.job
 rm ${targetdir}/${samp}_unmapped.job

done

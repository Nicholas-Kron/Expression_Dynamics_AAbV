#! /usr/bin/env bash
projdir="/scratch/projects/fieberlab/ANV"
project="fieberlab"
targetdir="${projdir}/cleaned_reads"
SraAccList=$1
BBDUK="/nethome/n.kron/local/bbtools/37.90"

[ ! -d ../logs ] && mkdir ../logs
[ ! -d ../logs/BBDUK_logs ] && mkdir ../logs/BBDUK_logs
[ ! -d ../logs/sickle_logs ] && mkdir ../logs/sickle_logs

#check if unmapped_reads exists
[ -d ../raw_reads ] && echo "../raw_reads found. Proceeding..." || (echo "Error: Directory ../raw_reads does not exist. Exiting..." && exit)

#check if cleaned reads folder exists, and if not, make one

[ ! -d ../cleaned_reads ] && echo "../cleaned_reads folder not detected. Making directory..." && mkdir ../cleaned_reads


samples=`cat ${SraAccList}`

for samp in ${samples}
do
  [ -f ${projdir}/raw_reads/"${samp}".fastq ] && ( printf "compressing uncompressed file ${samp}.fastq" && gzip ${projdir}/raw_reads/${samp}.fastq )
  [[ ! -f ${projdir}/raw_reads/"${samp}".fastq.gz ]] && (printf "Raw read file for "${samp}" not found!" && exit )

  #clean out any old versions
  rm ../cleaned_reads/${samp}*

echo "
#! /usr/bin/env bash
#BSUB -P ${project}
#BSUB -J ${samp}_process
#BSUB -e ${projdir}/logs/${samp}_process.err
#BSUB -o ${projdir}/logs/${samp}_process.out
#BSUB -W 4:00
#BSUB -n 1
#BSUB -q general


#load java
module load java/1.8.0_60
export _JAVA_OPTIONS=\"-Xmx4g -Xms1g\"

  echo \"trimming reads with BBDUK...\"

  ##just in case so as not to stop BBDUK from running
  [ -f ${projdir}/logs/BBDUK_logs/${samp}_stats.txt ] && rm ${projdir}/logs/BBDUK_logs/${samp}_stats.txt

  bbduk.sh \
  in=${projdir}/raw_reads/${samp}.fastq.gz \
  out=${targetdir}/${samp}.adaptor_trimmed.fastq.gz \
  stats=${projdir}/logs/BBDUK_logs/${samp}_stats.txt \
  ref='${BBDUK}'/resources/adapters.fa \
  ktrim=r \
  k=23 \
  mink=8 \
  hdist=1 \
  tpe \
  tbo \
  qtrim=lr \
  trimq=10 \
  minlen=50 \
  maq=10 \
  1>${projdir}/logs/BBDUK_logs/${samp}_bbduk.out \
  2>${projdir}/logs/BBDUK_logs/${samp}_bbduk.err

  [[ ! -f ${targetdir}/${samp}.adaptor_trimmed.fastq.gz ]] \
  && ( echo \"something went wrong, trimmed read file not found. Exiting...\" && exit )

  echo \"BBDUK trimming done!\"
  echo \"quality trimming SE reads with sickle...\"

  sickle se \
  -f ${targetdir}/${samp}.adaptor_trimmed.fastq.gz \
  -t sanger \
  -o ${targetdir}/${samp}.cleaned.fastq.gz \
  1>${projdir}/logs/sickle_logs/${samp}_se_sickle.out \
  2>${projdir}/logs/sickle_logs/${samp}_se_sickle.err

  [[ ! -f ${targetdir}/${samp}.cleaned.fastq.gz ]] && ( echo \"something went wrong, cleaned read file not found. Exiting...\" && exit )
  echo \"SE reads quality trimmed!\"
  echo \"reads quality trimmed, removing BBBDUK files...\"

  rm ${targetdir}/${samp}.adaptor_trimmed.fastq.gz

  echo \"BBDUK files reads removed!\"

  [[ ! -f ${targetdir}/${samp}.repaired.fastq.gz ]] \
  && ( echo \"something went wrong, repaired read file not found. Exiting...\" && exit )

  echo \"reads repaired!\"

  echo \"removing intermediate cleaned read files...\"
  rm ${targetdir}/${samp}.cleaned.fastq.gz 

  echo \"all done!\"

 " > ${targetdir}/${samp}_clean.job

 bsub < ${targetdir}/${samp}_clean.job
 rm ${targetdir}/${samp}_clean.job

done

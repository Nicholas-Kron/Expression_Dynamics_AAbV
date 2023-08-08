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
  [ -f ${projdir}/raw_reads/"${samp}"_1.fastq ] && ( printf "compressing uncompressed file ${samp}_1.fastq" && gzip ${projdir}/raw_reads/${samp}_1.fastq )
  [ -f ${projdir}/raw_reads/"${samp}"_2.fastq ] && ( printf "compressing uncompressed file ${samp}_2.fastq" && gzip ${projdir}/raw_reads/${samp}_2.fastq )
  [[ ! -f ${projdir}/raw_reads/"${samp}"_1.fastq.gz || ! -f ${projdir}/raw_reads/"${samp}"_2.fastq.gz ]] && (printf "Raw read files for "${samp}" not found!" && exit )

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
  in1=${projdir}/raw_reads/${samp}_1.fastq.gz \
  in2=${projdir}/raw_reads/${samp}_2.fastq.gz \
  out1=${targetdir}/${samp}.mate1.adaptor_trimmed.fastq.gz \
  out2=${targetdir}/${samp}.mate2.adaptor_trimmed.fastq.gz \
  outs=${targetdir}/${samp}.singletons.adaptor_trimmed.fastq.gz \
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

  [[ ! -f ${targetdir}/${samp}.mate1.adaptor_trimmed.fastq.gz ||  ! -f ${targetdir}/${samp}.mate2.adaptor_trimmed.fastq.gz || ! -f ${targetdir}/${samp}.singletons.adaptor_trimmed.fastq.gz ]] \
  && ( echo \"something went wrong, trimmed read files not found. Exiting...\" && exit )

  echo \"BBDUK trimming done!\"
  echo \"quality trimming PE reads with sickle...\"

  sickle pe -g \
  -f ${targetdir}/${samp}.mate1.adaptor_trimmed.fastq.gz \
  -r ${targetdir}/${samp}.mate2.adaptor_trimmed.fastq.gz \
  -t sanger \
  -o ${targetdir}/${samp}.mate1.cleaned.fastq.gz \
  -p ${targetdir}/${samp}.mate2.cleaned.fastq.gz \
  -s ${targetdir}/${samp}.singletonS.cleaned.fastq.gz \
  1>${projdir}/logs/sickle_logs/${samp}_pe_sickle.out \
  2>${projdir}/logs/sickle_logs/${samp}_pe_sickle.err

  [[ ! -f ${targetdir}/${samp}.mate1.cleaned.fastq.gz ||  ! -f ${targetdir}/${samp}.mate2.cleaned.fastq.gz ]] \
  && ( echo \"something went wrong, cleaned read files not found. Exiting...\" && exit )

  echo \"PE reads quality trimmed!\"
  echo \"quality trimming singletons with sickle...\"

  sickle se \
  -f ${targetdir}/${samp}.singletons.adaptor_trimmed.fastq.gz \
  -t sanger \
  -o ${targetdir}/${samp}.singletonB.cleaned.fastq.gz \
  1>${projdir}/logs/sickle_logs/${samp}_se_sickle.out \
  2>${projdir}/logs/sickle_logs/${samp}_se_sickle.err

  [[ ! -f ${targetdir}/${samp}.singletonB.cleaned.fastq.gz ]] && ( echo \"something went wrong, cleaned read file not found. Exiting...\" && exit )
  echo \"Singleton reads quality trimmed!\"
  echo \"reads quality trimmed, removing BBBDUK files...\"

  rm ${targetdir}/${samp}.mate1.adaptor_trimmed.fastq.gz \
  ${targetdir}/${samp}.mate2.adaptor_trimmed.fastq.gz \
  ${targetdir}/${samp}.singletons.adaptor_trimmed.fastq.gz

  echo \"BBDUK files reads removed!\"

  echo \"repairing reads with repair...\"

  repair.sh \
  in1=${targetdir}/${samp}.mate1.cleaned.fastq.gz \
  in2=${targetdir}/${samp}.mate2.cleaned.fastq.gz \
  out1=${targetdir}/${samp}.mate1.repaired.fastq.gz \
  out2=${targetdir}/${samp}.mate2.repaired.fastq.gz \
  outs=${targetdir}/${samp}.singletonR.cleaned.fastq.gz \
  repair \
  1>${projdir}/logs/BBDUK_logs/${samp}_repair.out \
  2>${projdir}/logs/BBDUK_logs/${samp}_repair.err

  [[ ! -f ${targetdir}/${samp}.mate1.repaired.fastq.gz ||  ! -f ${targetdir}/${samp}.mate2.repaired.fastq.gz || -f ${targetdir}/${samp}.singletonR.cleaned.fastq.gz ]] \
  && ( echo \"something went wrong, repaired read files not found. Exiting...\" && exit )

  echo \"reads repaired!\"
  echo \"combining singletons...\"

  cat ${targetdir}/${samp}.singletonS.cleaned.fastq.gz \
  ${targetdir}/${samp}.singletonB.cleaned.fastq.gz \
  ${targetdir}/${samp}.singletonR.cleaned.fastq.gz > ${projdir}/cleaned_reads/${samp}.singletons.repaired.fastq.gz

  echo \"removing intermediate cleaned read files...\"
  rm ${targetdir}/${samp}.mate1.cleaned.fastq.gz \
  ${targetdir}/${samp}.mate2.cleaned.fastq.gz

  echo \"removing intermediate singleton files...\"
  rm ${targetdir}/${samp}.singletonS.cleaned.fastq.gz \
  ${targetdir}/${samp}.singletonB.cleaned.fastq.gz \
  ${targetdir}/${samp}.singletonR.cleaned.fastq.gz

  echo \"all done!\"

 " > ${targetdir}/${samp}_clean.job

 bsub < ${targetdir}/${samp}_clean.job
 rm ${targetdir}/${samp}_clean.job

done

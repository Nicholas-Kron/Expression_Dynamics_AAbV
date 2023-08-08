#! /usr/bin/env bash

SraAccList=$1

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
  [ -f ../raw_reads/"${samp}".fastq ] && ( printf "compressing uncompressed file ${samp}.fastq" && gzip ../raw_reads/${samp}.fastq )
  [[ ! -f ../raw_reads/"${samp}".fastq.gz ]] && (printf "Raw read file for "${samp}" not found!" && exit )

  #clean out any old versions
  rm ../cleaned_reads/${samp}*

echo "trimming reads with BBDUK..."

  ##just in case so as not to stop BBDUK from running
  [ -f ../logs/BBDUK_logs/${samp}_stats.txt ] && rm ../logs/BBDUK_logs/${samp}_stats.txt

  /Users/Nick_Kron/Programs/bbmap/bbduk.sh \
  in=../raw_reads/${samp}.fastq.gz \
  out=../trimmed_reads/${samp}.adaptor_trimmed.fastq.gz \
  stats=../logs/BBDUK_logs/${samp}_stats.txt \
  ref=/Users/Nick_Kron/Programs/bbmap/resources/adapters.fa \
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
  qin=33 \
  1>../logs/BBDUK_logs/${samp}_bbduk.out \
  2>../logs/BBDUK_logs/${samp}_bbduk.err

  [[ ! -f ../trimmed_reads/${samp}.adaptor_trimmed.fastq.gz ]] \
  && ( echo "something went wrong, trimmed read file not found. Exiting..." && exit )

  echo "BBDUK trimming done!"
  echo "quality trimming SE reads with sickle..."

  sickle se \
  -f ../trimmed_reads/${samp}.adaptor_trimmed.fastq.gz \
  -t sanger \
  -o ../trimmed_reads/${samp}.cleaned.fastq.gz \
  1>../logs/sickle_logs/${samp}_se_sickle.out \
  2>../logs/sickle_logs/${samp}_se_sickle.err

  [[ ! -f ../trimmed_reads/${samp}.cleaned.fastq.gz ]] && ( echo "something went wrong, cleaned read file not found. Exiting..." && exit )
  echo "SE reads quality trimmed!"
  echo "reads quality trimmed, removing BBBDUK files..."

#  rm ../trimmed_reads/${samp}.adaptor_trimmed.fastq.gz

  echo "BBDUK files reads removed!"

  [[ ! -f ../trimmed_reads/${samp}.repaired.fastq.gz ]] \
  && ( echo "something went wrong, repaired read file not found. Exiting..." && exit )

  echo "reads repaired!"

  echo "removing intermediate cleaned read files..."
  mv ../trimmed_reads/${samp}.cleaned.fastq.gz ../trimmed_reads/${samp}.repaired.fastq.gz

  echo "all done!"


done

#! /usr/bin/env bash

projdir="/scratch/projects/fieberlab/ANV"
STARdir="/nethome/n.kron/local/STAR/2.6.0a/bin/Linux_x86_64_static"
project="fieberlab"
genome="${projdir}/genomes/modified_ANV_genome.fasta"
index="${projdir}/ANV_STAR"
gtffile="${projdir}/genomes/modified_ANV_genome.gtf"

if [ -d ${index} ]
  then
		rm -r ${index}
fi

# for small genomes, genomeSAindexNbases = min(14, log2(GenomeLength)/2 - 1)
#ANV genome is 35906 BP + 42 extra leader from Ben Neuman
#log2(35948)/2 -1 = 15.1/2 -1 = 6.6 ~= 7
#assume reads are 100bp PE for sjdbOverhang

if [ ! -d ${index} ]
  then
    mkdir ${index}
    bsub -P ${project} -q bigmem \
    -n 16 \
    -R "span[ptile=8]" \
    -e ${projdir}/build_star.err \
    -o ${projdir}/build_star.err \
    ${STARdir}/STAR \
      --runThreadN 16 \
      --runMode genomeGenerate \
      --genomeDir ${index} \
      --genomeFastaFiles ${genome} \
      --sjdbGTFfile ${gtffile} \
      --sjdbOverhang 99 \
      --genomeSAindexNbases 7 \
      --sjdbGTFfeatureExon CDS
fi

#--sjdbGTFtagExonParentTranscript Parent\
#--sjdbGTFfeatureExon CDS \
#--sjdbGTFtagExonParentTranscript gene_id \

#! /usr/bin/env bash

printf "Run\tTotal\tForward\tReverse\tTotal_splice\tForward_splice\tReverse_splice\n" > ../alignment_stats/splices_fwd_rev.txt

for SAMPLE in *_Aligned.sortedByCoord.out.bam
do

echo "processing ${SAMPLE}..."

ALL=$(samtools view -h ${SAMPLE} |  samtools view -c -F 260 - )
FWD=$(samtools view -h ${SAMPLE%.bam}_fwd.bam  | samtools view -c  -F 260 - )
REV=$(samtools view -h ${SAMPLE%.bam}_rev.bam | samtools view -c -F 260 - )

ALL_splice=$(samtools view -h ${SAMPLE} | awk -v OFS="\t" '$0 ~ /^@/{print $0;next;} $6 ~ /N/' | samtools view -c -F 260 - )
FWD_splice=$(samtools view -h ${SAMPLE%.bam}_fwd.bam | awk -v OFS="\t" '$0 ~ /^@/{print $0;next;} $6 ~ /N/' | samtools view -c  -F 260 - )
REV_splice=$(samtools view -h ${SAMPLE%.bam}_rev.bam | awk -v OFS="\t" '$0 ~ /^@/{print $0;next;} $6 ~ /N/' | samtools view -c -F 260 - )

printf "${SAMPLE%_Aligned.sortedByCoord.out.bam}\t${ALL}\t${FWD}\t${REV}\t${ALL_splice}\t${FWD_splice}\t${REV_splice}\n" >> ../alignment_stats/splices_fwd_rev.txt

done

#!/usr/bin/bash

cd ../logs/STAR_logs

ls *_Log.final.out > fileList.txt


awk -F"|" 'NR == 5 || NR == 6 || NR == 9 || NR ==24 || NR == 26 {print $1}' < `head -n1 fileList.txt` > base.txt

for i in `cat fileList.txt`
do
	name=`echo $i | sed 's/\(SRR[0-9][0-9]\)_Log.final.out/\1/g'`
	echo ${name} > ${name}_temp.txt
	awk -F"|" 'NR == 6 || NR == 9 || NR ==24 || NR == 26 {print $2}' < $i >> ${name}_temp.txt
done

paste base.txt *_temp.txt | tr -s "\t\t" "\t" > STAR_count_meta.txt

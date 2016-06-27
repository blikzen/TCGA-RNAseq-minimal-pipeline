#!/bin/bash
sudo sh -c "echo 'kernel.shmmax = 31000000000' >> /etc/sysctl.conf";
sudo sh -c "echo 'kernel.shmall = 31000000000' >> /etc/sysctl.conf";
sudo /sbin/sysctl -p;
export threads=$(grep -c ^processor /proc/cpuinfo);
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/ubuntu/bamtools/lib;
n=0;
while read -r line; do
 files[$(echo $n)]=$line;
 echo ${files[$n]};
 let 'n++';
done < 'manifest.txt';
total=${#files[@]};
for (( c=0; c<$total; c+=$threads )); do
 for (( n=0; n<$threads; n++ )); do
  k=$((n + c));
  if [ "$k" -lt "$total" ]; then
   gdc-client download -t ~/token.txt --no-segment-md5sums --no-file-md5sum ${files[$k]};
  fi;
 done
 find . -name "*.bam" | xargs -n 1 -P $threads -iFILES sh -c 'picard-tools SamToFastq I=FILES F=FILES.1.fq F2=FILES.2.fq'
 for f in $(find . -name "*.1.fq"); do
  replace=$(echo $f | sed 's/1\.fq/2\.fq/g');
  STAR --runMode alignReads --outFileNamePrefix "$line". --runThreadN 32 --genomeDir /mnt/ --genomeLoad LoadAndKeep --readFilesIn "$f" "$replace" --outSAMtype BAM Unsorted --outFilterType BySJout --outFilterMultimapNmax 20  --alignSJoverhangMin 8 --alignSJDBoverhangMin 1 --outFilterMismatchNmax 999 --outFilterMismatchNoverLmax 0.04 --alignIntronMin 20 --alignIntronMax 1000000  --alignMatesGapMax 1000000;
 done;
 STAR --genomeLoad Remove --genomeDir /mnt/
 find . -name "*.Aligned.out.bam" | xargs -n 1 -P $threads -iFILES sh -c 'samtools sort FILES FILES.sort'
 todo=$(find . -name "*sort.bam");
 fcs $threads /mnt/genes.gtf $todo > count_index_"$c".feature.txt
 fci $threads /mnt/ident-intergenic.gtf $todo > count_index_"$c".intergenic.txt
 rm -rf */
done
exit 0

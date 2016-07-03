#!/bin/bash
sudo sh -c "echo 'kernel.shmmax = 31000000000' >> /etc/sysctl.conf";
sudo sh -c "echo 'kernel.shmall = 31000000000' >> /etc/sysctl.conf";
sudo /sbin/sysctl -p;
export threads=$(grep -c ^processor /proc/cpuinfo);
export threadstwo=$(($threads*2));
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/ubuntu/bamtools/lib;
export http_proxy=http://cloud-proxy:3128;
export https_proxy=http://cloud-proxy:3128;
split -l "$threadstwo" manifest.txt xxx;
for f in $(ls xxx*); do
 echo -ne "id\tfilename\tmd5\tsize\tstate\n" > "yyy.$f.manifest";
 cat "$f" >> "yyy.$f.manifest";
done
for f in $(ls *.manifest); do
 gdc-client download -t ~/token.txt --no-segment-md5sums --no-file-md5sum -m "$f";
 find . -name "*.bam" | xargs -n 1 -P "$threadstwo" -iFILES sh -c 'fasty -o FILES#.fq FILES; rm -rf FILES;';
 for z in $(find . -name "*_1.fq"); do
  replace=$(echo "$z" | sed 's/1\.fq/2\.fq/g');
  STAR --runMode alignReads --outFileNamePrefix "$z". --runThreadN "$threadstwo" --genomeDir /mnt/ --genomeLoad LoadAndKeep --readFilesIn "$z" "$replace" --outSAMtype BAM Unsorted --outFilterType BySJout --outFilterMultimapNmax 20  --alignSJoverhangMin 8 --alignSJDBoverhangMin 1 --outFilterMismatchNmax 999 --outFilterMismatchNoverLmax 0.04 --alignIntronMin 20 --alignIntronMax 1000000  --alignMatesGapMax 1000000;
  rm -rf "$z" "$replace";
 done;
 STAR --genomeLoad Remove --outFileNamePrefix genome.remove. --genomeDir /mnt;
 find . -name "*.Aligned.out.bam" | xargs -n 1 -P "$threadstwo -iFILES sh -c 'samtools sort FILES FILES.sort; rm -rf FILES;';
 find . -name "*.sort.bam" | xargs -n 1 -P 4 -iFILES sh -c 'fcs 1 /mnt/genes.gtf FILES > FILES.count.feature.txt; fci 1 /mnt/ident-intergenic.gtf FILES > FILES.count.intergenic.txt; mv FILES.count.intergenic.txt .; mv FILES.count.feature.txt .;'
 rm -rf */;
done
exit 0

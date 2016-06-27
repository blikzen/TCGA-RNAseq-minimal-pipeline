# TCGA-RNAseq-minimal-pipeline

Analysis pipeline for RNAseq using STAR aligner and minimal scratch space.

Given line delimited manifest of UIIDs, bins by number of available processors and iteratively processes bins. Downloads bams from GDC, generates paired fastq, realigns to GRCh38.84, sorts by coordinates, then counts gene and intergenic features. Scripting is parallelized, efficiently uses system resources, and significantly reduces scratch space needed for processing at scale by progressively removing raw and intermediate analysis files. Can process 1000+ RNAseq libraries in less than a week with 16 cores, 32Gb of memory, and less than 500gb of scratch.

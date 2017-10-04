#!/bin/sh

# Homework 2 assignment
# Bianca Mocanu

#==============================================================================================
# Usage:
# 1. Copy files to be analyzed to ~/data/
# 2. replace <username> with your BBC account username in this script
# 3. Run the script by typing "bash <script path>"
 
#==============================================================================================
# Requirements:

# 1.fastq files in the /home/<username>/data folder
# 2.indexed genome or genome file to be indexed with "bowtie-build <infile> <outfile_handle>"
# 3.fastqc module (check for latest version: fastqc/0.11.5/, retrieved on Sep. 28, 2017)
# 4.fastx_tools (check for availability on BBC in /share/apps/ - add to $PATH if needed!
# 5.bowtie2 (check for latest version: bowtie2/2.3.1/, retrieved on Sep. 28, 2017)

#===============================================================================================
# Required modules load here:

module load bowtie2/2.3.1/
module load fastqc/0.11.5/

#===============================================================================================
# Global variables

inPATH="/home/bim16102/data/"
dm3_genome="/tempdata3/MCB5430/genomes/dm3/dm3_Bowtie_Index/dm3"
outPATH="/home/bim16102/data/processed_data/"
fastqfiles=$(find ${inPATH} -maxdepth 1 -type f)

#===============================================================================================

if [ -s $outPATH ]
	then
		cd ${outPATH}
		mkdir ${outPATH}logfiles
		touch ${outPATH}logfiles/log.txt
 		echo "$outPATH directory already exists" | tee -a ${outPATH}logfiles/log.txt

	else
		mkdir ${outPATH}
		cd ${outPATH}
		mkdir ${outPATH}logfiles
		touch ${outPATH}logfiles/log.txt
		echo "New directory created: ${outPATH}" | tee -a ${outPATH}logfiles/log.txt
fi


echo -e "Files to be proceesed: $fastqfiles" | tee -a ${outPATH}logfiles/log.txt

for file in $fastqfiles
	do	
		folder=`echo $(basename $file) | cut -d "." -f 1`  #creates a base name for the folders for each fastq file that is analyzed and a base for the newly generated files
		
		mkdir ${folder}  #folder for original data
		cd $folder
		echo -e "Starting analysis on $(basename $file) ..." | tee -a ${outPATH}logfiles/log.txt 
		echo "Running fastqc on $(basename $file)" | tee -a ${outPATH}logfiles/log.txt
		fastqc $file -o ${outPATH}${folder}  2>&1 | tee -a ${outPATH}logfiles/log.txt
		echo "Aligning original $(basename $file) to D.melanogaster dm3 genome..." | tee -a ${outPATH}logfiles/log.txt
		bowtie -v2 -m1 -q $dm3_genome $file ${folder}.sam 2>&1 | tee -a ${outPATH}logfiles/log.txt
		cd ..
		
		echo "Starting adapter clipping..." | tee -a ${outPATH}logfiles/log.txt
		mkdir ${folder}_fastxclipped #folder for adaptor-clipped data
		cd ${folder}_fastxclipped
		fastx_clipper -Q 33 -a TGCTTGGACTACATATGGTTGAGGGTTGTATGGAATTCTCGGGTGCCAAGG -i $file -o ./${folder}_clipped.fastq 2>&1 | tee -a ${outPATH}logfiles/log.txt
		echo "Generating QC reports on the clipped data..." | tee -a ${outPATH}logfiles/log.txt
		fastqc ${folder}_clipped.fastq -o ${outPATH}${folder}_fastxclipped 2>&1 | tee -a ${outPATH}logfiles/log.txt

		echo "Aligning adapter clipped fastq to D.melanogaster dm3 genome..." | tee -a ${outPATH}logfiles/log.txt
		bowtie -v2 -m1 -q $dm3_genome ${folder}_clipped.fastq ${folder}_clipped.sam 2>&1 | tee -a ${outPATH}logfiles/log.txt
		cd ..

		echo "Starting quality trimming..." | tee -a ${outPATH}logfiles/log.txt
		mkdir ${folder}_Qtrimmed #folder for quality-trimmed data
		cd ${folder}_Qtrimmed
		fastq_quality_trimmer -Q33 -t 30 -l 20 -i $file -o ./${folder}_Qtrimmed.fastq 2>&1 | tee -a ${outPATH}logfiles/log.txt
		echo "Generating QC reports on the quality trimmed data..." | tee -a ${outPATH}logfiles/log.txt
		fastqc ${folder}_Qtrimmed.fastq -o ${outPATH}${folder}_Qtrimmed 2>&1 | tee -a ${outPATH}logfiles/log.txt
		echo "Aligning quality trimmed file to D.melanogaster dm3 genome..." | tee -a ${outPATH}logfiles/log.txt
		bowtie -v2 -m1 -q $dm3_genome ${folder}_Qtrimmed.fastq ${folder}_Qtrimmed.sam 2>&1 | tee -a ${outPATH}logfiles/log.txt
		cd ..
		echo "Analysis complete for $(basename $file)!" | tee -a ${outPATH}logfiles/log.txt
	done	

#===============================================================================================
# Unloading of required modules:

module unload bowtie2/2.3.1/
module unload fastqc/0.11.5/

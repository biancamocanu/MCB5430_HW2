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
 		echo "$outPATH directory already exists"
		cd ${outPATH}
	else
		mkdir ${outPATH}
		echo "New directory created: ${outPATH}"
		cd ${outPATH}
fi

echo -e "Files to be proceesed: $fastqfiles"

for file in $fastqfiles
	do	
		folder=`echo $(basename $file) | cut -d "." -f 1`  #creates a base name for the folders for each fastq file that is analyzed and a base for the newly generated files
		
		mkdir ${folder}  #folder for original data
		cd $folder
		echo -e "Starting analysis on $(basename $file) ..."
		echo "Running fastqc on $(basename $file)"
		fastqc $file -o ${outPATH}${folder}
		echo "Aligning original $(basename $file) to D.melanogaster dm3 genome..."
		bowtie -v2 -m1 -q $dm3_genome $file ${folder}.sam 		
		cd ..
		
		mkdir ${folder}_fastxclipped #folder for adaptor-clipped data
		cd ${folder}_fastxclipped
		fastx_clipper -Q 33 -a TGCTTGGACTACATATGGTTGAGGGTTGTATGGAATTCTCGGGTGCCAAGG -i $file -o ./${folder}_clipped.fastq
		fastqc ${folder}_clipped.fastq -o ${outPATH}${folder}_fastxclipped 
		echo "Aligning adapter clipped fastq to D.melanogaster dm3 genome..."
		bowtie -v2 -m1 -q $dm3_genome ${folder}_clipped.fastq ${folder}_clipped.sam
		cd ..


		mkdir ${folder}_Qtrimmed #folder for quality-trimmed data
		cd ${folder}_Qtrimmed
		fastq_quality_trimmer -Q33 -t 30 -l 20 -i $file -o ./${folder}_Qtrimmed.fastq
		fastqc ${folder}_Qtrimmed.fastq -o ${outPATH}${folder}_Qtrimmed
		echo "Aligning quality trimmed file to D.melanogaster dm3 genome..."
		bowtie -v2 -m1 -q $dm3_genome ${folder}_Qtrimmed.fastq ${folder}_Qtrimmed.sam
		cd ..
	done	

#===============================================================================================
# Unloading of required modules:

module unload bowtie2/2.3.1/
module unload fastqc/0.11.5/

#!/bin/bash

################################
VCFGZ=$1 ; POP=$(basename $1 .vcf.gz)
CHROMLIST="$(cat $2)" # file with chr name new on each line
MAF=$3
BATCHSIZE=$4 #5000
OVERLAP=$5 #500
PHASED=$6 # phased or unphased
################################

if [[ $# -ne 6 ]]
then
    echo "USAGE: $0 VCFGZ POP CHROMLIST MAF BATCHSIZE OVERLAP PHASED"
    echo "Expecting the following values on the command line, in that order"
    echo "name of the vcf (compressed with bgzip and indexed)"
    echo "name of the population"
    echo "list of all wanted chromosomes"
    echo "example ./02-scripts/00.extract_data_bcftools.sh phased.vcf.gz population1 list_chromosome.txt"
    exit
fi

if [[ -z "$VCFGZ" ]]
then
    echo "STOP : VCF FILE required"
    exit
fi

if [[ -z "$CHROMLIST" ]]
then
    echo -e "STOP : LIST OF CHROMOSOMES in file required\nName of each chr on new line"
    exit
fi

if [[ -z "$MAF" ]]
then 
	echo "STOP : MAF number needed (float)"
	exit
fi

if [[ -z "$BATCHSIZE" ]]
then 
	echo "STOP: BATCH SIZE needed (for example: 5000)"
	exit
fi

if [[ -z "$OVERLAP" ]]
then
	echo "STOP: BATCH OVERLAP needed (for example 500)"
	exit
fi

if [[ -z "$PHASED" ]] && [[ "${PHASED}" = "phased" || "${PHASED}" == "unphased" ]]
then 
	echo "STOP: SPECIFY PHASED/UNPHASED MODE with \"phased\" or \"unphased\""
	exit
fi

#############################################################################################

# Indexing VCFGZ
echo 'MAKIN INDEX'
tabix -f -C $VCFGZ

echo 'START EXTRACTING SUBSETS OF CHROMOSOMES AND SPLIT IT ON BATCHES'

for chr in $CHROMLIST 
do	
	echo ${chr}

	PopChrDir="${POP}/chromo.${chr}"; mkdir -p $PopChrDir
	PopChrLDhatDir="${PopChrDir}/LDhat_maf"; mkdir -p $PopChrLDhatDir

	vcfchr="${PopChrDir}/batch.${POP}.${chr}.maf${MAF}.vcf.gz"
	poslist="${PopChrDir}/list_position"

	bcftools view -r $chr ${VCFGZ} --min-af ${MAF} --max-alleles 2 --exclude-types indels |\
	bgzip -c > ${vcfchr}
	tabix -f -C -p  ${vcfchr}

	# Split on batches
	
	## Get list of possiton
	zcat "${vcfchr}" | grep -v "#" | cut -f 1-2 > poslist
	
	## Run splitting script
	python3 `which LDhat.split_dataset.py` \
  		poslist \
	        ${BATCHSIZE} \
	        ${OVERLAP} \
		${PopChrDir}

	#Construct input files for unphased or phased vcf input file
	for i in `seq $(ls $PopChrDir | grep dataset_ | wc -l)`
	do
		mkdir -p ${PopChrLDhatDir}/batch_${i}
	
        	if [[ "${PHASED}" == "unphased" ]]
	        then
        	        vcftools --gzvcf "${vcfchr}" --positions ${PopChrDir}/dataset_${i} --ldhat-geno --chr ${chr} --out ${PopChrLDhatDir}/batch_${i}/${i}
	        else
                	vcftools --gzvcf "${vcfchr}" --positions ${PopChrDir}/dataset_${i} --phased --ldhat --chr ${chr} --out ${PopChrLDhatDir}/batch_${i}/${i}
        	fi
	done	
done

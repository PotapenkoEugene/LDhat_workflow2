#!/bin/bash

# Need to run only in POPULATION dir with chromo.chr? dirs and specified LK file!!!

############
CHRLIST="$(cat $1)"
LK=$(readlink -f $2) # lookup table required (Can take author's lk tables and convert it for your sample size with LDhat subfunction)
# Varied INTERVAL parameters
ITER=$3 # Number of iteration 10000000 - 60000000
SAMP=$4 # Sampling every 5000 updates
BPEN=$5 # BlockPenalty 5 - 20
BURNIN=$6 # Discard first N Burn in iteration in STAT tool 25000
NCPUS=$7 # ideal 20 for hive slurm system
#############


# MAKE SPLIT FILES FOR EACH CHROM
for chr in $CHRLIST
do
	chrdir="chromo.${chr}"
	echo $chr
	
	# Enter to chrom and batches dir
        cd ${chrdir}/LDhat_maf/
	ls | grep "batch_" > batch.list
	
	# Split files on batches based on NCPUS 
	split batch.list -l $NCPUS  # for 20 threads parallization

	# run INTERVAL on split files on each chromo
	for batchlist in `echo x??` 
        do 
        	 sbatch batchjob_LDhat_IntervalParallel.sh ${chr} $batchlist $LK $ITER $SAMP $BPEN $BURNIN $NCPUS
        done
	
	# Return
	cd ../../

done


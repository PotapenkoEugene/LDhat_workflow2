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
	#split batch.list -l $NCPUS  # for 20 threads parallization

	# Save job command for each batch
	for batch in `cat batch.list`
	do
		# Extract number of batch
	        i=$( echo ${batch} | cut -f2 -d _ )
	        # Run interval tool in background for paralleling
        	echo "interval -seq ${batch}/${i}.ldhat.sites -loc ${batch}/${i}.ldhat.locs -lk ${LK} -its ${ITER} -bpen ${BPEN} -samp ${SAMP} -prefix ${batch}/ > ${batch}/logs.txt ; stat -input ${batch}/rates.txt -burn ${BURNIN} -loc ${batch}/${i}.ldhat.locs -prefix ${batch}/ && rm ${batch}/rates.txt ${batch}/type_table.txt ${batch}/bounds.txt ${batch}/logs.txt"

		#Save jobs in file
	done > parallel_jobs.list
	
	# run parallel computing
	cat parallel_jobs.list | parallel -j $NCPUS
	
	# Return to population dir
	cd ../../

done


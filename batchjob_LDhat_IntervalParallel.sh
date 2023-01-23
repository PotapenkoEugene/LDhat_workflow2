#!/bin/bash

#SBATCH --ntasks 20           # use 20 cores
#SBATCH --ntasks-per-node=20  # use 20 cpus per each node
#SBATCH --time 1-00:00:00     # set job timelimit to 1 day and 3 hours
#SBATCH --partition hive1d    # partition name
#SBATCH -J interval_parallel_list      # sensible name for the job

cat $0

#!!!!!!!!!!!!!!!!!!!!!!!! RUN ONLY IN POPULATION DIRECTORY !!!!!!!!!!!!!!!!!!!!!#


# load up the correct modules, if required
. /etc/profile.d/modules.sh
module load gnu-parallel/2015.11.22 libs/glibc-2.14.1 gcc/5.1.0

############
CHR=$1
BATCHLISTNAME=$2; BATCHLIST="$(cat $2)" # files after split command xaa xab ... etc with list of batches
LK=$3 # lookup table required (Can take author's lk tables and convert it for your sample size with LDhat subfunction)
# Varied INTERVAL parameters
ITER=$4 # Number of iteration 10000000 - 60000000
SAMP=$5 # Sampling every 5000 updates
BPEN=$6 # BlockPenalty 5 - 20
BURNIN=$7 # Discard first N Burn in iteration in STAT tool 25000
NCPUS=$8
#############

# check
if [[ -z "${CHR}" ]]
then
	echo "STOP: CHROMOSOME NAME required"
	exit
fi

if [[ -z "${BATCHLIST}" ]]
then
	echo "STOP: BATCH LIST required"
	exit
fi

if [[ -z "${LK}" ]]
then
	echo "STOP: LOOKUP TABLE required\nCan take author's lk tables on LDhat github and convert it for your sample size with LDhat subfunction"
	exit
fi

if [[ -z "${ITER}" ]]
then 
	echo "STOP: NUMBER OF ITERATION required\nRecommended from 10000000 to 60000000"
	exit
fi

if [[ -z "${SAMP}" ]]
then 
	echo "STOP: SAMPLING FREQUENCY required\nRecommended 5000"
	exit
fi

if  [[ -z "${BPEN}" ]]
then
	echo "STOP: BLOCK PENALTY required\nRecommended from 5 to 20"
	exit
fi

echo "WARNING MAKE SURE TO PROVIDE CORRECT LOOKUP TABLE FOR YOUR DATASET"
###########################################################################

echo  "       running chromo.${CHR} with  ${ITER} iterations"
echo  "       sampling every ${SAMPLE} iterations"
echo "##################################################################"


for batch in $BATCHLIST
do
	i=$( echo ${batch} | cut -f2 -d _ )
	# Run interval tool in background for paralleling
	echo "interval -seq ${batch}/${i}.ldhat.sites -loc ${batch}/${i}.ldhat.locs -lk ${LK} -its ${ITER} -bpen ${BPEN} -samp ${SAMP} -prefix "${batch}/" > ${batch}/logs.txt"
	interval -seq ${batch}/${i}.ldhat.sites -loc ${batch}/${i}.ldhat.locs -lk ${LK} -its ${ITER} -bpen ${BPEN} -samp ${SAMP} -prefix "${batch}/" > ${batch}/logs.txt
#" # ; stat -input ${batch}/rates.txt -burn "${BURNIN}" -loc "${batch}/${i}.ldhat.locs" -prefix ${batch}/" # && rm ${batch}/rates.txt ${batch}/type_table.txt ${batch}/bounds.txt ${batch}/logs.txt"

#Save jobs in file and run parallel computing of it
done #> ${BATCHLISTNAME}_parallel_jobs.list ; cat ${BATCHLISTNAME}_parallel_jobs.list | parallel -j $NCPUS

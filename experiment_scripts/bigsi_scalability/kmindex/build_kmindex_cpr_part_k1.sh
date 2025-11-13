#!/bin/bash

KMPATH=~/kmindex_env/bin
KMINDEX=$KMPATH/kmindex
NSAMPLES=$1
NTHREADS=32
K=31
Z=3
TARGET_FPR=0.05

paste updated_files_24750.txt.fof.txt num_kmers.txt | head -n $NSAMPLES | awk '{om=int(log($4)/log(10)); print $1" contigs"$2>"p"om"_'$NSAMPLES'.fof.txt"; print $4>"p"om"_'$NSAMPLES'.num_kmers.txt"}'

ulimit -n 1000000

mkdir -p /scratch/BIGSI/kmindex

for PARTFILE in p*_$NSAMPLES.fof.txt; do
    PART=$(basename $PARTFILE .fof.txt)
    LARGEST=$(sort -nrk1 $PART.num_kmers.txt | head -n 1 | cut -f1)
    BLOOM_SIZE=$(echo "$LARGEST $TARGET_FPR" | awk '{print int(-$1/log(1-$2)*log(exp(1))+0.5)}')
    echo "part $PART; max(nelem) = $LARGEST -> size = $BLOOM_SIZE; index-k = $(( K - Z))"
    /usr/bin/time -v $KMINDEX build -f $PART.fof.txt --cpr -i /scratch/BIGSI/kmindex/kmindex_$NSAMPLES -d /scratch/BIGSI/kmindex/kmindex_${NSAMPLES}_$PART -r kmindex_${NSAMPLES}_$PART -k $(( K - Z )) -t $NTHREADS --hard-min 1 --bloom-size $BLOOM_SIZE >/scratch/BIGSI/kmindex/build_${NSAMPLES}_$PART.log 2>&1 &
done

wait

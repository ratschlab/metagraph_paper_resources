#!/bin/bash

DIR=~/metagenome/data/cloudcompute/mus_musculus/nobackup/build;

rm -rf ${DIR}/rd;
mkdir ${DIR}/rd;

ln -s ~/metagenome/data/cloudcompute/mus_musculus/metazoa_mus_musculus_primary.dbg \
      ${DIR}/rd/graph.dbg;

find ~/metagenome/data/cloudcompute/mus_musculus_annotation/nobackup/columns -name "*.annodbg" \
    > ${DIR}/columns.txt

mkdir ${DIR}/batches;
pushd ${DIR}/batches
split -d -n r/15 <(cat ../columns.txt | shuf)
popd

mkdir ${DIR}/rd/rd_columns

METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_release/metagraph

for B in {0..12..3}; do
    dep_cond="";
    for N in `seq $B $((B+2))`; do
        N=$(printf "%02d" $N);
        CHUNK=x$N;
        JOBID=$(bsub -J "mouse_rd_stage_0_$CHUNK" \
                 -oo ${DIR}/logs/mouse_rd_stage_0_$CHUNK.lsf \
                 -w "${dep_cond:4}" \
                 -W 24:00 \
                 -n 36 -R "rusage[mem=19400] span[hosts=1] select[hname!='le-amd-fp-004']" \
                "cat ${DIR}/batches/$CHUNK | /usr/bin/time -v $METAGRAPH transform_anno -v \
                    --anno-type row_diff \
                    --row-diff-stage 0 \
                    -i ${DIR}/rd/graph.dbg \
                    -o ${DIR}/rd/rd_columns/vector_${B}.row_count \
                    --mem-cap-gb 650 \
                    -p 72 \
                    2>&1 | tee ${DIR}/logs/mouse_rd_stage_0_$CHUNK.log" \
            | awk '/is submitted/{print substr($2, 2, length($2)-2);}');
        dep_cond+=" && $JOBID";
    done
done

bsub -J "mouse_rd_stage_1" \
     -oo ${DIR}/logs/mouse_rd_stage_1.lsf \
     -w "1341106 && 1341109 && 1341112 && 1341115 && 1341118 && 1341107 && 1341108 && 1341110 && 1341111 && 1341113 && 1341114 && 1341116 && 1341117 && 1341119 && 1341120" \
     -W 120:00 \
     -n 36 -R "rusage[mem=19000] span[hosts=1] select[hname!='le-amd-fp-004']" \
    "cat /dev/null | /usr/bin/time -v $METAGRAPH transform_anno -v \
        --anno-type row_diff \
        --row-diff-stage 1 \
        -i ${DIR}/rd/graph.dbg \
        -o ${DIR}/rd/rd_columns/vectors \
        -p 72 \
        2>&1 | tee ${DIR}/logs/mouse_rd_stage_1.log"


for B in {0..12..3}; do
    dep_cond="    1341121";
    for N in `seq $B $((B+2))`; do
        N=$(printf "%02d" $N);
        CHUNK=x$N;
        JOBID=$(bsub -J "mouse_rd_stage_1_$CHUNK" \
                 -oo ${DIR}/logs/mouse_rd_stage_1_$CHUNK.lsf \
                 -w "${dep_cond:4}" \
                 -W 24:00 \
                 -n 36 -R "rusage[mem=19400] span[hosts=1] select[hname!='le-amd-fp-004']" \
                "cat ${DIR}/batches/$CHUNK | /usr/bin/time -v $METAGRAPH transform_anno -v \
                    --anno-type row_diff \
                    --row-diff-stage 1 \
                    -i ${DIR}/rd/graph.dbg \
                    -o ${DIR}/rd/rd_columns/vector_${B}.row_reduction \
                    --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
                    --mem-cap-gb 650 \
                    -p 72 \
                    2>&1 | tee ${DIR}/logs/mouse_rd_stage_1_$CHUNK.log" \
            | awk '/is submitted/{print substr($2, 2, length($2)-2);}');
        dep_cond+=" && $JOBID";
    done
done


bsub -J "mouse_rd_stage_2" \
     -oo ${DIR}/logs/mouse_rd_stage_2.lsf \
     -w "1341137 && 1341138 && 1341139 && 1341140 && 1341141 && 1341142 && 1341143 && 1341144 && 1341145 && 1341146 && 1341147 && 1341148 && 1341149 && 1341150 && 1341151" \
     -W 24:00 \
     -n 36 -R "rusage[mem=19000] span[hosts=1] select[hname!='le-amd-fp-004']" \
    "cat /dev/null | /usr/bin/time -v $METAGRAPH transform_anno -v \
        --anno-type row_diff \
        --row-diff-stage 2 \
        -i ${DIR}/rd/graph.dbg \
        -o ${DIR}/rd/rd_columns/vectors \
        -p 72 \
        2>&1 | tee ${DIR}/logs/mouse_rd_stage_2.log"


for B in {0..12..3}; do
    dep_cond="    1341162";
    for N in `seq $B $((B+2))`; do
        N=$(printf "%02d" $N);
        CHUNK=x$N;
        JOBID=$(bsub -J "mouse_rd_stage_2_$CHUNK" \
                 -oo ${DIR}/logs/mouse_rd_stage_2_$CHUNK.lsf \
                 -w "${dep_cond:4}" \
                 -W 24:00 \
                 -n 36 -R "rusage[mem=19400] span[hosts=1] select[hname!='le-amd-fp-004']" \
                "cat ${DIR}/batches/$CHUNK | /usr/bin/time -v $METAGRAPH transform_anno -v \
                    --anno-type row_diff \
                    --row-diff-stage 2 \
                    -i ${DIR}/rd/graph.dbg \
                    -o ${DIR}/rd/rd_columns/columns \
                    --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
                    --mem-cap-gb 650 \
                    -p 72 \
                    2>&1 | tee ${DIR}/logs/mouse_rd_stage_2_$CHUNK.log" \
            | awk '/is submitted/{print substr($2, 2, length($2)-2);}');
        dep_cond+=" && $JOBID";
    done
done


find ${DIR}/rd/rd_columns/ -name "*.annodbg" > ${DIR}/rd/rd_columns.txt

bsub -J "mouse_rd_brwt" \
     -oo ${DIR}/logs/build_rd_brwt.lsf \
     -W 24:00 \
     -n 36 -R "rusage[mem=19000] span[hosts=1]" \
    "find ${DIR}/rd/rd_columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_brwt \
            --greedy \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation \
            --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
            -p 72 --parallel-nodes 10 \
            2>&1 | tee ${DIR}/logs/build_rd_brwt.log"

bsub -J "mouse_rd_brwt_relax" \
     -w "mouse_rd_brwt" \
     -oo ${DIR}/logs/build_rd_brwt_relax.lsf \
     -W 24:00 \
     -n 36 -R "rusage[mem=19000] span[hosts=1]" \
    "/usr/bin/time -v $METAGRAPH relax_brwt -v \
        -p 36 \
        --relax-arity 32 \
        -o ${DIR}/annotation.relaxed \
        ${DIR}/annotation.row_diff_brwt.annodbg \
        2>&1 | tee ${DIR}/logs/build_rd_brwt_relax.log"

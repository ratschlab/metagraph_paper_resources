#!/bin/bash

ln -s ~/metagenome/data/uhgg/uhgg_catalogue/graphs/graph_complete_k31.dbg \
      ~/metagenome/data/uhgg/uhgg_catalogue/graphs/build/rd/graph.dbg;

DIR=~/metagenome/data/uhgg/uhgg_catalogue/graphs/build;
mkdir ${DIR}/rd/rd_columns;
METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_release/metagraph;

bsub -J "uhgg_rd_stage_0" \
     -oo ${DIR}/logs/rd_stage_0.lsf \
     -W 4:00 \
     -n 36 -R "rusage[mem=5000] span[hosts=1]" \
    "find ~/metagenome/data/uhgg/uhgg_catalogue/annotation/columns -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 0 \
            --mem-cap-gb 650 \
            --parallel 72 \
            -o ${DIR}/rd/rd_columns/out \
            -i ${DIR}/rd/graph.dbg \
            2>&1 | tee ${DIR}/logs/rd_stage_0.log"; \

bsub -J "uhgg_rd_stage_1" \
     -w "uhgg_rd_stage_0" \
     -oo ${DIR}/logs/rd_stage_1.lsf \
     -W 4:00 \
     -n 36 -R "rusage[mem=5000] span[hosts=1]" \
    "find ~/metagenome/data/uhgg/uhgg_catalogue/annotation/columns -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 1 \
            --mem-cap-gb 650 \
            --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
            --parallel 72 \
            -o ${DIR}/rd/rd_columns/out \
            -i ${DIR}/rd/graph.dbg \
            2>&1 | tee ${DIR}/logs/rd_stage_1.log"; \

bsub -J "uhgg_rd_stage_2" \
     -w "uhgg_rd_stage_1" \
     -oo ${DIR}/logs/rd_stage_2.lsf \
     -W 4:00 \
     -n 36 -R "rusage[mem=5000] span[hosts=1]" \
    "find ~/metagenome/data/uhgg/uhgg_catalogue/annotation/columns -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 2 \
            --max-path-length 200 \
            --mem-cap-gb 650 \
            --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
            --parallel 72 \
            -o ${DIR}/rd/rd_columns/out \
            -i ${DIR}/rd/graph.dbg \
            2>&1 | tee ${DIR}/logs/rd_stage_2.log"; \

bsub -J "uhgg_rd_brwt" \
     -w "uhgg_rd_stage_2" \
     -oo ${DIR}/logs/rd_brwt.lsf \
     -W 4:00 \
     -n 36 -R "rusage[mem=5000] span[hosts=1]" \
    "find ${DIR}/rd/rd_columns -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_brwt \
            --greedy --subsample 10000000 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation \
            -p 72 --parallel-nodes 10 \
            2>&1 | tee ${DIR}/logs/rd_brwt.log"

bsub -J "uhgg_rd_brwt_relax" \
     -w "uhgg_rd_brwt" \
     -oo ${DIR}/logs/rd_brwt_relax.lsf \
     -W 4:00 \
     -n 36 -R "rusage[mem=5000] span[hosts=1]" \
    "/usr/bin/time -v $METAGRAPH relax_brwt -v \
        --relax-arity 32 \
        -o ${DIR}/annotation.relaxed \
        -p 72 \
        ${DIR}/annotation.row_diff_brwt.annodbg \
        2>&1 | tee ${DIR}/logs/rd_brwt_relax.log"

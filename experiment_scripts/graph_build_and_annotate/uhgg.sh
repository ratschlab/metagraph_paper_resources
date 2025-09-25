#!/bin/bash

rm -rf ~/metagenome/data/uhgg/all_genomes/build/rd;
mkdir ~/metagenome/data/uhgg/all_genomes/build/rd;

ln -s ~/metagenome/data/uhgg/all_genomes/graph_complete_k31.dbg \
      ~/metagenome/data/uhgg/all_genomes/build/rd/graph.dbg;

DIR=~/metagenome/data/uhgg/all_genomes/build;
mkdir ${DIR}/rd/rd_columns;
METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_test/metagraph;

bsub -J "UHGG_rd_stage_0" \
     -oo ${DIR}/logs/rd_stage_0.lsf \
     -W 24:00 \
     -n 36 -R "rusage[mem=19000] span[hosts=1]" \
    "find ${DIR}/columns -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 0 \
            --mem-cap-gb 650 \
            --parallel 72 \
            -o ${DIR}/rd/rd_columns/out \
            -i ${DIR}/rd/graph.dbg \
            2>&1 | tee ${DIR}/logs/rd_stage_0.log"; \

bsub -J "UHGG_rd_stage_1" \
     -w "UHGG_rd_stage_0" \
     -oo ${DIR}/logs/rd_stage_1.lsf \
     -W 24:00 \
     -n 36 -R "rusage[mem=19000] span[hosts=1]" \
    "find ${DIR}/columns -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 1 \
            --mem-cap-gb 650 \
            --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
            --parallel 72 \
            -o ${DIR}/rd/rd_columns/out \
            -i ${DIR}/rd/graph.dbg \
            2>&1 | tee ${DIR}/logs/rd_stage_1.log"; \

bsub -J "UHGG_rd_stage_2" \
     -w "UHGG_rd_stage_1" \
     -oo ${DIR}/logs/rd_stage_2.lsf \
     -W 24:00 \
     -n 36 -R "rusage[mem=19000] span[hosts=1]" \
    "find ${DIR}/columns -name \"*.annodbg\" \
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

sbatch -J "UHGG_rd_disk" \
     -d afterok:$(get_jobid UHGG_rd_stage_2) \
     -o $DIR/logs/rd_disk.slog \
     -t 0-24 \
     --cpus-per-task 34 \
     --mem-per-cpu=10G \
     --partition=compute,gpu \
     --wrap="find $DIR/rd/rd_columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_disk \
            --mem-cap-gb 220 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation \
            -p 34"

bsub -J "UHGG_rd_brwt" \
     -w "UHGG_rd_stage_2" \
     -oo ${DIR}/logs/rd_brwt.lsf \
     -W 120:00 \
     -n 36 -R "rusage[mem=19000] span[hosts=1]" \
    "find ${DIR}/rd/rd_columns -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_brwt \
            --greedy --subsample 1000000 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation \
            -p 72 --parallel-nodes 10 \
            2>&1 | tee ${DIR}/logs/rd_brwt.log"

bsub -J "UHGG_rd_brwt_relax" \
     -w "UHGG_rd_brwt" \
     -oo ${DIR}/logs/rd_brwt_relax.lsf \
     -W 24:00 \
     -n 36 -R "rusage[mem=19000] span[hosts=1]" \
    "/usr/bin/time -v $METAGRAPH relax_brwt -v \
        --relax-arity 32 \
        -o ${DIR}/annotation.relaxed \
        -p 72 \
        ${DIR}/annotation.row_diff_brwt.annodbg \
        2>&1 | tee ${DIR}/logs/rd_brwt_relax.log"

#!/bin/bash

mkdir ~/metagenome/data/metasub/graphs/k19/build/rd;

ln -s ~/metagenome/data/metasub/graphs/k19/graph_merged_k19.primary.dbg \
      ~/metagenome/data/metasub/graphs/k19/build/rd/graph.dbg;

DIR=~/metagenome/data/metasub/graphs/k19/build;
mkdir ${DIR}/rd/rd_columns;
METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_test/metagraph;

sbatch -J "metasub_rd_0" \
     -o $DIR/logs/rd_0.slog \
     -t 0-24 \
     --cpus-per-task 34 \
     --mem-per-cpu=14G \
     --partition=compute \
    --wrap="find $DIR/columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 0 \
            --mem-cap-gb 420 \
            -p 34 \
            -o $DIR/rd/rd_columns/out \
            -i $DIR/rd/graph.dbg"; \

sbatch -J "metasub_rd_1" \
     -d afterok:$(get_jobid metasub_rd_0) \
     -o $DIR/logs/rd_1.slog \
     -t 0-24 \
     --cpus-per-task 34 \
     --mem-per-cpu=14G \
     --partition=compute \
    --wrap="find $DIR/columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 1 \
            --mem-cap-gb 420 \
            -p 34 \
            -o $DIR/rd/rd_columns/out \
            -i $DIR/rd/graph.dbg"; \

sbatch -J "metasub_rd_2" \
     -d afterok:$(get_jobid metasub_rd_1) \
     -o $DIR/logs/rd_2.slog \
     -t 0-24 \
     --cpus-per-task 34 \
     --mem-per-cpu=14G \
     --partition=compute \
    --wrap="find $DIR/columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 2 \
            --mem-cap-gb 420 \
            -p 34 \
            -o $DIR/rd/rd_columns/out \
            -i $DIR/rd/graph.dbg"; \

sbatch -J "metasub_rd_disk" \
     -d afterok:$(get_jobid metasub_rd_2) \
     -o $DIR/logs/rd_disk.slog \
     -t 0-24 \
     --cpus-per-task 34 \
     --mem-per-cpu=19G \
     --wrap="find $DIR/rd/rd_columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_disk \
            --mem-cap-gb 420 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation \
            -p 34"

bsub -J "metasub_rd_brwt" \
     -w "metasub_rd_stage_2" \
     -oo ${DIR}/logs/rd_brwt.lsf \
     -W 24:00 \
     -n 36 -R "rusage[mem=15000] span[hosts=1]" \
    "find ${DIR}/rd/rd_columns -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_brwt \
            --greedy --subsample 10000000 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation \
            -p 72 --parallel-nodes 10 \
            2>&1 | tee ${DIR}/logs/rd_brwt.log"

bsub -J "metasub_rd_brwt_relax" \
     -w "metasub_rd_brwt" \
     -oo ${DIR}/logs/rd_brwt_relax.lsf \
     -W 24:00 \
     -n 36 -R "rusage[mem=15000] span[hosts=1]" \
    "/usr/bin/time -v $METAGRAPH relax_brwt -v \
        --relax-arity 32 \
        -o ${DIR}/annotation.relaxed \
        -p 72 \
        ${DIR}/annotation.row_diff_brwt.annodbg \
        2>&1 | tee ${DIR}/logs/rd_brwt_relax.log"

#!/bin/bash

ln -s ~/metagenome/data/metasub/graphs/output_k41_cleaned_graph/graph_merged_k41.primary.dbg \
      ~/metagenome/data/metasub/graphs/k41/build/rd/graph.dbg;

DIR=~/metagenome/data/metasub/graphs/k41/build;
mkdir ${DIR}/rd/rd_columns;
METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_release/metagraph;

sbatch -J "metasub_rd_stage_0" \
     -o ${DIR}/logs/rd_stage_0.slog \
     -t 00-24 \
     --cpus-per-task 36 \
     --mem-per-cpu=19G \
     --wrap="find ${DIR}/columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 0 \
            --mem-cap-gb 300 \
            --parallel 36 \
            -o ${DIR}/rd/rd_columns/out \
            -i ${DIR}/rd/graph.dbg"; \

sbatch -J "metasub_rd_stage_1" \
     -d afterok:$(get_jobid metasub_rd_stage_0) \
     -o ${DIR}/logs/rd_stage_1.slog \
     -t 00-24 \
     --cpus-per-task 36 \
     --mem-per-cpu=19G \
     --wrap="find ${DIR}/columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 1 \
            --mem-cap-gb 300 \
            --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
            --parallel 36 \
            -o ${DIR}/rd/rd_columns/out \
            -i ${DIR}/rd/graph.dbg"; \

sbatch -J "metasub_rd_stage_2" \
     -d afterok:$(get_jobid metasub_rd_stage_1) \
     -o ${DIR}/logs/rd_stage_2.slog \
     -t 00-24 \
     --cpus-per-task 36 \
     --mem-per-cpu=19G \
     --wrap="find ${DIR}/columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 2 \
            --max-path-length 100 \
            --mem-cap-gb 300 \
            --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
            --parallel 36 \
            -o ${DIR}/rd/rd_columns/out \
            -i ${DIR}/rd/graph.dbg"; \

sbatch -J "metasub_rd_brwt" \
     -d afterok:$(get_jobid metasub_rd_stage_2) \
     -o ${DIR}/logs/rd_brwt.slog \
     -t 00-24 \
     --cpus-per-task 36 \
     --mem-per-cpu=15G \
     --wrap="find ${DIR}/rd/rd_columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_brwt \
            --greedy --subsample 10000000 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation \
            -p 72 --parallel-nodes 10"

sbatch -J "metasub_rd_brwt_relax" \
     -d afterok:$(get_jobid metasub_rd_brwt) \
     -o ${DIR}/logs/rd_brwt_relax.slog \
     -t 00-24 \
     --cpus-per-task 36 \
     --mem-per-cpu=15G \
     --wrap="/usr/bin/time -v $METAGRAPH relax_brwt -v \
        --relax-arity 32 \
        -o ${DIR}/annotation.relaxed \
        -p 72 \
        ${DIR}/annotation.row_diff_brwt.annodbg"

sbatch -J "metasub_rd_disk" \
     -d afterok:$(get_jobid metasub_rd_stage_2) \
     -o ${DIR}/logs/rd_disk.slog \
     -t 00-24 \
     --cpus-per-task 36 \
     --mem-per-cpu=15G \
     --wrap="find ${DIR}/rd/rd_columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_disk \
            --mem-cap-gb 300 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation \
            -p 36"

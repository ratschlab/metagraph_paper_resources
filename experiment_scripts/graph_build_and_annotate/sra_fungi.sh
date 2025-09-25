#!/bin/bash

DIR=~/metagenome/data/cloudcompute/fungi_graphs;
METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_test/metagraph;

mkdir -p ${DIR}/logs;

sbatch -J "fungi" \
     -o $DIR/logs/build_graph.slog \
     -t 7-00 \
     --cpus-per-task 34 \
     --mem-per-cpu=19G \
    --wrap="cat ${DIR}/samples.txt \
        | /usr/bin/time -v $METAGRAPH build -v \
            -k 31 \
            --mode canonical \
            --mem-cap-gb 80 \
            --disk-swap ~/metagenome/scratch/nobackup/ \
            -p 34 \
            -o $DIR/graph; \
    /usr/bin/time -v $METAGRAPH transform -v \
            --to-fasta \
            --primary-kmers \
            -p 34 \
            -o $DIR/primary_contigs \
            $DIR/graph.dbg; \
    /usr/bin/time -v $METAGRAPH build -v \
            -k 31 \
            --mode primary \
            --mem-cap-gb 80 \
            --disk-swap ~/metagenome/scratch/nobackup/ \
            -p 34 \
            -o $DIR/graph_primary \
            $DIR/primary_contigs.fasta.gz; \
    /usr/bin/time -v $METAGRAPH transform -v \
            --state small \
            -p 34 \
            -o $DIR/graph_primary_small \
            $DIR/graph_primary.dbg;"

mkdir ${DIR}/columns;

sbatch -J "fungi_annotate" \
     -o $DIR/logs/annotate_graph.slog \
     -t 00-120 \
     --cpus-per-task 34 \
     --mem-per-cpu=19G \
    --wrap="cat ${DIR}/samples.txt \
        | /usr/bin/time -v $METAGRAPH annotate -v \
            -i $DIR/graph_primary.dbg \
            --anno-filename \
            --separately \
            -o ${DIR}/columns \
            -p 4 \
            --threads-each 8"

mkdir -p ${DIR}/rd/rd_columns;

ln -s $DIR/graph_primary.dbg ${DIR}/rd/graph.dbg;

sbatch -J "fungi_rd_0" \
     -o $DIR/logs/rd_0.slog \
     -t 00-72 \
     --cpus-per-task 34 \
     --mem-per-cpu=19G \
     --exclude compute-biomed-03,compute-biomed-02,compute-biomed-10 \
    --wrap="find ${DIR}/columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 0 \
            --mem-cap-gb 500 \
            -p 34 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/rd/rd_columns/out"

sbatch -J "fungi_rd_1" \
     -d afterok:$(get_jobid fungi_rd_0) \
     -o $DIR/logs/rd_1.slog \
     -t 00-72 \
     --cpus-per-task 34 \
     --mem-per-cpu=19G \
     --exclude compute-biomed-03,compute-biomed-02,compute-biomed-10 \
    --wrap="find ${DIR}/columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 1 \
            --mem-cap-gb 500 \
            --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
            -p 34 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/rd/rd_columns/out"

sbatch -J "fungi_rd_2" \
     -d afterok:$(get_jobid fungi_rd_1) \
     -o $DIR/logs/rd_2.slog \
     -t 00-72 \
     --cpus-per-task 34 \
     --mem-per-cpu=19G \
     --exclude compute-biomed-03,compute-biomed-02,compute-biomed-10 \
    --wrap="find ${DIR}/columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 2 \
            --mem-cap-gb 500 \
            --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
            -p 34 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/rd/rd_columns/out"

sbatch -J "fungi_rd_flat" \
     -d afterok:$(get_jobid fungi_rd_2) \
     -o $DIR/logs/rd_flat.slog \
     -t 00-72 \
     --cpus-per-task 34 \
     --mem-per-cpu=8G \
     --exclude compute-biomed-03,compute-biomed-02 \
    --wrap="find ${DIR}/rd/rd_columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_flat \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation \
            -p 34"

sbatch -J "fungi_rd_sparse" \
     -d afterok:$(get_jobid fungi_rd_2) \
     -o $DIR/logs/rd_sparse.slog \
     -t 00-72 \
     --cpus-per-task 34 \
     --mem-per-cpu=8G \
     --exclude compute-biomed-03,compute-biomed-02 \
    --wrap="find ${DIR}/rd/rd_columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_sparse \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation \
            -p 34"

sbatch -J "fungi_rd_disk" \
     -d afterok:$(get_jobid fungi_rd_2) \
     -o $DIR/logs/rd_disk.slog \
     -t 00-24 \
     --cpus-per-task 34 \
     --mem-per-cpu=15G \
     --exclude compute-biomed-03,compute-biomed-02 \
    --wrap="find ${DIR}/rd/rd_columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_disk \
            --mem-cap-gb 300 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation \
            -p 34"

sbatch -J "fungi_rd_brwt" \
     -d afterok:$(get_jobid fungi_rd_2) \
     -o $DIR/logs/rd_brwt.slog \
     -t 00-72 \
     --cpus-per-task 56 \
     --mem-per-cpu=15G \
     --exclude compute-biomed-03,compute-biomed-02 \
    --wrap="find ${DIR}/rd/rd_columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_brwt \
            --greedy --subsample 200000 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation_new \
            --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
            -p 56 --parallel-nodes 10"

sbatch -J "fungi_rd_brwt_relax" \
     -d afterok:$(get_jobid fungi_rd_brwt) \
     -o $DIR/logs/rd_brwt_relax.slog \
     -t 00-72 \
     --cpus-per-task 34 \
     --mem-per-cpu=8G \
     --exclude compute-biomed-03,compute-biomed-02 \
    --wrap="/usr/bin/time -v $METAGRAPH relax_brwt -v \
        -p 34 \
        --relax-arity 32 \
        -o ${DIR}/annotation_new.relaxed \
        ${DIR}/annotation_new.row_diff_brwt.annodbg"

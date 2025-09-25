#!/bin/bash

DIR=~/metagenome/data/cloudcompute/random_100_studies;
METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_test/metagraph;

find ~/metagenome/data/cloudcompute/metagraph_1kstudies -name "*.fasta.gz" > $DIR/samples.txt;

mkdir -p ${DIR}/logs;

sbatch -J "random100" \
     -o $DIR/logs/build_graph.slog \
     -t 00-120 \
     --cpus-per-task 34 \
     --mem-per-cpu=3G \
    --wrap="cat ${DIR}/samples.txt \
        | /usr/bin/time -v $METAGRAPH build -v \
            -k 31 \
            --inplace \
            --mode canonical \
            --mem-cap-gb 50 \
            --disk-swap ~/metagenome/scratch/nobackup \
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
            --mem-cap-gb 50 \
            --disk-swap ~/metagenome/scratch/nobackup \
            -p 34 \
            -o $DIR/graph_primary \
            $DIR/primary_contigs.fasta.gz; \
    /usr/bin/time -v $METAGRAPH transform -v \
            --state small \
            -p 34 \
            -o $DIR/graph_primary_small \
            $DIR/graph_primary.dbg;"


mkdir ${DIR}/columns;

sbatch -J "random100_annotate" \
     -d afterok:$(get_jobid random100) \
     -o $DIR/logs/annotate_graph.slog \
     -t 00-120 \
     --cpus-per-task 34 \
     --mem-per-cpu=3G \
    --wrap="cat ${DIR}/samples.txt \
        | /usr/bin/time -v $METAGRAPH annotate -v \
            -i $DIR/graph_primary.dbg \
            --anno-filename \
            --separately \
            -o ${DIR}/columns \
            -p 5 \
            --threads-each 8"


rm -rf ${DIR}/rd;
mkdir ${DIR}/rd;

ln -s $DIR/graph_primary.dbg $DIR/rd/graph.dbg;

mkdir ${DIR}/rd/rd_columns

sbatch -J "random100_rd_0" \
     -d afterok:$(get_jobid random100_annotate) \
     -o $DIR/logs/rd_0.slog \
     -t 00-120 \
     --cpus-per-task 34 \
     --mem-per-cpu=10G \
    --wrap="find ${DIR}/columns -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 0 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/rd/rd_columns/out \
            --mem-cap-gb 70 \
            -p 34"


sbatch -J "random100_rd_1" \
     -d afterok:$(get_jobid random100_rd_0) \
     -o $DIR/logs/rd_1.slog \
     -t 00-120 \
     --cpus-per-task 34 \
     --mem-per-cpu=10G \
    --wrap="find ${DIR}/columns -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 1 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/rd/rd_columns/out \
            --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
            --mem-cap-gb 70 \
            -p 34"


sbatch -J "random100_rd_2" \
     -d afterok:$(get_jobid random100_rd_1) \
     -o $DIR/logs/rd_2.slog \
     -t 00-120 \
     --cpus-per-task 34 \
     --mem-per-cpu=10G \
    --wrap="find ${DIR}/columns -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 2 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/rd/rd_columns/out \
            --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
            --mem-cap-gb 70 \
            -p 34"


sbatch -J "random100_rd_flat" \
     -d afterok:$(get_jobid random100_rd_2) \
     -o ${DIR}/logs/rd_flat.slog \
     -t 00-24 \
     --cpus-per-task 34 \
     --mem-per-cpu=10G \
    --wrap="find ${DIR}/rd/rd_columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_flat \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation \
            -p 34"

sbatch -J "random100_rd_sparse" \
     -d afterok:$(get_jobid random100_rd_2) \
     -o ${DIR}/logs/rd_sparse.slog \
     -t 00-24 \
     --cpus-per-task 34 \
     --mem-per-cpu=10G \
    --wrap="find ${DIR}/rd/rd_columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_sparse \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation \
            -p 34"

sbatch -J "random100_rd_brwt" \
     -o ${DIR}/logs/rd_brwt.slog \
     -t 00-24 \
     --cpus-per-task 34 \
     --mem-per-cpu=24G \
    --wrap="find ${DIR}/rd/rd_columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_brwt \
            --greedy --subsample 10000000 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation \
            --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
            -p 34 --parallel-nodes 10"

sbatch -J "random100_rd_brwt_relax" \
     -d afterok:$(get_jobid random100_rd_brwt) \
     -o ${DIR}/logs/rd_brwt_relax.slog \
     -t 00-24 \
     --cpus-per-task 34 \
     --mem-per-cpu=8G \
    --wrap="/usr/bin/time -v $METAGRAPH relax_brwt -v \
        -p 34 \
        --relax-arity 32 \
        -o ${DIR}/annotation.relaxed \
        ${DIR}/annotation.row_diff_brwt.annodbg"

sbatch -J "random100_rd_disk" \
     -o ${DIR}/logs/rd_disk.slog \
     -t 00-12 \
     --cpus-per-task 34 \
     --mem-per-cpu=10G \
    --wrap="find ${DIR}/rd/rd_columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_disk \
            --mem-cap-gb 250 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation \
            -p 34"




sbatch -J "random100_rd_brwt_orig_linkage" \
     -o ${DIR}/logs/rd_brwt_orig_linkage.slog \
     -t 00-24 \
     --cpus-per-task 34 \
     --mem-per-cpu=10G \
    --wrap="for x in \$(cat samples.txt); do echo columns/\$(basename \$x).column.annodbg; done \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_brwt \
            --greedy --linkage \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/linkage_from_columns \
            -p 34"

sbatch -J "random100_rd_brwt_orig" \
     -d afterok:$(get_jobid random100_rd_brwt_orig_linkage) \
     -o ${DIR}/logs/rd_brwt_orig.slog \
     -t 00-24 \
     --cpus-per-task 34 \
     --mem-per-cpu=24G \
    --wrap="for x in \$(cat samples.txt); do echo rd/rd_columns/\$(basename \$x).row_diff.annodbg; done \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_brwt \
            --linkage-file ${DIR}/linkage_from_columns \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation_orig \
            --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
            -p 34 --parallel-nodes 10"


sbatch -J "random100_rd_brwt_orig_relax" \
     -d afterok:$(get_jobid random100_rd_brwt_orig) \
     -o ${DIR}/logs/rd_brwt_orig_relax_orig.slog \
     -t 00-24 \
     --cpus-per-task 34 \
     --mem-per-cpu=8G \
    --wrap="/usr/bin/time -v $METAGRAPH relax_brwt -v \
        -p 34 \
        --relax-arity 32 \
        -o ${DIR}/annotation_orig.relaxed \
        ${DIR}/annotation_orig.row_diff_brwt.annodbg"

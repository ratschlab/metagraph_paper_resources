#!/bin/bash

for i in {0,9}; do
    DIR=~/metagenome/data/cloudcompute/metazoa_graphs/nobackup/chunk_${i};
    METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_test/metagraph;
    mkdir -p ${DIR}/logs;

    cut -f1 ${DIR}/metazoa_all_cleanable_no_pacbio_no_nanopore_metadata_only_genomic_${i}_chunk.tsv | tail -n +2 > $DIR/ids.txt;
    for x in $(cat $DIR/ids.txt); do echo /cluster/work/grlab/projects/metagenome/data/cloudcompute/metazoa/clean/${x:0:3}/${x:0:6}/${x}/$x.fasta.gz; done > $DIR/samples.txt;

    sbatch -J "metazoa_${i}" \
         -o $DIR/logs/build_graph.slog \
         -t 7-00 \
         --cpus-per-task 34 \
         --mem-per-cpu=19G \
         --partition=compute \
         --exclude compute-biomed-10 \
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
                $DIR/graph.dbg \
            && rm $DIR/graph.dbg; \
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

    sbatch -J "metazoa_${i}_annotate" \
         -d afterok:$(get_jobid metazoa_${i}) \
         -o $DIR/logs/annotate_graph.slog \
         -t 7-00 \
         --cpus-per-task 56 \
         --mem-per-cpu=15G \
         --exclude compute-biomed-10 \
        --wrap="cat ${DIR}/samples.txt \
            | /usr/bin/time -v $METAGRAPH annotate -v \
                -i $DIR/graph_primary.dbg \
                --anno-filename \
                --separately \
                -o ${DIR}/columns \
                -p 4 \
                --threads-each 14"

    rm -rf ${DIR}/rd;
    mkdir ${DIR}/rd;

    ln -s $DIR/graph_primary.dbg $DIR/rd/graph.dbg;

    mkdir ${DIR}/rd/rd_columns;

    sbatch -J "metazoa_${i}_rd_0" \
         -d afterok:$(get_jobid metazoa_${i}_annotate) \
         -o $DIR/logs/rd_0.slog \
         -t 7-00 \
         --cpus-per-task 34 \
         --mem-per-cpu=19G \
         --exclude compute-biomed-10 \
        --wrap="find ${DIR}/columns -name \"*.annodbg\" \
            | /usr/bin/time -v $METAGRAPH transform_anno -v \
                --anno-type row_diff \
                --row-diff-stage 0 \
                -i ${DIR}/rd/graph.dbg \
                -o ${DIR}/rd/rd_columns/out \
                --mem-cap-gb 500 \
                -p 34"


    sbatch -J "metazoa_${i}_rd_1" \
         -d afterok:$(get_jobid metazoa_${i}_rd_0) \
         -o $DIR/logs/rd_1.slog \
         -t 7-00 \
         --cpus-per-task 34 \
         --mem-per-cpu=19G \
         --exclude compute-biomed-10 \
        --wrap="find ${DIR}/columns -name \"*.annodbg\" \
            | /usr/bin/time -v $METAGRAPH transform_anno -v \
                --anno-type row_diff \
                --row-diff-stage 1 \
                -i ${DIR}/rd/graph.dbg \
                -o ${DIR}/rd/rd_columns/out \
                --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
                --mem-cap-gb 500 \
                -p 34 && \
            rm ${DIR}/rd/rd_columns/*.row_count"

    sbatch -J "metazoa_${i}_rd_2" \
         -d afterok:$(get_jobid metazoa_${i}_rd_1) \
         -o $DIR/logs/rd_2.slog \
         -t 7-00 \
         --cpus-per-task 34 \
         --mem-per-cpu=19G \
         --exclude compute-biomed-10 \
        --wrap="find ${DIR}/columns -name \"*.annodbg\" \
            | /usr/bin/time -v $METAGRAPH transform_anno -v \
                --anno-type row_diff \
                --row-diff-stage 2 \
                -i ${DIR}/rd/graph.dbg \
                -o ${DIR}/rd/rd_columns/out \
                --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
                --mem-cap-gb 500 \
                -p 34 && \
            rm ${DIR}/rd/rd_columns/*.row_reduction && \
            rm ${DIR}/rd/graph.dbg.pred* && \
            rm ${DIR}/rd/graph.dbg.succ* && \
            ls -l ${DIR}/columns | grep annodbg > ${DIR}/columns.txt && \
            rm -r ${DIR}/columns"


    sbatch -J "metazoa_${i}_rd_brwt" \
         -d afterok:$(get_jobid metazoa_${i}_rd_2) \
         -o ${DIR}/logs/rd_brwt.slog \
         -t 7-00 \
         --cpus-per-task 34 \
         --mem-per-cpu=24G \
        --wrap="find ${DIR}/rd/rd_columns/ -name \"*.annodbg\" \
            | /usr/bin/time -v $METAGRAPH transform_anno -v \
                --anno-type row_diff_brwt \
                --greedy \
                -i ${DIR}/rd/graph.dbg \
                -o ${DIR}/annotation \
                --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
                -p 34 --parallel-nodes 4"

    sbatch -J "metazoa_${i}_rd_brwt_relax" \
         -d afterok:$(get_jobid metazoa_${i}_rd_brwt) \
         -o ${DIR}/logs/rd_brwt_relax.slog \
         -t 2-00 \
         --cpus-per-task 17 \
         --mem-per-cpu=40G \
        --wrap="/usr/bin/time -v $METAGRAPH relax_brwt -v \
            -p 17 \
            --relax-arity 32 \
            -o ${DIR}/annotation.relaxed \
            ${DIR}/annotation.row_diff_brwt.annodbg && \
        rm ${DIR}/annotation.row_diff_brwt.annodbg"
done


for i in 00 {0..15}; do
    DIR=~/metagenome/data/cloudcompute/metazoa_graphs/nobackup/chunk_${i};
    METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_test/metagraph;
    mkdir -p ${DIR}/logs;

    sbatch -J "stats_${i}" \
         -o $DIR/logs/graph_stats.slog \
         -t 7-00 \
         --cpus-per-task 34 \
         --mem-per-cpu=10G \
         --partition=compute \
        --wrap="/usr/bin/time -v $METAGRAPH stats -v --count-dummy \
                -p 34 \
                $DIR/graph_primary_small.dbg"
done

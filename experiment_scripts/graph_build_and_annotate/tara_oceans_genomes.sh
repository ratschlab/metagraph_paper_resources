#!/bin/bash

DATA=/cluster/work/grlab/projects/metagenome/raw_data/tara/genomes-fasta;
DIR=~/metagenome/data/tara/genome_coord;

mkdir $DIR;
mkdir $DIR/logs;

find $DATA -name "*.gz" > $DIR/list.txt;

METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_release/metagraph;
bsub -J "build_graph_genomes" \
     -oo $DIR/logs/build_graph.lsf \
     -W 24:00 \
     -n 36 -R "rusage[mem=19000] span[hosts=1]" \
    "cat $DIR/list.txt \
        | /usr/bin/time -v $METAGRAPH build -v \
            -k 31 \
            --mem-cap-gb 50 \
            --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
            -p 72 \
            -o $DIR/graph; \
    /usr/bin/time -v $METAGRAPH transform -v \
            --state small \
            -p 72 \
            -o $DIR/graph_small \
            $DIR/graph.dbg;"

DATA=/cluster/work/grlab/projects/metagenome/raw_data/tara/genomes-fasta
DIR=~/metagenome/data/tara/genome_coord;
mkdir $DIR/columns;
mkdir $DIR/batches;
cd $DIR/batches;
split -d -n r/40 <(find $DATA -name "*.gz" | shuf);

for N in {0..39}; do
    N=$(printf "%02d" $N);
    list=x$N;
    bsub -J "count_bp_assemblies_${list}" \
         -o /dev/null \
         -W 4:00 \
         -n 1 -R "rusage[mem=10000] span[hosts=1]" \
    "for file in \\\$(cat $DIR/batches/${list}); do \
        id=\\\$(basename \\\${file%.fa.gz}); \
        echo \\\${id} \\\$(zcat \\\$file | sed '/^>/d' | tr -d '\n' | wc -c) >> $DIR/num_bp.txt; \
    done";
done

METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_release/metagraph;

for N in {0..39}; do
    N=$(printf "%02d" $N);
    list=x$N;
    bsub -J "annotate_genomes_${list}" \
         -w "build_graph_genomes" \
         -oo ${DIR}/logs/annotate_${list}.lsf \
         -W 4:00 \
         -n 18 -R "rusage[mem=15000] span[hosts=1]" \
        "cat $DIR/batches/${list} \
            | /usr/bin/time -v $METAGRAPH annotate \
                -i $DIR/graph.dbg \
                --anno-filename \
                --separately \
                --coordinates \
                -o ${DIR}/columns \
                -p 4 \
                --threads-each 9"; \
done

DIR=~/metagenome/data/tara/genome_coord;
mkdir $DIR/rd;
mkdir $DIR/rd/rd_columns;
ln -s $DIR/graph.dbg ${DIR}/rd/graph.dbg;

METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_release/metagraph;
DIR=~/metagenome/data/tara/genome_coord;
bsub -J "genomes_rd_0" \
     -w "annotate_genomes_*" \
     -o ${DIR}/logs/rd_0.lsf \
     -W 24:00 \
     -n 36 -R "rusage[mem=19000] span[hosts=1]" \
    "find ${DIR}/columns/ -name \"*.column.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 0 \
            --coordinates \
            --mem-cap-gb 600 \
            --disk-swap \\\"\\\" \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/rd/rd_columns/out \
            -p 72";

DIR=~/metagenome/data/tara/genome_coord;
bsub -J "genomes_rd_1" \
     -w "genomes_rd_0" \
     -o ${DIR}/logs/rd_1.lsf \
     -W 24:00 \
     -n 36 -R "rusage[mem=19000] span[hosts=1]" \
    "find ${DIR}/columns/ -name \"*.column.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno \
            --anno-type row_diff \
            --row-diff-stage 1 \
            --coordinates \
            --mem-cap-gb 300 \
            --disk-swap \\\"\\\" \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/rd/rd_columns/out \
            -p 72";

DIR=~/metagenome/data/tara/genome_coord;
bsub -J "genomes_rd_2" \
     -w "genomes_rd_1" \
     -oo ${DIR}/logs/rd_2.lsf \
     -W 24:00 \
     -n 36 -R "rusage[mem=19000] span[hosts=1]" \
    "find ${DIR}/columns/ -name \"*.column.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno \
            --anno-type row_diff \
            --row-diff-stage 2 \
            --coordinates \
            --mem-cap-gb 300 \
            --disk-swap \\\"\\\" \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/rd/rd_columns/out \
            -p 72";

DIR=~/metagenome/data/tara/genome_coord;
bsub -J "genomes_rd_brwt_coord" \
     -w "genomes_rd_2" \
     -oo ${DIR}/logs/rd_brwt_coord.lsf \
     -W 24:00 \
     -n 36 -R "rusage[mem=19000] span[hosts=1]" \
    "find ${DIR}/rd/rd_columns/ -name \"*.column.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_brwt_coord \
            --greedy --subsample 1000000 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation \
            -p 72 --parallel-nodes 10";

DIR=~/metagenome/data/tara/genome_coord;
bsub -J "genomes_rd_brwt_coord_relax" \
     -w "genomes_rd_brwt_coord" \
     -oo ${DIR}/logs/rd_brwt_coord_relax.lsf \
     -W 24:00 \
     -n 12 -R "rusage[mem=10000] span[hosts=1]" \
    "/usr/bin/time -v $METAGRAPH relax_brwt -v \
            -p 24 \
            --relax-arity 32 \
            -o ${DIR}/annotation.relaxed \
            ${DIR}/annotation.row_diff_brwt_coord.annodbg";

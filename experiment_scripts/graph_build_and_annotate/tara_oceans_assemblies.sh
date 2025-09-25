#!/bin/bash

DATA=/cluster/work/grlab/projects/metagenome/raw_data/tara/assemblies-fasta
DIR=~/metagenome/data/tara/assemblies;

mkdir $DIR;
mkdir $DIR/logs;

find $DATA -name "*.gz" > $DIR/list.txt;

METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_release/metagraph;
bsub -J "build_graph_assemblies" \
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

DATA=/cluster/work/grlab/projects/metagenome/raw_data/tara/assemblies-fasta
DIR=~/metagenome/data/tara/assemblies;
mkdir $DIR/columns;
mkdir $DIR/batches;
cd $DIR/batches;
split -d -n r/40 <(find $DATA -name "*.gz" | shuf);

bsub -J "count_bp_assemblies[1-$(cat $DIR/list.txt | wc -l)]" \
     -o /dev/null \
     -W 4:00 \
     -n 1 -R "rusage[mem=10000] span[hosts=1]" \
    "file=\\\$(sed -n \${LSB_JOBINDEX}p $DIR/list.txt); \
    id=\\\$(basename \\\${file%.fasta.gz}); \
    echo \\\${id} \\\$(zcat \\\$file | sed '/^>/d' | tr -d '\n' | wc -c) >> $DIR/num_bp.txt;";

METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_test/metagraph;

for N in {0..39}; do
    N=$(printf "%02d" $N);
    list=x$N;
    bsub -J "annotate_assemblies_${list}" \
         -w "build_graph_assemblies" \
         -oo ${DIR}/logs/annotate_${list}.lsf \
         -W 4:00 \
         -n 18 -R "rusage[mem=15000] span[hosts=1]" \
        "cat $DIR/batches/${list} \
            | /usr/bin/time -v $METAGRAPH annotate \
                -i $DIR/graph.dbg \
                --anno-header \
                --separately \
                --coordinates \
                -o ${DIR}/columns \
                -p 4 \
                --threads-each 9"; \
done

DIR=~/metagenome/data/tara/assemblies;
mkdir $DIR/rd;
mkdir $DIR/rd/rd_columns;
ln -s $DIR/graph.dbg ${DIR}/rd/graph.dbg;

METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_test/metagraph;
DIR=~/metagenome/data/tara/assemblies;
sbatch -J "assemblies_rd_0" \
       -o ${DIR}/logs/rd_0.slog \
       -t 00-72 \
       --cpus-per-task 34 \
       --mem-per-cpu=19G \
    --wrap="find ${DIR}/columns -name \"*.column.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 0 \
            --mem-cap-gb 500 \
            --disk-swap \\\"\\\" \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/rd/rd_columns/out \
            -p 68";

DIR=~/metagenome/data/tara/assemblies;
sbatch -J "assemblies_rd_1" \
       -d afterok:$(get_jobid assemblies_rd_0) \
       -o ${DIR}/logs/rd_1.slog \
       -t 00-72 \
       --cpus-per-task 34 \
       --mem-per-cpu=19G \
    --wrap="find ${DIR}/columns -name \"*.column.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno \
            --anno-type row_diff \
            --row-diff-stage 1 \
            --mem-cap-gb 300 \
            --disk-swap \\\"\\\" \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/rd/rd_columns/out \
            -p 68";

DIR=~/metagenome/data/tara/assemblies;
sbatch -J "assemblies_rd_2" \
       -d afterok:$(get_jobid assemblies_rd_1) \
       -o ${DIR}/logs/rd_2.slog \
       -t 00-24 \
       --cpus-per-task 34 \
       --mem-per-cpu=19G \
    --wrap="find ${DIR}/columns -name \"*.column.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno \
            --anno-type row_diff \
            --row-diff-stage 2 \
            --mem-cap-gb 300 \
            --disk-swap \\\"\\\" \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/rd/rd_columns/out \
            -p 68";

sbatch -J "assemblies_rd_disk" \
     -d afterok:$(get_jobid assemblies_rd_2) \
     -o $DIR/logs/rd_disk.slog \
     -t 0-24 \
     --cpus-per-task 34 \
     --mem-per-cpu=19G \
     --partition=compute,gpu \
     --wrap="find $DIR/rd/rd_columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_disk \
            --mem-cap-gb 220 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation \
            -p 34"

DIR=~/metagenome/data/tara/assemblies;
sbatch -J "assemblies_rd_sparse" \
       -d afterok:$(get_jobid assemblies_rd_2) \
       -o ${DIR}/logs/rd_sparse.slog \
       -t 00-24 \
       --cpus-per-task 36 \
       --mem-per-cpu=19G \
    --wrap="find ${DIR}/rd/rd_columns -name \"*.row_diff.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno \
            --anno-type row_diff_sparse \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation \
            -p 72";

DIR=~/metagenome/data/tara/assemblies;
sbatch -J "assemblies_rd_flat" \
       -d afterok:$(get_jobid assemblies_rd_2) \
       -o ${DIR}/logs/rd_flat.slog \
       -t 00-24 \
       --cpus-per-task 34 \
       --mem-per-cpu=19G \
    --wrap="find ${DIR}/rd/rd_columns -name \"*.row_diff.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_flat \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation \
            -p 68";

DIR=~/metagenome/data/tara/assemblies;
bsub -J "assemblies_rd_brwt" \
     -w "assemblies_rd_2" \
     -oo ${DIR}/logs/rd_brwt.lsf \
     -W 24:00 \
     -n 36 -R "rusage[mem=19000] span[hosts=1]" \
    "find ${DIR}/rd/rd_columns -name \"*.row_diff.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_brwt \
            --greedy --subsample 1000000 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation \
            -p 72 --parallel-nodes 10";

DIR=~/metagenome/data/tara/assemblies;
bsub -J "assemblies_rd_brwt_relax" \
     -w "assemblies_rd_brwt" \
     -oo ${DIR}/logs/rd_brwt_relax.lsf \
     -W 24:00 \
     -n 12 -R "rusage[mem=10000] span[hosts=1]" \
    "/usr/bin/time -v $METAGRAPH relax_brwt -v \
            -p 24 \
            --relax-arity 32 \
            -o ${DIR}/annotation.relaxed \
            ${DIR}/annotation.row_diff_brwt.annodbg";

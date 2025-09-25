#!/bin/bash

rm -rf ~/metagenome/data/cloudcompute/metagut_graphs/build/rd;
mkdir ~/metagenome/data/cloudcompute/metagut_graphs/build/rd;

ln -s ~/metagenome/data/cloudcompute/metagut_graphs/graph_merged_complete_k31.primary.dbg \
      ~/metagenome/data/cloudcompute/metagut_graphs/build/rd/graph.dbg;

cp ~/metagenome/data/cloudcompute/metagut_annotation/files_to_annotate.txt \
   ~/metagenome/data/cloudcompute/metagut_graphs/build/columns.txt
sed -i 's/^.*\///' ~/metagenome/data/cloudcompute/metagut_graphs/build/columns.txt
sed -i 's/^/\/cluster\/home\/mikhaika\/metagenome\/data\/cloudcompute\/metagut_annotation\/columns\//' \
            ~/metagenome/data/cloudcompute/metagut_graphs/build/columns.txt
sed -i 's/$/.column.annodbg/' ~/metagenome/data/cloudcompute/metagut_graphs/build/columns.txt

DIR=~/metagenome/data/cloudcompute/metagut_graphs/nobackup/build;
mkdir ${DIR}/batches;
pushd ${DIR}/batches
cp ../columns.txt ./
split -n r/6 columns.txt
popd

DIR=~/metagenome/data/cloudcompute/metagut_graphs/nobackup/build;
mkdir ${DIR}/rd/rd_columns;
METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_release/metagraph;
cd ${DIR}/batches;
for list in xa*; do
    bsub -J "MetaGut_rd_stage_0_${list}" \
         -oo ${DIR}/logs/rd_stage_0_${list}.lsf \
         -W 72:00 \
         -n 36 -R "rusage[mem=19000] span[hosts=1] select[hname!='le-amd-fp-004']" \
        "cat ${list} \
            | /usr/bin/time -v $METAGRAPH transform_anno -v \
                --anno-type row_diff \
                --row-diff-stage 0 \
                --mem-cap-gb 650 \
                --parallel 72 \
                -o ${DIR}/rd/rd_columns/out \
                -i ${DIR}/rd/graph.dbg \
                2>&1 | tee ${DIR}/logs/rd_stage_0_${list}.log"; \
done

bsub -J "MetaGut_rd_stage_1" \
     -oo ${DIR}/logs/rd_stage_1.lsf \
     -W 72:00 \
     -n 36 -R "rusage[mem=19000] span[hosts=1]" \
    "cat /dev/null \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 1 \
            --mem-cap-gb 650 \
            --parallel 72 \
            -o ${DIR}/rd/rd_columns/out \
            -i ${DIR}/rd/graph.dbg \
            2>&1 | tee ${DIR}/logs/rd_stage_1.log"; \

for list in xa*; do
    bsub -J "MetaGut_rd_stage_1_${list}" \
         -oo ${DIR}/logs/rd_stage_1_${list}.lsf \
         -W 72:00 \
         -n 36 -R "rusage[mem=19000] span[hosts=1] select[hname!='le-amd-fp-004']" \
        "cat ${list} \
            | /usr/bin/time -v $METAGRAPH transform_anno -v \
                --anno-type row_diff \
                --row-diff-stage 1 \
                --mem-cap-gb 500 \
                --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
                --parallel 72 \
                -o ${DIR}/rd/rd_columns/out \
                -i ${DIR}/rd/graph.dbg \
                2>&1 | tee ${DIR}/logs/rd_stage_1_${list}.log"; \
done

bsub -J "MetaGut_rd_stage_2" \
     -oo ${DIR}/logs/rd_stage_2.lsf \
     -W 72:00 \
     -n 36 -R "rusage[mem=19000] span[hosts=1]" \
    "cat /dev/null \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 2 \
            --max-path-length 100 \
            --mem-cap-gb 650 \
            --parallel 72 \
            -o ${DIR}/rd/rd_columns/out \
            -i ${DIR}/rd/graph.dbg \
            2>&1 | tee ${DIR}/logs/rd_stage_2.log"; \

for list in xa*; do
    bsub -J "MetaGut_rd_stage_2_${list}" \
         -w "MetaGut_rd_stage_2" \
         -oo ${DIR}/logs/rd_stage_2_${list}.lsf \
         -W 72:00 \
         -n 36 -R "rusage[mem=19000] span[hosts=1] select[hname!='le-amd-fp-004']" \
        "cat ${list} \
            | /usr/bin/time -v $METAGRAPH transform_anno -v \
                --anno-type row_diff \
                --row-diff-stage 2 \
                --max-path-length 100 \
                --mem-cap-gb 650 \
                --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
                --parallel 72 \
                -o ${DIR}/rd/rd_columns/out \
                -i ${DIR}/rd/graph.dbg \
                2>&1 | tee ${DIR}/logs/rd_stage_2_${list}.log"; \
done


DIR=~/metagenome/data/cloudcompute/metagut_graphs/nobackup/build;
METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_master/metagraph;
bsub -J "metagut_cluster" \
     -oo ${DIR}/logs/cluster_original.lsf \
     -W 240:00 \
     -n 36 -R "rusage[mem=19000] span[hosts=1]" \
    "cat ${DIR}/columns.txt \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type brwt \
            --linkage --greedy --subsample 50000 \
            -o ${DIR}/cluster_original \
            -p 72 \
            2>&1 | tee ${DIR}/logs/cluster_original.log"

DIR=~/metagenome/data/cloudcompute/metagut_graphs/nobackup/build;
METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_master/metagraph;
for x in $(cat ${DIR}/columns.txt); do
    x=$(basename $x);
    echo $DIR/rd/rd_columns/${x%.column.annodbg}.row_diff.annodbg;
done > ${DIR}/rd_columns_cluster_original.txt
bsub -J "metagut_rd_brwt" \
     -oo ${DIR}/logs/rd_brwt.lsf \
     -W 48:00 \
     -n 48 -R "rusage[mem=40400] span[hosts=1]" \
    "cat ${DIR}/rd_columns_cluster_original.txt \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_brwt \
            --linkage-file ${DIR}/cluster_original \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation \
            -p 96 --parallel-nodes 10 \
            2>&1 | tee ${DIR}/logs/rd_brwt.log"

METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_master/metagraph;
DIR=~/metagenome/data/cloudcompute/metagut_graphs/nobackup/build;
bsub -J "metagut_rd_brwt_relax" \
     -oo ${DIR}/logs/rd_brwt_relax.lsf \
     -W 48:00 \
     -n 18 -R "rusage[mem=78000] span[hosts=1]" \
    "/usr/bin/time -v $METAGRAPH relax_brwt -v \
        -p 36 \
        --relax-arity 32 \
        -o ${DIR}/annotation.relaxed \
        ${DIR}/annotation.row_diff_brwt.annodbg \
        2>&1 | tee ${DIR}/logs/rd_brwt_relax.log"

METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_test/metagraph;
DIR=~/metagenome/data/cloudcompute/metagut_graphs/nobackup/build;
sbatch -J "metagut_rd_disk" \
     -o $DIR/logs/rd_disk.slog \
     -t 00-120 \
     --cpus-per-task 56 \
     --mem-per-cpu=15G \
    --wrap="find ${DIR}/rd/rd_columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_disk \
            --mem-cap-gb 800 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation \
            -p 56"

METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_test/metagraph;
DIR=~/metagenome/data/cloudcompute/metagut_graphs/nobackup/build;
sbatch -J "metagut_rd_disk_big" \
     -o $DIR/logs/rd_disk_big.slog \
     -t 00-120 \
     --cpus-per-task 70 \
     --mem-per-cpu=20G \
    --wrap="find ${DIR}/rd/rd_columns/ -name \"*.annodbg\" \
        | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_disk \
            --mem-cap-gb 1200 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/annotation_big \
            -p 70"

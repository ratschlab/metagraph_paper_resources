#!/bin/bash

DIR=~/metagenome/data/cloudcompute/homo_sapiens_graphs/build/nobackup;

rm -rf ${DIR}/rd;
mkdir ${DIR}/rd;

ln -s ~/metagenome/data/cloudcompute/homo_sapiens_graphs/graph_merged_complete_k31.primary.dbg \
      ${DIR}/rd/graph.dbg;

cp ~/metagenome/data/cloudcompute/homo_sapiens_annotation/files_to_annotate.txt \
   ${DIR}/columns.txt
sed -i 's/^.*\///' ${DIR}/columns.txt
sed -i 's/^/\/cluster\/home\/mikhaika\/metagenome\/data\/cloudcompute\/homo_sapiens_annotation\/columns\//' \
            ${DIR}/columns.txt
sed -i 's/$/.column.annodbg/' ${DIR}/columns.txt


mkdir ${DIR}/batches;
pushd ${DIR}/batches
cp ../columns.txt ./
split -l -n r/60 columns.txt
popd

mkdir ${DIR}/rd/rd_columns

METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_release/metagraph

for B in {64..79..4}; do
    dep_cond="";
    for N in `seq $B $((B+3))`; do
        N=$(printf "%02d" $N);
        CHUNK=x$N;
        JOBID=$(bsub -J "human_rd_stage_0_$CHUNK" \
                 -oo ${DIR}/logs/human_rd_stage_0_$CHUNK.lsf \
                 -w "${dep_cond:4}" \
                 -W 48:00 \
                 -n 36 -R "rusage[mem=13000] span[hosts=1] select[hname!='le-amd-fp-004']" \
                "cat ${DIR}/batches/$CHUNK | /usr/bin/time -v $METAGRAPH transform_anno -v \
                    --anno-type row_diff \
                    --row-diff-stage 0 \
                    -i ${DIR}/rd/graph.dbg \
                    -o ${DIR}/rd/rd_columns/vector_${B}.row_count \
                    --mem-cap-gb 450 \
                    -p 72 \
                    2>&1 | tee ${DIR}/logs/human_rd_stage_0_$CHUNK.log" \
            | awk '/is submitted/{print substr($2, 2, length($2)-2);}');
        dep_cond+=" && $JOBID";
    done
done

bsub -J "human_rd_stage_1" \
     -oo ${DIR}/logs/human_rd_stage_1.lsf \
     -w "1322561 && 1322569 && 1322577 && 1322585 && 1322593 && 1322601 && 1322609 && 1322617 && 1322641 && 1322645 && 1322649 && 1322653 && 1322562 && 1322563 && 1322564 && 1322565 && 1322566 && 1322567 && 1322568 && 1322570 && 1322571 && 1322572 && 1322573 && 1322574 && 1322575 && 1322576 && 1322578 && 1322579 && 1322580 && 1322581 && 1322582 && 1322583 && 1322584 && 1322586 && 1322587 && 1322588 && 1322589 && 1322590 && 1322591 && 1322592 && 1322594 && 1322595 && 1322596 && 1322597 && 1322598 && 1322599 && 1322600 && 1322602 && 1322603 && 1322604 && 1322605 && 1322606 && 1322607 && 1322608 && 1322610 && 1322611 && 1322612 && 1322613 && 1322614 && 1322615 && 1322616 && 1322618 && 1322619 && 1322620 && 1322621 && 1322622 && 1322623 && 1322624 && 1322642 && 1322643 && 1322644 && 1322646 && 1322647 && 1322648 && 1322650 && 1322651 && 1322652 && 1322654 && 1322655 && 1322656" \
     -W 120:00 \
     -n 36 -R "rusage[mem=19000] span[hosts=1] select[hname!='le-amd-fp-004']" \
    "cat /dev/null | /usr/bin/time -v $METAGRAPH transform_anno -v \
        --anno-type row_diff \
        --row-diff-stage 1 \
        -i ${DIR}/rd/graph.dbg \
        -o ${DIR}/rd/rd_columns/vectors \
        --mem-cap-gb 600 \
        -p 72 \
        2>&1 | tee ${DIR}/logs/human_rd_stage_1.log"


DIR=~/metagenome/data/cloudcompute/homo_sapiens_graphs/build/nobackup;
METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_release/metagraph
rm ${DIR}/rd/rd_columns/*.row_count

# 4, 48:00, mem=13400, 335
# 8, 48:00, mem=19000, 475
# 8, 48:00, mem=20000, 500
# 6, 48:00, mem=20000, 450

for B in {64..79..4}; do
    dep_cond="";
    for N in `seq $B $((B+3))`; do
        N=$(printf "%02d" $N);
        CHUNK=x$N;
        JOBID=$(bsub -J "human_rd_stage_1_$CHUNK" \
                 -oo ${DIR}/logs/human_rd_stage_1_$CHUNK.lsf \
                 -w "${dep_cond:4}" \
                 -W 48:00 \
                 -n 36 -R "rusage[mem=19400] span[hosts=1] select[hname!='le-amd-fp-004']" \
                "cat ${DIR}/batches/$CHUNK | /usr/bin/time -v $METAGRAPH transform_anno -v \
                    --anno-type row_diff \
                    --row-diff-stage 1 \
                    -i ${DIR}/rd/graph.dbg \
                    -o ${DIR}/rd/rd_columns/vector_${B}.row_reduction \
                    --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
                    --mem-cap-gb 500 \
                    -p 72 \
                    2>&1 | tee ${DIR}/logs/human_rd_stage_1_$CHUNK.log" \
            | awk '/is submitted/{print substr($2, 2, length($2)-2);}');
        dep_cond+=" && $JOBID";
    done
done


DIR=~/metagenome/data/cloudcompute/homo_sapiens_graphs/build/nobackup;
METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_release/metagraph
bsub -J "human_rd_stage_2" \
     -oo ${DIR}/logs/human_rd_stage_2.lsf \
     -W 120:00 \
     -n 36 -R "rusage[mem=19400] span[hosts=1]" \
        "cat /dev/null | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 2 \
            --max-path-length 100 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/rd/rd_columns/out \
            --mem-cap-gb 650 \
            -p 72 \
            2>&1 | tee ${DIR}/logs/human_rd_stage_2.log"


for N in {0..79}; do
    N=$(printf "%02d" $N);
    CHUNK=x$N;
    bsub -J "human_rd_stage_2_$CHUNK" \
         -oo ${DIR}/logs/human_rd_stage_2_$CHUNK.lsf \
         -W 24:00 \
         -n 36 -R "rusage[mem=13000] span[hosts=1]" \
        "cat ${DIR}/batches/$CHUNK | /usr/bin/time -v $METAGRAPH transform_anno -v \
            --anno-type row_diff \
            --row-diff-stage 2 \
            --max-path-length 100 \
            -i ${DIR}/rd/graph.dbg \
            -o ${DIR}/rd/rd_columns/out \
            --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
            --mem-cap-gb 450 \
            -p 72 \
            2>&1 | tee ${DIR}/logs/human_rd_stage_2_$CHUNK.log";
done

DIR=~/metagenome/data/cloudcompute/homo_sapiens_graphs/build/nobackup;
L=~/metagenome/data/taxonomy/linkage/homo_sapiens/redo/split_rd;
for G in {0..10}; do
    cp $L/group_$G $DIR/;
    sed -i 's/^/\/cluster\/work\/grlab\/projects\/metagenome\/data\/cloudcompute\/homo_sapiens_graphs\/build\/nobackup\/rd\/rd_columns\//' $DIR/group_$G;
    sed -i 's/$/.fasta.gz.row_diff.annodbg/' $DIR/group_$G;
done

DIR=~/metagenome/data/cloudcompute/homo_sapiens_graphs/build/nobackup;
METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_master/metagraph;
L=~/metagenome/data/taxonomy/linkage/homo_sapiens/redo/split_rd;
for G in {0,1}; do
    cp $L/group_$G.linkage ${DIR}/;
    bsub -J "homo_sapiens_rd_brwt_$G" \
         -oo ${DIR}/logs/rd_brwt_$G.lsf \
         -W 24:00 \
         -n 36 -R "rusage[mem=19000] span[hosts=1]" \
        "cat $DIR/group_$G \
            | /usr/bin/time -v $METAGRAPH transform_anno -v \
                --anno-type row_diff_brwt \
                --linkage-file $DIR/group_$G.linkage \
                -i ${DIR}/rd/graph.dbg \
                -o ${DIR}/annotation_$G \
                --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
                -p 72 --parallel-nodes 10 \
                2>&1 | tee ${DIR}/logs/rd_brwt_$G.log"
done

DIR=~/metagenome/data/cloudcompute/homo_sapiens_graphs/build/nobackup;
METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_master/metagraph;
for G in {5..10}; do
    bsub -J "homo_sapiens_rd_brwt_$G" \
         -oo ${DIR}/logs/rd_brwt_$G.lsf \
         -W 48:00 \
         -n 36 -R "rusage[mem=19000] span[hosts=1]" \
        "cat $DIR/group_$G \
            | /usr/bin/time -v $METAGRAPH transform_anno -v \
                --anno-type row_diff_brwt \
                --greedy --subsample 10000000 \
                -i ${DIR}/rd/graph.dbg \
                -o ${DIR}/annotation_$G \
                --disk-swap ~/metagenome/scratch/nobackup/stripe_1 \
                -p 72 --parallel-nodes 10 \
                2>&1 | tee ${DIR}/logs/rd_brwt_$G.log"
done

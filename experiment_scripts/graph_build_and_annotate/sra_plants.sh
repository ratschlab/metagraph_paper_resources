#!/bin/bash

DIR=~/metagenome/data/cloudcompute/viridiplantae_graphs;
METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_master/metagraph;
bsub -J "plants_primary" \
     -oo ${DIR}/build_primary_new.lsf \
     -W 120:00 \
     -n 36 -R "rusage[mem=19000] span[hosts=1] select[model==XeonE7_8867v3]" \
    "gtime -v $METAGRAPH build -v \
            -k 31 \
            --mode primary \
            -o $DIR/graph_primary_new \
            $DIR/primary_contigs_k31.fasta.gz \
            --disk-swap ~/metagenome/scratch/nobackup/ \
            --mem-cap-gb 100 \
            --disk-cap-gb 20000 \
            -p 36 \
            2>&1 | tee ${DIR}/build_primary_new.log";


ln -s ~/metagenome/data/cloudcompute/viridiplantae_graphs/graph_primary.dbg \
      ~/metagenome/data/cloudcompute/viridiplantae_annotation/rd/graph_primary.dbg
mkdir ~/metagenome/data/cloudcompute/viridiplantae_annotation/rd/rd_columns

METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_master/metagraph;
DIR=~/metagenome/data/cloudcompute/viridiplantae_annotation;
cd ${DIR}/rd/batches;
for S in {xac,}; do
    bsub -J "plants_rd_${S}" \
         -oo ${DIR}/rd/transform_to_rd_${S}.lsf \
         -W 120:00 \
         -n 36 -R "rusage[mem=20000] span[hosts=1] select[model==XeonE7_8867v3]" \
        "cat ${DIR}/rd/batches/${S} \
            | gtime -v $METAGRAPH transform_anno -v \
                --anno-type row_diff \
                --max-path-length 100 \
                --mem-cap-gb 650 \
                -i ${DIR}/rd/graph_primary.dbg \
                -o ${DIR}/rd/rd_columns/out \
                -p 72 \
                2>&1 | tee ${DIR}/rd/transform_to_rd_${S}.log";
done


cd ~/metagenome/data/cloudcompute/viridiplantae_annotation/rd/second_run;
sed -i 's/.fasta.gz.column.annodbg//' all_columns.txt
sed -i 's/.fasta.gz.row_diff.annodbg//' rd_transformed.txt
comm -23 all_columns.txt rd_transformed.txt > remaining.txt

sed -i 's/$/.fasta.gz.column.annodbg/' remaining.txt
sed -i 's/^/\/cluster\/home\/mikhaika\/metagenome\/data\/cloudcompute\/viridiplantae_annotation\/columns\//' remaining.txt
cat remaining.txt | shuf > remaining_random.txt
split -n r/6 remaining_random.txt


METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_test/metagraph;
DIR=~/metagenome/data/cloudcompute/viridiplantae_annotation;
cd ${DIR}/rd/second_run;
for S in xa*; do
    bsub -J "plants_rd_${S}" \
         -oo ${DIR}/rd/transform_to_rd_run2_${S}.lsf \
         -W 120:00 \
         -n 36 -R "rusage[mem=19500] span[hosts=1] select[hname!='le-amd-fp-004']" \
        "cat ${DIR}/rd/second_run/${S} \
            | gtime -v $METAGRAPH transform_anno -v \
                --anno-type row_diff \
                --max-path-length 100 \
                --mem-cap-gb 650 \
                -i ${DIR}/rd/graph_primary.dbg \
                -o ${DIR}/rd/rd_columns/out \
                -p 72 \
                2>&1 | tee ${DIR}/rd/transform_to_rd_run2_${S}.log";
done


sed -i 's/$/.fasta.gz.column.annodbg/' all_columns.txt
sed -i 's/^/\/cluster\/home\/mikhaika\/metagenome\/data\/cloudcompute\/viridiplantae_annotation\/columns\//' all_columns.txt
split -n r/12 <(cat all_columns.txt | shuf)

METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_release/metagraph;
DIR=~/metagenome/data/cloudcompute/viridiplantae_annotation/nobackup/build;
mkdir ${DIR}/rd/rd_columns_opt;
cd ${DIR}/rd/rd_columns_opt;
ln -s ../rd_columns/*row_reduction* .;

METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_release/metagraph;
DIR=~/metagenome/data/cloudcompute/viridiplantae_annotation/nobackup/build;
cd ${DIR}/batches/left;
for S in x*; do
    bsub -J "plants_rd_${S}_opt" \
         -oo ${DIR}/logs/transform_to_rd_${S}__opt.lsf \
         -W 24:00 \
         -n 36 -R "rusage[mem=19500] span[hosts=1] select[hname!='le-amd-fp-004']" \
        "cat ${DIR}/batches/left/${S} \
            | gtime -v $METAGRAPH transform_anno -v \
                --anno-type row_diff \
                --max-path-length 100 \
                --mem-cap-gb 650 \
                --optimize \
                -i ${DIR}/rd/graph_primary.dbg \
                -o ${DIR}/rd/rd_columns_opt/out \
                -p 72 \
                2>&1 | tee ${DIR}/logs/transform_to_rd_${S}__opt.log";
done

cp columns.viridiplantae.filtered.txt rd_columns.txt
sed -i 's/$/.fasta.gz.row_diff.annodbg/' rd_columns.txt
sed -i 's/^/\/cluster\/work\/grlab\/projects\/metagenome\/data\/cloudcompute\/viridiplantae_annotation\/nobackup\/build\/rd\/rd_columns_opt\//' \
    rd_columns.txt


bsub -J "plants_rd_brwt_reserve" \
     -oo /dev/null \
     -W 120:00 \
     -n 16 -R "rusage[mem=4000] span[hosts=1] select[hname=='le-fat-001']" \
    "sleep 1000h";
bsub -J "plants_rd_brwt_reserve" \
     -oo /dev/null \
     -W 120:00 \
     -n 48 -R "rusage[mem=4000] span[hosts=1] select[hname=='le-fat-001']" \
    "sleep 1000h";


METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_release/metagraph;
DIR=~/metagenome/data/cloudcompute/viridiplantae_annotation/nobackup/build;
bsub -J "plants_rd_brwt" \
     -oo ${DIR}/logs/build_rd_brwt.lsf \
     -W 48:00 \
     -n 48 -R "rusage[mem=40000] span[hosts=1]" \
    "cat ${DIR}/rd_columns.txt \
        | gtime -v $METAGRAPH transform_anno -v \
            --anno-type row_diff_brwt \
            -i ${DIR}/rd/graph_primary.dbg \
            --linkage-file ${DIR}/columns.viridiplantae.filtered.taxids.linkage.txt \
            -o ${DIR}/annotation \
            -p 96 --parallel-nodes 5 \
            2>&1 | tee ${DIR}/logs/build_rd_brwt.log"


METAGRAPH=~/projects/projects2014-metagenome/metagraph/build_release/metagraph;
DIR=~/metagenome/data/cloudcompute/viridiplantae_annotation/nobackup/build;
bsub -J "plants_rd_brwt_relax" \
     -w "plants_rd_brwt" \
     -oo ${DIR}/logs/build_rd_brwt_relax.lsf \
     -W 48:00 \
     -n 36 -R "rusage[mem=15000] span[hosts=1]" \
    "gtime -v $METAGRAPH relax_brwt -v \
        -p 36 \
        --relax-arity 32 \
        -o ${DIR}/../../annotation.relaxed \
        ${DIR}/../../annotation.row_diff_brwt.annodbg \
        2>&1 | tee ${DIR}/logs/build_rd_brwt_relax.log"


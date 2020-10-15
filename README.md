# MetaGraph resources
This repository contains resources related to the [manuscript](https://www.biorxiv.org/content/10.1101/2020.10.01.322164v1) describing the MetaGraph framework, such as supplemental data tables containing sample metadata, example scripts and interactive notebooks. Please find below a more detailed description of each category under the respective section.

**Disclaimer:** This repository is currently still under construction and more content will be added within the next days. Some of the sections are still incomplete.

## Supplemental Data Tables
All metadata tables of sample cohorts analyzed in the manuscript can be found in the `data_tables` directory. Please note that the data items in this repository utilize the [git-lfs](https://git-lfs.github.com/) framework. You need to install `git-lfs` on your system to be able to download and access the data. The following table summarizes, which table relates to which cohort.

[//]: # (The table styles are currently ignored by GitHub ... https://github.com/github/markup/issues/119)
<table style="width: 100%; table-layout: fixed;">
  <tr >
    <th style="width:40%;">Dataset Description</th>
    <th>File</th>
  </tr>
  <tr>
    <td>Sample metadata for the SRA-Microbe index</td>
    <td style="overflow:scroll;">data_tables/TableS1_SRA_Microbe.tsv.gz</td>
  </tr>
  <tr>
    <td>Sample metadata for the SRA-Fungi index</td>
    <td style="overflow:scroll;">data_tables/TableS2_SRA_Fungi.tsv.gz</td>
  </tr>
  <tr>
    <td>Sample metadata for the SRA-Plant index</td>
    <td style="overflow:scroll;">data_tables/TableS3_SRA_Plant.tsv.gz</td>
  </tr>
  <tr>
    <td>Sample metadata for the SRA-Metazoa index</td>
    <td style="overflow:scroll;">data_tables/TableS4_SRA_Metazoa.tsv.gz</td>
  </tr>
  <tr>
    <td>Sample metadata for the SRA-Metazoa index</td>
    <td style="overflow:scroll;">data_tables/TableS6_MetaSUB.csv.gz</td>
  </tr>
  <tr>
    <td>Sample metadata for the GTEx index</td>
    <td style="overflow:scroll;">data_tables/TableS7_GTEX.txt</td>
  </tr>
  <tr>
    <td>Sample metadata for the TCGA index</td>
    <td style="overflow:scroll;">data_tables/TableS8_TCGA.tsv.gz</td>
  </tr>
  <tr>
    <td>List of E. coli reference genomes used for accuracy experiment</td>
    <td style="overflow:scroll;">data_tables/TableS9_EColi.txt</td>
  </tr>
  <tr>
    <td>Sample metadata for the SRA-Microbe index which was extracted from McCortex logs</td>
    <td style="overflow:scroll;">data_tables/TableS10_SRA_Microbe_McCortex_logs.tsv.gz</td>
  </tr>
  <tr>
    <td>List of SRA IDs in SRA-Microbe with no available metadata</td>
    <td style="overflow:scroll;">data_tables/TableS11_SRA_Microbe_no_logs.tsv</td>
  </tr>
  <tr>
    <td>List of lengths and classifications of differential sequences assembled from the kidney transplant cohorts</td>
    <td style="overflow:scroll;">data_tables/TableS12_Differential_Sequence_stats.tsv</td>
  </tr>
</table>

## Interactive Notebooks
This folder contains Ipython notebooks that can be used as examples to show how to interact with the graph indexes served on local or remote servers. Some of the result panels presented in the MetaGraph manuscript can be reproduced using these notebooks.

## Experiment Scripts
This folder contains the scripts used to run the experiments presented in the MetaGraph manuscript.


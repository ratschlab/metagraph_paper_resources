# MetaGraph resources
This repository contains resources related to the [manuscript](https://www.biorxiv.org/content/10.1101/2020.10.01.322164v1) describing the MetaGraph framework, such as supplemental data tables containing sample metadata, example scripts and interactive notebooks. Please find below a more detailed description of each category under the respective section.

## Supplemental Data Tables
All metadata tables of sample cohorts analyzed in the manuscript can be found in the `data_tables` directory. The following table summarizes, which table relates to which cohort.

[//]: # (The table styles are currently ignored by GitHub ... https://github.com/github/markup/issues/119)
<table style="width: 100%; table-layout: fixed;">
  <tr >
    <th style="width:40%;">Dataset Description</th>
    <th>File</th>
  </tr>
  <tr>
    <td>Sample metadata for the SRA-Microbe index</td>
    <td style="overflow:scroll;">data_tables/microbe_from_bigsi_*.tsv*</td>
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
</table>

## Interactive Notebooks
This folder contains Ipython notebooks that can be used as examples to show how to interact with the graph indexes served on local or remote servers. Some of the result panels presented in the MetaGraph manuscript can be reproduced using these notebooks. 

## Experiment Scripts
This folder contains the scripts used to run the experiments presented in the MetaGraph manuscript.

**Disclaimer:** This repository is currently still under construction and more content will be added within the next days. Some of the sections are still incomplete.

Here is the JSON template with list of parameters provided to facilitate easy implementation by users according to their library design requirements. Each parameter in quotes should be followed by a colon and then replaced with the actual values for "data-type":

 ```
  "MPRAmatch.read_a": "File",
  "MPRAmatch.read_b": "File", 
  "MPRAmatch.reference_fasta": "File", 
  "MPRAmatch.read_b_number": "Integer", 
  "MPRAmatch.read_len": "Integer", 
  "MPRAmatch.seq_min": "Integer", 
  "MPRAmatch.enh_min": "Integer", 
  "MPRAmatch.enh_max": "Integer", 
  "MPRAmatch.barcode_link": "String",
  "MPRAmatch.oligo_link": "String", 
  "MPRAmatch.end_oligo_link": "String",
  "MPRAmatch.working_directory": "/path/to/MPRASuite/MPRAmatch/scripts", 
  "MPRAmatch.out_directory": "String", 
  "MPRAmatch.id_out": "String"

##Use this parameter only for saturation mutagenesis library
**"MPRAmatch.attributes": "File"

```
<br>

* **MPRAmatch.read_a**: Path to read1 fastq file
* **MPRAmatch.read_b**: Path to read2 fastq file
* **MPRAmatch.reference_fasta**: Path to reference fastq file
* **MPRAmatch.read_b_number**: default: 2
* **MPRAmatch.read_len**: default: 250 ; Maximum length (in bp) of reads to be flashed 
* **MPRAmatch.seq_min**: default: 100 ; Minimum sequence length to pull for barcode
* **MPRAmatch.enh_min**: default: 50 ; Minimum enhancer length to pull
* **MPRAmatch.enh_max**: default: 210 ; Maximum enhancer length to pull 
* **MPRAmatch.barcode_link**: default: "TCTAGA" ; 6 bases at the barcode end of the sequence linking the barcode and oligo 
* **MPRAmatch.oligo_link**: default: "AGTG" ; 4 bases at the oligo end of the sequence linking the barcode and oligo 
* **MPRAmatch.end_oligo_link**: default: "CGTC" ; 4 bases indicating the oligo is no longer being sequenced 
* **MPRAmatch.working_directory"** Path to the MPRAmatch scripts folder
* **MPRAmatch.out_directory**: Path to the output directory for MPRAmatch
* **MPRAmatch.id_out**: Project ID or library name

The JSON file used in the pipeline currently applies default values for all the listed parameters. If your library preparation involves different settings, please update the parameters accordingly and manually provide the JSON file in the config file. (Please refer to the MPRAmatch README section 4b)

**The default JSON file template includes all parameters except for `MPRAmatch.attributes`, which should be provided only if the user is analyzing a saturation mutagenesis library. 
(Saturation Mutagenesis in Massively Parallel Reporter Assay (MPRA) analysis is a powerful technique used to study the functional impact of every possible single nucleotide variant (SNV) within a given DNA sequence. This method allows researchers to systematically and comprehensively interrogate the regulatory elements of the genome, such as promoters, enhancers, and other non-coding regions, to understand how genetic variations affect gene expression.)




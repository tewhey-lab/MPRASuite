Here is the list of parameters provided in the JSON file to facilitate easy implementation by users according to the library design requirements:

  "MPRAmatch.read_a": "File", [Path to read1 fastq file]
  "MPRAmatch.read_b": "File", [Path to read2 fastq file]
  "MPRAmatch.reference_fasta": "File", [Path to reference fastq file]
  "MPRAmatch.read_b_number": "Integer", [default: 2]
  "MPRAmatch.read_len": "Integer", [default: 250 ; Maximum length (in bp) of reads to be flashed ]
  "MPRAmatch.seq_min": "Integer", [default: 100 ; Minimum sequence length to pull for barcode ]
  "MPRAmatch.enh_min": "Integer", [default: 50 ; Minimum enhancer length to pull ]
  "MPRAmatch.enh_max": "Integer", [default: 210 ; Maximum enhancer length to pull ]
  "MPRAmatch.barcode_link": "String", [default: "TCTAGA" ; 6 bases at the barcode end of the sequence linking the barcode and oligo ]
  "MPRAmatch.oligo_link": "String", [efault: "AGTG" ; 4 bases at the oligo end of the sequence linking the barcode and oligo ]
  "MPRAmatch.end_oligo_link": "String", [default: "CGTC" ; 4 bases indicating the oligo is no longer being sequenced ]
  "MPRAmatch.working_directory": "/path/to/MPRASuite/MPRAmatch/scripts", [Path to the MPRAmatch scripts folder]
  "MPRAmatch.out_directory": "String", [Path to the output directory for MPRAmatch]
  "MPRAmatch.id_out": "String", [Project ID or library name]
**"MPRAmatch.attributes": "File"; [Path to attributes file ]


The JSON file used in the pipeline currently applies default values for all the listed parameters. If your library preparation involves different settings, please update the parameters accordingly and manually provide the JSON file in the config file. (Please refer to the MPRAmatch README section 4b)

**The default JSON file template includes all parameters except for `MPRAmatch.attributes`, which should be provided only if the user is analyzing a saturation mutagenesis library. 
(Saturation Mutagenesis in Massively Parallel Reporter Assay (MPRA) analysis is a powerful technique used to study the functional impact of every possible single nucleotide variant (SNV) within a given DNA sequence. This method allows researchers to systematically and comprehensively interrogate the regulatory elements of the genome, such as promoters, enhancers, and other non-coding regions, to understand how genetic variations affect gene expression.)




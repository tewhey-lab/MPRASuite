### A guide to output files for `MPRAcount`

  - `*.match`
    1. Sequence ID
    2. Found Barcode
    3. (matching oligo)


  - `*.tag`
    1. Barcode
    2. Total Seen
    3. Tag Flag
      -  0: Barcode found in parsed file and no issue mapping
      - -9: Barcode not found in parsed file
      - -1: Barcode found in parsed file, collision accepted
      - -4: Barcode found in parsed file, collision not accepted
      - -5: Barcode found in parsed file, mapping failed
      - -6: Barcode found in parsed file, mapped reverse complement
    4. Oligo ID (from parsed)
    5. Mapping Flag (from parsed; `-` if barcode not found in dictionary)
    6. Barcode
    7. error (from parsed)
    8. CIGAR (from parsed)
    9. MD/cs tag (from parsed)
    10. start/stop (from parsed)


  - `.stats`
    1. replicate ID
    2. good barcodes (mapping flag == 0)
    3. good reads (mapping flag == 0)
    4. total matched reads (mapping flag in [0,1,2])
    5. percent (good reads)/(total matched reads)
    6. all barcodes (mapping flag in [-,0,1,2])
    7. all reads (mapping flag in [-,0,1,2])
    8. percent (good reads)/(all reads)


  - `_condition.txt`
    1. replicate ID (row names when read into R for `MPRAmodel`)
    2. condition


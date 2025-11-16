#!/usr/bin/perl
use strict;
use warnings;
my $fasta = $ARGV[0];
my $read = $ARGV[1];
my $out = $ARGV[2];
my $link_A_bc = $ARGV[3]; #Any length, we use 6 bases
my $link_A_oligo = $ARGV[4]; #4 bases
my $end_A_oligo = $ARGV[5]; #4 bases
my $MIN_SEQ_SIZE = $ARGV[6];
my $MIN_ENH_SIZE = $ARGV[7];
my $MAX_ENH_SIZE = $ARGV[8];
my $bc_len = $ARGV[9];
my $link_A_size = $ARGV[10];
my $link_end_size = $ARGV[11];
my $bc_offset = defined($ARGV[12]) ? ($ARGV[12] - 1) : 0; # NEW: Barcode start offset (defaults to 0)

open (FASTA, "$fasta") or die("ERROR: can not read file ($fasta): $!\n");
open (MATCH, ">$out".".match") or die("ERROR: can not create $out .matched: $!\n");
open (REJECT, ">$out".".reject") or die("ERROR: can not create $out .rejected: $!\n");

my $barcode_seq;
my $barcode_start;
my $id;
my $r1;
my $revcomp;
my $revcomp_barcode;
my $link_index=$bc_len + $bc_offset;
my $oligo_start;
my $oligo_end;
my $oligo_length;
my $oligo_seq;
my $revcomp_oligo;
my $link_A_adj = $link_A_size - 8;
my $link_end_adj = $link_end_size - 18;

if($link_end_adj < 0){
  $link_end_adj = $link_end_size + 2;
}

while (<FASTA>){
# Extract Sequence ID
  chomp;
  $id = $_;
  $id =~ s/^@/>/;
  $id =~ s/^>//;
  $id =~ s/\/1$//;
  
# Extract the sequence
  $r1 = <FASTA>;
  chomp $r1;
  
  if(length($r1) < $MIN_SEQ_SIZE){
    next;
  }
  
# If the flashed file placed read 1 second, take the reverse complement
  if($read == 1){
    $revcomp = reverse($r1);
  	$revcomp =~ tr/ACGTNacgtn/TGCANtgcan/;
    $r1 = $revcomp;
  }
  
# Check for the barcode linker start at bc_offset + bc_len and look in the next 10 bases for the linking sequence.
# This accounts for possible deletions or insertions.
  my $search_start = $bc_offset + $bc_len - 2;
  if(index(substr($r1, $search_start, 10), $link_A_bc) != -1){
    $link_index = index(substr($r1, $search_start, 10), $link_A_bc);
    $link_index += $search_start;
  }
  
# If the linker is not present then reject the sequence.
  if(index(substr($r1, $search_start, 10), $link_A_bc) == -1){
    if($id ne "+"){
      print REJECT "$id\t Linker Sequence Not Found\n";
    }
    next;
  }
  
# Extract barcode starting from bc_offset position
# The barcode should be bc_len bases long, starting at bc_offset
  if($link_index - $bc_len - $bc_offset <= 0){
    $barcode_start = $bc_offset;
    $barcode_seq = substr($r1, $barcode_start, $bc_len);
  }
# If the linker is found later than expected, adjust barcode position accordingly
  else{
    $barcode_start = $link_index - $bc_len;
    $barcode_seq = substr($r1, $barcode_start, $bc_len);
  }
  
# Look for the oligo end of the linker sequence starting from where the barcode linker was found
  $oligo_start = index(substr($r1, $link_index+$link_A_adj, 12), $link_A_oligo);
  
# If the oligo end of the linker sequence is not found then set it to zero, essentially making an arbitrary cut to start the oligo
  if($oligo_start == -1){
    $oligo_start = 0;
    $oligo_start = $-[0] if substr($r1, $link_index+$link_A_adj, 12) =~ /A[ACTG][ACTG]G/;
  }
  
# Add link_A_adj + 4 to the oligo start to put the start of the oligo at the end of the oligo linker sequence
  $oligo_start += $link_A_adj+4+$link_index;
  
# Find the end of the oligo with respect to the end of the sequence
  $oligo_end = index(substr($r1, -$link_end_adj, 8), $end_A_oligo);
  if($oligo_end == -1){
    $oligo_end = 2;
    if($link_end_size == 0){
      $oligo_end = 2;
    }
  }
  $oligo_end += -$link_end_adj;
  
# Define the substring that is the oligo
  $oligo_length = length($r1) + $oligo_end - $oligo_start;
  $oligo_seq = substr($r1, $oligo_start, $oligo_length);
  $revcomp_oligo = reverse($oligo_seq);
  $revcomp_oligo =~ tr/ACGTNacgtn/TGCANtgcan/;
  $oligo_seq = $revcomp_oligo;
  
# Print to match if it pulled an actual id
  if($id ne "+"){
    if($oligo_length >= $MIN_ENH_SIZE && $oligo_length <= $MAX_ENH_SIZE){
      print MATCH join("\t", $id, $barcode_seq, $oligo_seq, $oligo_length, length($r1)."\n");
    }
    else{
      print REJECT join("\t", $id, "Oligo Outside Length Bounds", $barcode_seq, $oligo_length."\n");
    }
  }
}

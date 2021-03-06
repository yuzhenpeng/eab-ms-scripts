#!/usr/bin/perl
#find_largest_phased_blocks.pl
use strict;
use warnings;
# A program to find the largest phased block for a gene, from phasing results generated with whatshap (https://whatshap.readthedocs.io/en/latest/)
# Requires as input a tab separated file containing contig names for the genes (in 2nd column), the phased block number (3rd column) and a count of the number of variants in that phased block (1st column)
# The input file can be generated by using a combination of Unix tools to extract information (the number, i.e. start position, and size of phased blocks) for genes of interest from the phased vcf file produced by whatshap 
# WARNING! This script works on the assumption that all of the genes of interest are on separate contigs/scaffolds in the genome assembly; the input file should also be sorted on contig name, so that all lines for a given contig/scaffold are consecutive
# WARNING! This script also assumes that the contig/scaffold names in your genome assembly only include alphanumeric characters and underscores; if the format differs then the code below may need to be altered to remove any characters from the "$name_to_match" scalar that may prevent proper pattern matching

# See comments below for further information on how this script works
# Usage: perl find_largest_phased_blocks.pl path_to_input_file

#Declare and initialize variables
my $infile;
my $current_line;
my @current_line_parts= ();
my $array_size=0;
my $name_to_match;
my $contig_name_flag = 0;
my $current_contig_name;
my $current_block_size = 0;
my $new_block_size = 0;
my $current_block_number = 0;

#Take the path to the input file from the first argument provided on the commandline
$infile = $ARGV[0];
chomp $infile;

#Create output file for saving results in, or print an error if file cannot be made
open (OUTFILE, ">>Largest_phased_blocks.txt") or die "Largest_phased_blocks.txt\": $!\n";

#Open input file, or print an error if file cannot be opened
open (INFILE, "<$infile") or die "Could not open file \"$infile\": $!\n";

#Read in input file, one line at a time
while (<INFILE>) {
  	#save a copy of the current line into a scalar
  	$current_line = $_;
 	#remove the newline character from the current line
 	chomp $_;
 	#split current line to separate out elements on tab and add it to an array
 	@current_line_parts = split(/\t/, $_);
 	#save the count of elements in the array into a scalar
 	$array_size=@current_line_parts;
 	
 	#lines relating to unphased variants will have 2 elements in, lines that are for phased blocks will have 3 elements
 	#if the array size is equal to 2 (i.e. from unphased variants), go to next line
 	if ($array_size==2){
 		next;
 	#if the array size is equal to 3, carry out checks for phased block size
 	} elsif ($array_size==3) {
 		#save the name of the contig into a scalar to use for pattern matching
 		$name_to_match = $current_line_parts[1];
 		#if the current contig name scalar is empty, save the name of the contig into another scalar (i.e. should only happen for the first line)
 		if ($contig_name_flag == 0) {
 			$current_contig_name = $current_line_parts[1];
 			#save the size of the current phased block (i.e. number of variants it contains) into a scalar
 			$current_block_size = $current_line_parts[0];
        	#remove any whitespace characters from the scalar
        	$current_block_size =~ s/\s//g;
        	#save the phased block number into a scalar (i.e. the start position of the phased block)
        	$current_block_number = $current_line_parts[2];	
  			#reset the flag to 1, once the current contig name scalar has been set for the first time
  			$contig_name_flag = 1;
 		#otherwise check if the line being checked is for the same contig as the previous line
 		} elsif ($name_to_match =~ m/$current_contig_name/g) {
 		#if it is, see if the size of the phased block in this line is larger than for the previous one
 		#save the block size into a scalar and replace any white space characters
 		$new_block_size = $current_line_parts[0]; 
 		$new_block_size =~ s/\s//g;
 			 if ($new_block_size > $current_block_size){
 			 	#if the new block size is bigger that the previous one, reset the current block size with this value
 			 	$current_block_size = $new_block_size;
 			 	#and reset the value for the current block number
 			 	$current_block_number = $current_line_parts[2];	
 			 }
 	 	#if the line being checked is not for the same contig as the previous line
 	 	#this means that there are no more phased blocks for that contig in the input file, so the results can be output
 		} else {
 			#print results to the file, unless the largest phased block only has 1 variant in
 			unless ($current_block_size == 1) {
 				print OUTFILE "$current_contig_name\t$current_block_number\n";
 			}
 		#reset values for block size and block number with those from the current line
 		$current_block_size = $current_line_parts[0];
 		$current_block_size =~ s/\s//g;
 		#remove any whitespace characters from the block number scalar
 		$current_block_number = $current_line_parts[2];
 		} 	
 	#reset current contig name scalar with the name from the current line before processing next line
 	$current_contig_name = $current_line_parts[1];
 	
 	#otherwise, if some other element size (not 2 or 3) is found, print an error
 	} else {
 		print "ERROR!!! Unexpected array size; check format of the input file\n";
 		next;
 	} 	 	
}

#print values for final contig checked to the output file, unless the largest phased block only has 1 variant in
unless ($current_block_size == 1) {
	print OUTFILE "$current_contig_name\t$current_block_number\n";
}

#Close input file
close INFILE;

#Close output files
close OUTFILE;

#exit the program
exit;
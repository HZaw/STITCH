* v1.2.9
	* Add command line wrapper for STITCH to facilitate running from the command line
	* Reduce RAM when working on large regions of the genome (e.g. chromosomes) by loading raw data 1 Mbp at a time
	* Change examples script to only showcase examples and not installing dependencies
* v1.2.8
	* Change output to bgzipped VCF from gzip. Require bgzip to be in PATH
* v1.2.7
	* Speed up C++ functions by re-orienting internal matrices to better use column-major order
	* Fix potential compilation specific bug requiring specification of C++ header iomanip
	* Fix bug about loading reference haplotypes from X chromosome for male reference samples
	* More tests
* v1.2.6
	* Fix bugs that manifest when the number of SNPs is very small (in the tens)
	* More tests
	* Increase efficiency of code, particularly C++ code
* v1.2.5
	* Require samtools to be in PATH
	* More thorough and better tested input validation
* v1.2.4
	* Enable C++11 compilation
	* Fix bug where sample name from bam header was being grabbed from any line with @RG in it and not specifically lines starting with @RG
* v1.2.3
	* Fix bug where the central SNP in a read was random from SNPs in read and not the central SNP by position among SNPs in the read as it ought to have been
	* Fix bug where the final SNP from posfile wasn't being loaded from the sample BAMs and as a result not being imputed
	* Fix bug where reads split into 3+ pieces were not being properly handled (e.g. long reads where sections map to multiple locations)
	* Faster internal handling of cigar string
* v1.2.2
	* Reduce RAM footprint when loading reference haplotypes
	* Crash early if rsync is not in PATH
	* Added option to override default VCF output name. See vcf_output_name
	* Added unit tests under testthat framework
* v1.2.1
	* Change internal system calls to reduce RAM usage
	* Fix bug passing through variable to subfunction
* v1.2.0
	* Can use reference panels in IMPUTE2 format. See example script and reference_* variables
	* Can bundle together inputs to facilitate imputation of very large N. See inputBundleBlockSize
	* Example human data provided to showcase STITCH functionality. See examples script
* v1.1.4
	* Can work off CRAM files or BAM files. To use CRAM files, see cramlist and reference variables, or see examples script
	* Changed GL as genotype likelihood to GP as genotype posterior probability in output VCF
* v1.1.3
	* Changed R example script to work on provided example data
	* Changed default downsampleToCov to 50 to reduce likelihood of overflow at high coverage SNPs
	* Miscellaneous small fixes to BAM conversion script to better handle samples with very few reads
	* Changed default region where reads from BAM are loaded (chrStart and chrEnd) to NA, to be inferred from posfile and the region to be imputed, rather than to grab reads from the whole chromosome
	* Fixed ability to use high coverage validation samples (genfile) when using generateInputOnly and regenerateInput
* v1.1.2
	* Fixed typo in header of outputted VCF
* v1.1.1
	* Fixed bug where samples with no reads on a chromosome gave an old input format
* v1.1.0
	* Changed default output to VCF (added option outputBlockSize to control how it is written)
        * Removed two package dependencies
        * Remove ability to write output to .gen format (remove outputGenFormat)
        * Add change log to README and miscellaneous other changes
* v1.0.1
	* Added ability to use soft clipped bases
* v1.0.0
	* Version used for paper


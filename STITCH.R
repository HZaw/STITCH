#!/usr/bin/env Rscript

if (!suppressPackageStartupMessages(require("optparse")))
    install.packages("optparse", repos="http://cran.rstudio.com/")

option_list <- list(
    make_option(
        "--chr",
        type = "character",
        help = "What chromosome to run. Should match BAM headers"
    ), 
    make_option(
        "--posfile",
        type = "character",
        help = "Where to find file with positions to run. File is tab seperated with no header, one row per SNP, with col 1 = chromosome, col 2 = physical position (sorted from smallest to largest), col 3 = reference base, col 4 = alternate base. Bases are capitalized. Example first row: 1<tab>1000<tab>A<tab>G<tab>"
    ), 
    make_option(
        "--K",
        type = "integer",
        help = "How many founder / mosaic haplotypes to use"
    ), 
    make_option(
        "--nGen",
        type = "double",
        help = "Number of generations since founding or mixing. Note that the algorithm is relatively robust to this. Use nGen = 4 * Ne / K if unsure"
    ), 
    make_option(
        "--outputdir",
        type = "character",
        help = "What output directory to use"
    ), 
    make_option(
        "--tempdir",
        type = "character",
        help = "What directory to use as temporary directory. If set to NA, use default R tempdir. If possible, use ramdisk, like /dev/shm/ [default NA] ",
        default = NA
    ), 
    make_option(
        "--bamlist",
        type = "character",
        help = "Path to file with bam file locations. File is one row per entry, path to bam files. Bam index files should exist in same directory as for each bam, suffixed either .bam.bai or .bai [default \"\"] ",
        default = ""
    ), 
    make_option(
        "--cramlist",
        type = "character",
        help = "Path to file with cram file locations. File is one row per entry, path to cram files. cram files are converted to bam files on the fly for parsing into STITCH [default \"\"] ",
        default = ""
    ), 
    make_option(
        "--reference",
        type = "character",
        help = "Path to reference fasta used for making cram files. Only required if cramlist is defined [default \"\"] ",
        default = ""
    ), 
    make_option(
        "--genfile",
        type = "character",
        help = "Path to gen file with high coverage results. Empty for no genfile. File has a header row with a name for each sample, matching what is found in the bam file. Each subject is then a tab seperated column, with 0 = hom ref, 1 = het, 2 = hom alt and NA indicating missing genotype, with rows corresponding to rows of the posfile. Note therefore this file has one more row than posfile which has no header [default \"\"] ",
        default = ""
    ), 
    make_option(
        "--method",
        type = "character",
        help = "How to run imputation - either diploid or pseudoHaploid, the former being the original method quadratic in K, the later being linear in K [default diploid] ",
        default = "diploid"
    ), 
    make_option(
        "--outputInputInVCFFormat",
        type = "logical",
        help = "Whether to output the input in vcf format [default FALSE] ",
        default = FALSE
    ), 
    make_option(
        "--downsampleToCov",
        type = "double",
        help = "What coverage to downsample individual sites to. This ensures no floating point errors at sites with really high coverage [default 50] ",
        default = 50
    ), 
    make_option(
        "--downsampleFraction",
        type = "double",
        help = "Downsample BAMs by choosing a fraction of reads to retain. Must be value 0<downsampleFraction<1 [default 1] ",
        default = 1
    ), 
    make_option(
        "--readAware",
        type = "logical",
        help = "Whether to run the algorithm is read aware mode. If false, then reads are split into new reads, one per SNP per read [default TRUE] ",
        default = TRUE
    ), 
    make_option(
        "--chrStart",
        type = "integer",
        help = "When loading from BAM, some start position, before SNPs occur. Default NA will infer this from either regionStart, regionEnd and buffer, or posfile [default NA] ",
        default = NA
    ), 
    make_option(
        "--chrEnd",
        type = "integer",
        help = "When loading from BAM, some end position, after SNPs occur. Default NA will infer this from either regionStart, regionEnd and buffer, or posfile [default NA] ",
        default = NA
    ), 
    make_option(
        "--regionStart",
        type = "integer",
        help = "When running imputation, where to start from. The 1-based position x is kept if regionStart <= x <= regionEnd [default NA] ",
        default = NA
    ), 
    make_option(
        "--regionEnd",
        type = "integer",
        help = "When running imputation, where to stop [default NA] ",
        default = NA
    ), 
    make_option(
        "--buffer",
        type = "integer",
        help = "Buffer of region to perform imputation over. So imputation is run form regionStart-buffer to regionEnd+buffer, and reported for regionStart to regionEnd, including the bases of regionStart and regionEnd [default NA] ",
        default = NA
    ), 
    make_option(
        "--maxDifferenceBetweenReads",
        type = "double",
        help = "How much of a difference to allow the reads to make in the forward backward probability calculation. For example, if P(read | state 1)=1 and P(read | state 2)=1e-6, re-scale so that their ratio is this value. This helps prevent any individual read as having too much of an influence on state changes, helping prevent against influence by false positive SNPs [default 1000] ",
        default = 1000
    ), 
    make_option(
        "--alphaMatThreshold",
        type = "double",
        help = "Minimum (maximum is 1 minus this) state switching into probabilities [default 1e-4] ",
        default = 1e-4
    ), 
    make_option(
        "--emissionThreshold",
        type = "double",
        help = "Emission probability bounds. emissionThreshold < P(alt read | state k) < (1-emissionThreshold) [default 1e-4] ",
        default = 1e-4
    ), 
    make_option(
        "--iSizeUpperLimit",
        type = "double",
        help = "Do not use reads with an insert size of more than this value [default as.integer(600)] ",
        default = as.integer(600)
    ), 
    make_option(
        "--bqFilter",
        type = "double",
        help = "Minimum BQ for a SNP in a read. Also, the algorithm uses bq<=mq, so if mapping quality is less than this, the read isnt used [default as.integer(17)] ",
        default = as.integer(17)
    ), 
    make_option(
        "--niterations",
        type = "integer",
        help = "Number of EM iterations. [default 40] ",
        default = 40
    ), 
    make_option(
        "--shuffleHaplotypeIterations",
        type = "character",
        help = "Iterations on which to perform heuristic attempt to shuffle founder haplotypes for better fit. To disable set to NA. [default c(4,8,12,16)] ",
        default = c(4,8,12,16)
    ), 
    make_option(
        "--splitReadIterations",
        type = "character",
        help = "Iterations to try and split reads which may span recombination breakpoints for a better fit [default 25] ",
        default = 25
    ), 
    make_option(
        "--nCores",
        type = "integer",
        help = "How many cores to use [default 1] ",
        default = 1
    ), 
    make_option(
        "--expRate",
        type = "double",
        help = "Expected recombination rate in cM/Mb [default 0.5] ",
        default = 0.5
    ), 
    make_option(
        "--maxRate",
        type = "double",
        help = "Maximum recomb rate cM/Mb [default 100] ",
        default = 100
    ), 
    make_option(
        "--minRate",
        type = "double",
        help = "Minimum recomb rate cM/Mb [default 0.1] ",
        default = 0.1
    ), 
    make_option(
        "--Jmax",
        type = "integer",
        help = "Maximum number of SNPs on a read [default 1000] ",
        default = 1000
    ), 
    make_option(
        "--regenerateInput",
        type = "logical",
        help = "Whether to regenerate input files [default TRUE] ",
        default = TRUE
    ), 
    make_option(
        "--originalRegionName",
        type = "character",
        help = "If regenerateInput is FALSE (i.e. using existing data), this is the name of the original region name (chr.regionStart.regionEnd). This is necessary to load past variables [default NA] ",
        default = NA
    ), 
    make_option(
        "--keepInterimFiles",
        type = "logical",
        help = "Whether to keep interim parameter estimates [default FALSE] ",
        default = FALSE
    ), 
    make_option(
        "--keepTempDir",
        type = "logical",
        help = "Whether to keep files in temporary directory [default FALSE] ",
        default = FALSE
    ), 
    make_option(
        "--environment",
        type = "character",
        help = "Whether to use server or cluster multicore options [default server] ",
        default = "server"
    ), 
    make_option(
        "--pseudoHaploidModel",
        type = "integer",
        help = "How to model read probabilities in pseudo diploid model (shouldn't be changed) [default 9] ",
        default = 9
    ), 
    make_option(
        "--switchModelIteration",
        type = "integer",
        help = "Whether to switch from pseudoHaploid to diploid and at what iteration (NA for no switching) [default NA] ",
        default = NA
    ), 
    make_option(
        "--generateInputOnly",
        type = "logical",
        help = "Whether to just generate input data then quit [default FALSE] ",
        default = FALSE
    ), 
    make_option(
        "--restartIterations",
        type = "character",
        help = "In pseudoHaploid method, which iterations to look for collapsed haplotype prnobabilities to resolve [default NA] ",
        default = NA
    ), 
    make_option(
        "--refillIterations",
        type = "character",
        help = "When to try and refill some of the less frequently used haplotypes [default c(6, 10, 14, 18)] ",
        default = c(6, 10, 14, 18)
    ), 
    make_option(
        "--downsampleSamples",
        type = "double",
        help = "What fraction of samples to retain. Useful for checking effect of N on imputation. Not meant for general use [default 1] ",
        default = 1
    ), 
    make_option(
        "--downsampleSamplesKeepList",
        type = "character",
        help = "When downsampling samples, specify a numeric list of samples to keep [default NA] ",
        default = NA
    ), 
    make_option(
        "--subsetSNPsfile",
        type = "character",
        help = "If input data has already been made for a region, then subset down to a new set of SNPs, as given by this file. Not meant for general use [default NA] ",
        default = NA
    ), 
    make_option(
        "--useSoftClippedBases",
        type = "logical",
        help = "Whether to use (TRUE) or not use (FALSE) bases in soft clipped portions of reads [default FALSE] ",
        default = FALSE
    ), 
    make_option(
        "--outputBlockSize",
        type = "integer",
        help = "How many samples to write out to disk at the same time when making temporary VCFs that are later pasted together at the end to make the final VCF. Smaller means lower RAM footprint, larger means faster write. [default 1000] ",
        default = 1000
    ), 
    make_option(
        "--inputBundleBlockSize",
        type = "integer",
        help = "If NA, disable bundling of input files. If not NA, bundle together input files in sets of <= inputBundleBlockSize together [default NA] ",
        default = NA
    ), 
    make_option(
        "--reference_haplotype_file",
        type = "character",
        help = "Path to reference haplotype file in IMPUTE format (file with no header and no rownames, one row per SNP, one column per reference haplotype, space separated, values must be 0 or 1) [default \"\"] ",
        default = ""
    ), 
    make_option(
        "--reference_legend_file",
        type = "character",
        help = "Path to reference haplotype legend file in IMPUTE format (file with one row per SNP, and a header including position for the physical position in 1 based coordinates, a0 for the reference allele, and a1 for the alternate allele) [default \"\"] ",
        default = ""
    ), 
    make_option(
        "--reference_sample_file",
        type = "character",
        help = "Path to reference sample file (file with header, one must be POP, corresponding to populations that can be specified using reference_populations) [default \"\"] ",
        default = ""
    ), 
    make_option(
        "--reference_populations",
        type = "character",
        help = "Vector with character populations to include from reference_sample_file e.g. CHB, CHS [default NA] ",
        default = NA
    ), 
    make_option(
        "--reference_phred",
        type = "integer",
        help = "Phred scaled likelihood or an error of reference haplotype. Higher means more confidence in reference haplotype genotypes, lower means less confidence [default 20] ",
        default = 20
    ), 
    make_option(
        "--reference_iterations",
        type = "integer",
        help = "When using reference haplotypes, how many iterations to use to train the starting data [default 10] ",
        default = 10
    ), 
    make_option(
        "--vcf_output_name",
        type = "character",
        help = "Override the default VCF output name with this given file name. Please note that this does not change the names of inputs or outputs (e.g. RData, plots), so if outputdir is unchanged and if multiple STITCH runs are processing on the same region then they may over-write each others inputs and outputs [default NULL] ",
        default = NULL
    ), 
    make_option(
        "--initial_min_hapProb",
        type = "double",
        help = "Initial lower bound for probability read comes from haplotype. Double bounded between 0 and 1 [default 0.4] ",
        default = 0.4
    ), 
    make_option(
        "--initial_max_hapProb",
        type = "double",
        help = "Initial upper bound for probability read comes from haplotype. Double bounded between 0 and 1 [default 0.6] ",
        default = 0.6
    ), 
    make_option(
        "--regenerateInputWithDefaultValues",
        type = "logical",
        help = "If regenerateInput is FALSE and the original input data was made using regionStart, regionEnd and buffer as default values, set this equal to TRUE [default FALSE] ",
        default = FALSE
    ), 
    make_option(
        "--plotHapSumDuringIterations",
        type = "logical",
        help = "Boolean TRUE/FALSE about whether to make a plot that shows the relative number of individuals using each ancestral haplotype in each iteration [default FALSE] ",
        default = FALSE
    ), 
    make_option(
        "--save_sampleReadsInfo",
        type = "logical",
        help = "Experimental. Boolean TRUE/FALSE about whether to save additional information about the reads that were extracted [default FALSE] ",
        default = FALSE
    )
)
opt <- suppressWarnings(parse_args(OptionParser(option_list = option_list)))
suppressPackageStartupMessages(library(STITCH))
Sys.setenv(PATH = paste0(Sys.getenv("PATH"), ":", getwd()))
STITCH(
    chr = opt$chr,
    posfile = opt$posfile,
    K = opt$K,
    nGen = opt$nGen,
    outputdir = opt$outputdir,
    tempdir = opt$tempdir,
    bamlist = opt$bamlist,
    cramlist = opt$cramlist,
    reference = opt$reference,
    genfile = opt$genfile,
    method = opt$method,
    outputInputInVCFFormat = opt$outputInputInVCFFormat,
    downsampleToCov = opt$downsampleToCov,
    downsampleFraction = opt$downsampleFraction,
    readAware = opt$readAware,
    chrStart = opt$chrStart,
    chrEnd = opt$chrEnd,
    regionStart = opt$regionStart,
    regionEnd = opt$regionEnd,
    buffer = opt$buffer,
    maxDifferenceBetweenReads = opt$maxDifferenceBetweenReads,
    alphaMatThreshold = opt$alphaMatThreshold,
    emissionThreshold = opt$emissionThreshold,
    iSizeUpperLimit = opt$iSizeUpperLimit,
    bqFilter = opt$bqFilter,
    niterations = opt$niterations,
    shuffleHaplotypeIterations = eval(parse(text=opt$shuffleHaplotypeIterations)),
    splitReadIterations = eval(parse(text=opt$splitReadIterations)),
    nCores = opt$nCores,
    expRate = opt$expRate,
    maxRate = opt$maxRate,
    minRate = opt$minRate,
    Jmax = opt$Jmax,
    regenerateInput = opt$regenerateInput,
    originalRegionName = opt$originalRegionName,
    keepInterimFiles = opt$keepInterimFiles,
    keepTempDir = opt$keepTempDir,
    environment = opt$environment,
    pseudoHaploidModel = opt$pseudoHaploidModel,
    switchModelIteration = opt$switchModelIteration,
    generateInputOnly = opt$generateInputOnly,
    restartIterations = opt$restartIterations,
    refillIterations = eval(parse(text=opt$refillIterations)),
    downsampleSamples = opt$downsampleSamples,
    downsampleSamplesKeepList = opt$downsampleSamplesKeepList,
    subsetSNPsfile = opt$subsetSNPsfile,
    useSoftClippedBases = opt$useSoftClippedBases,
    outputBlockSize = opt$outputBlockSize,
    inputBundleBlockSize = opt$inputBundleBlockSize,
    reference_haplotype_file = opt$reference_haplotype_file,
    reference_legend_file = opt$reference_legend_file,
    reference_sample_file = opt$reference_sample_file,
    reference_populations = eval(parse(text=opt$reference_populations)),
    reference_phred = opt$reference_phred,
    reference_iterations = opt$reference_iterations,
    vcf_output_name = opt$vcf_output_name,
    initial_min_hapProb = opt$initial_min_hapProb,
    initial_max_hapProb = opt$initial_max_hapProb,
    regenerateInputWithDefaultValues = opt$regenerateInputWithDefaultValues,
    plotHapSumDuringIterations = opt$plotHapSumDuringIterations,
    save_sampleReadsInfo = opt$save_sampleReadsInfo
)

## directory to save results
dir.create("results", showWarnings = FALSE)
resname <- "results/results_tmp.rds"

## parameters for batchtools
# number of cores
CORES <- 4L
# batchtool
registry_name <- "reg_temp"

## forest settings
# number of trees
NumTrees <- 500L

## customization of study
# number of repetitions of each study setting x N x P
REPL <- 1L
# only use subset of problems/DGP? --> remove/add model names from/to following vector
dgps <- c("weibull")
# only use subset of methods? --> remove/add method names from/to following vector
# e.g. "mob","mobhonest", "hybrid", "hybridhonest", "mobcox", "mobcoxhonest", "hybridcox", "hybridcoxhonest", "bm", "bmhybrid"
methods <- c("mob", "hybrid", "mobcox", "hybridcox", "bm", "bmhybrid", "bmcox", "bmhybridcox")
# methods <- c("bm", "bmhybrid", "bmcox", "bmhybridcox")
# specify cox methods 
coxmethods <- c("mobcox", "hybridcox", "bmcox", "bmhybridcox")
# coxmethods <- c("bmcox", "bmhybridcox")
# use older study setting? --> provide path to study results of previous study
oldresdf <- NULL
# oldresdf <- "results/results_study.rds"
# only run subset of studies? --> provide study IDs (based on DGP.R)
StudyIDs <- NULL # e.g. c(1, 2)

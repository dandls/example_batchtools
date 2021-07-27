rm(list = ls())
#----
# 0) Load helper functions & libraries
#----
TEST <- TRUE

# Setup
if (TEST) {
  source("def_test.R")
} else {
  source("def.R")
}
paste(NumTrees, CORES,  REPL, sep = ", ")
source("libs.R")
source("DGP.R")
source("run.R")

#-------
# 1) Setup DGP 
# Result: lookup table resdf
#-------
setups_normal <- create_setups(model = "normal")
setups_binomial <- create_setups(model = "binomial")
setups_polr <- create_setups(model = "polr")
setups_weibull <- create_setups(model = "weibull")

if (is.null(oldresdf)) {

  resdf_normal <- create_args(setups_normal)
  resdf_binomial <- create_args(setups_binomial)
  resdf_polr <- create_args(setups_polr)
  resdf_weibull <- create_args(setups_weibull)

} else {
  ## Code to use older setups (seeds)
    resdf <- readRDS(oldresdf)
    onemethod <- unique(resdf$algorithm)[1]
    resdf <- resdf[resdf$algorithm == onemethod,
      c("setup", "nsim", "dim", "repl", "seed", "model", "p", "m", "t", "sd", "ol")]
    if (REPL < max(resdf$repl)) {
      resdf <- resdf[resdf$repl %in% 1:REPL,]
    }
    resdf_normal <- resdf[resdf$model == "normal"]
    resdf_binomial <- resdf[resdf$model == "binomial"]
    resdf_weibull <- resdf[resdf$model == "weibull"]
    resdf_polr <- resdf[resdf$model == "polr"]
}

if (!is.null(StudyIDs)) {
  resdf_normal <- resdf_normal[resdf_normal$setup %in% StudyIDs, ]
  resdf_binomial <- resdf_binomial[resdf_binomial$setup %in% StudyIDs, ]
  resdf_polr <- resdf_polr[resdf_polr$setup %in% StudyIDs, ]
  resdf_weibull <- resdf_weibull[resdf_weibull$setup %in% StudyIDs, ]
}

message("nrows of resdf_normal is: ", nrow(resdf_normal))


#-----
# 2) Create study environment (TEST/NO TEST)
# Result: experimental registry
#-----
OVERWRITE <- TRUE

# Create registry 
if (file.exists(registry_name)) {
  if (OVERWRITE) {
    unlink(registry_name, recursive = TRUE)
    reg = makeExperimentRegistry(file.dir = registry_name, packages = packages,
      seed = 123L)
  } else {
    reg = loadRegistry(registry_name, writeable = TRUE)
  }
} else {
  reg = makeExperimentRegistry(file.dir = registry_name, packages = packages,
    seed = 123L)
}

# Specifications
reg$default.resources = list(
  ntasks = 1L,
  ncpus = 1L,
  nodes = 1L,
  clusters = "serial")
reg$cluster.functions = makeClusterFunctionsMulticore(CORES)

#----
# 3) Add problem = training dataset based on lookup table resdf
#----
fun_normal = function(job, data, setup, nsim, dim, seed, ...) {
  simulate(setups_normal[[setup]], nsim = nsim, dim = dim, nsimtest = 1000L, seed = seed)
}

fun_binomial = function(job, data, setup, nsim, dim, seed, ...) {
  simulate(setups_binomial[[setup]], nsim = nsim, dim = dim, nsimtest = 1000L, seed = seed)
}

fun_polr = function(job, data, setup, nsim, dim, seed, ...) {
  simulate(setups_polr[[setup]], nsim = nsim, dim = dim, nsimtest = 1000L, seed = seed)
}

fun_weibull = function(job, data, setup, nsim, dim, seed, ...) {
  simulate(setups_weibull[[setup]], nsim = nsim, dim = dim, nsimtest = 1000L, seed = seed)
}

prob.designs <- list()

for (dgp in dgps) {
  addProblem(dgp, fun = eval(parse(text = paste("fun", dgp, sep = "_"))), reg = reg)
  prob.designs[[dgp]] <- eval(parse(text = paste("resdf", dgp, sep = "_")))
}

#-----
# 4) Add algorithms 
# Functions are defined in ../../code/run.R
#-----
algo.designs <- list()
for (method in methods) {
  addAlgorithm(method, fun = eval(parse(text = paste("fun", method, sep = "."))), reg = reg)
  algo.designs[[method]] <- data.frame()
}

#----
# 5) add experiments 
# Run mobcox and hybridcox only on data of Weibull model 
#----
addExperiments(prob.designs, algo.designs = algo.designs[!names(algo.designs) %in% coxmethods], reg = reg)
addExperiments(prob.designs["weibull"], algo.designs = algo.designs[coxmethods])

#----
# 6) check setup 
#----
# check what has been created
summarizeExperiments(reg = reg)
# sets <- unwrap(getJobPars(reg = reg))
# testJob(3L)

#-----
# 7) submit jobs 
#----
submitJobs()
waitForJobs()

#----
# 8) Save results as rds 
#----
res <- ijoin(
  getJobPars(),
  reduceResultsDataTable(fun = function(x) list(res = x))
)
res <- unwrap(res, sep = ".")
names(res) <- stringr::str_remove_all(names(res), "prob.pars.") 

if (!is.null(oldresdf)) {
  resold <- readRDS(oldresdf)
  if (names(resold) == names(res)) res <- rbind(res, resold)
}

saveRDS(res, file = resname)






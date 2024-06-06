args <- commandArgs(trailingOnly = TRUE)
mpramodel_script=args[1]
proj=args[2]
negCtrl=args[3]
postCtrl=args[4]
attr_proj=args[5]
count_proj=args[6]
cond_proj=args[7]
proj_options=args[8]

print(args)

config <- list()
for (arg in args) {
  kv <- strsplit(arg, "=")[[1]]
  key <- kv[1]
  value <- kv[2]
  config[[key]] <- value
}

# Print the configuration to verify
print(config)

# Example of using the configuration parameters
if (!is.null(attr_proj)) {
  message(paste("Attributes File:", attr_proj))
}

if (!is.null(count_proj)) {
  message(paste("MPRAcount Counts File:", count_proj))
}

if (!is.null(cond_proj)) {
  message(paste("MPRAcount Condition File:", cond_proj))
}

if (!is.null(proj_options)) {
  message(paste("MPRAmodel parameter settings are:", "proj_options"))
}

#######

attr_proj <- read.delim(attr_proj, stringsAsFactors=F)

count_proj <- read.delim(count_proj, stringsAsFactors=F)

cond_proj <- read.delim(cond_proj, stringsAsFactors=F, row.names=1, header=F)

colnames(cond_proj) <- "condition"

source(mpramodel_script)

proj_out <- MPRAmodel(count_proj, attr_proj, cond_proj, filePrefix=paste0(proj,prefix, sep=""), negCtrlName=negCtrl, posCtrlName=posCtrl, projectName=proj, "proj_options")

writeLines(capture.output(sessionInfo()), "sessionInfo.txt")


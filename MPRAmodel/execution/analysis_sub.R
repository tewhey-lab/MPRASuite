proj <- "OLJR"
prefix <- ""
negCtrl <- "negCtrl"
posCtrl <- "expCtrl"

attr_proj <- read.delim(paste0("/projects/tewhey-lab/projects/collaborations/Ray_TCell/",proj,"/setup/Tcell_GWAS_ctrl.attributes"), stringsAsFactors=F)
count_proj <- read.delim(paste0("/projects/tewhey-lab/projects/collaborations/autoimmune_mpra/231103-233906_OLJR/outputs/MPRAmatch/231108-094515_OLJR_MPRAcount/OLJR.count"), stringsAsFactors=F)

cond_proj <- read.delim(paste0("/projects/tewhey-lab/projects/collaborations/autoimmune_mpra/231103-233906_OLJR/outputs/MPRAmatch/231108-094515_OLJR_MPRAcount/MPRAmodel/OLJR_condition.txt"), stringsAsFactors=F, row.names=1, header=F)

colnames(cond_proj) <- "condition"

# total_reps <- 4

# cond_FADS <- as.data.frame(c(rep("DNA",total_reps), rep("K562",total_reps)), stringsAsFactors=F)
# colnames(cond_FADS) <- "condition"
# rownames(cond_FADS) <- colnames(count_FADS)[7:ncol(count_FADS)]

source("/projects/tewhey-lab/github/MPRAmodel/MPRAmodel.R")

#setwd("/projects/tewhey-lab/projects/UKBB/OL13/anlaysis_output/")

proj_out <- MPRAmodel(count_proj, attr_proj, cond_proj, filePrefix=paste0(proj,prefix, sep=""), negCtrlName=negCtrl, posCtrlName=posCtrl, projectName=proj, cSkew=F, prior=F, method='ss')

writeLines(capture.output(sessionInfo()), "sessionInfo.txt")


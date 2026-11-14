# From repo root: Rscript dev/data/matched-founders/analyze.R OUTDIR N_SEEDS [MAX_TICKS]
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) %in% c(2L,3L))
out <- args[1L]
n_expected <- as.integer(args[2L])
max_ticks <- if(length(args)==3L) as.integer(args[3L]) else 1000L
stopifnot(n_expected>0L,max_ticks>0L)
d <- read.csv(file.path(out, "runs.csv"), na.strings = "NA")
trace <- read.csv(file.path(out, "trajectories.csv"), na.strings = "NA")
required <- c("exploration", "world", "founder_sd", "mutation_sd", "seed")
stopifnot(all(required %in% names(d)), !anyDuplicated(d[required]),
          all(is.finite(d$initial_diversity)), all(d$initial_diversity >= 0),
          all((d$final_agents < 2) == is.na(d$final_diversity)))
key_values <- function(x) do.call(paste,c(lapply(x[required],as.character),sep="|"))
expected <- expand.grid(exploration=c("fixed","heterozygosity"),world=c("benign","costly"),
  founder_sd=c(0,.05,.2),mutation_sd=c(0,.05,.2),seed=10001:(10000+n_expected),
  stringsAsFactors=FALSE)
run_keys <- key_values(d)
stopifnot(nrow(d)==36L*n_expected,setequal(run_keys,key_values(expected)),
          all(d$final_tick>=1 & d$final_tick<=max_ticks))
snapshots <- sort(unique(c(0,1,2,5,10,20,50,100,200,500,max_ticks)))
snapshots <- snapshots[snapshots<=max_ticks]
expected_trace <- unlist(lapply(seq_len(nrow(d)),function(i)
  paste(run_keys[i],sort(unique(c(snapshots,d$final_tick[i]))),sep="@")),use.names=FALSE)
trace_run_keys <- key_values(trace)
trace_keys <- paste(trace_run_keys,trace$t,sep="@")
stopifnot(!anyDuplicated(trace_keys),setequal(trace_keys,expected_trace))
idx <- match(trace_run_keys,run_keys)
stopifnot(!anyNA(idx),all(is.na(trace$n_agents)==(trace$t>d$final_tick[idx])))
terminal <- trace$t==d$final_tick[idx]
initial <- trace$t==0
stopifnot(all(trace$n_agents[initial]==50),
  isTRUE(all.equal(trace$diversity_exact[initial],d$initial_diversity[idx[initial]])),
  isTRUE(all.equal(trace$n_agents[terminal],d$final_agents[idx[terminal]])),
  isTRUE(all.equal(trace$diversity_exact[terminal],d$final_diversity[idx[terminal]])))
blocks <- interaction(d[c("exploration", "world", "founder_sd", "seed")], drop=TRUE)
stopifnot(all(vapply(split(d$initial_fingerprint, blocks), function(x) length(unique(x))==1L, logical(1))))
stopifnot(all(vapply(split(d$mutation_sd, blocks), function(x) setequal(x,c(0,.05,.2)), logical(1))))
stopifnot(all(d$initial_diversity[d$founder_sd == 0] == 0))
zero <- d$founder_sd==0 & d$mutation_sd==0 & d$final_agents>=2
stopifnot(all(d$final_diversity[zero]==0))

# This function uses only the exact minimum/time and endpoint from each trace.
# Feeding those sufficient statistics gives the same verdict as the full trace.
scope <- new.env(parent=globalenv())
sys.source("R/analysis.R", envir=scope)
d$viability <- vapply(seq_len(nrow(d)), function(i) {
  scope$viability_report(data.frame(t=c(d$tick_of_min[i],d$final_tick[i]),
    n_agents=c(d$min_population[i],d$final_agents[i])), n_agents_init=50L)$verdict
}, character(1))
write.csv(d, file.path(out,"runs_with_viability.csv"), row.names=FALSE, na="NA")

mean_stats <- function(x) {
  x <- x[is.finite(x)]; n <- length(x)
  if (!n) return(c(n=0,mean=NA,mcse=NA,lower=NA,upper=NA))
  avg <- mean(x); se <- if(n>1) sd(x)/sqrt(n) else NA_real_
  half <- if(n>1) qt(.975,n-1)*se else NA_real_
  c(n=n,mean=avg,mcse=se,lower=avg-half,upper=avg+half)
}
prop_stats <- function(x) {
  n <- length(x); k <- sum(x); p <- k/n
  ci <- binom.test(k,n)$conf.int
  c(n=n,count=k,mean=p,mcse=sqrt(p*(1-p)/n),lower=ci[1],upper=ci[2])
}
key <- c("exploration","world","founder_sd","mutation_sd")
groups <- split(seq_len(nrow(d)), interaction(d[key], drop=TRUE))
summary <- do.call(rbind,lapply(groups,function(idx) {
  x <- d[idx,]; base <- x[1,key,drop=FALSE]
  metrics <- list(survival=prop_stats(x$final_agents>0),
    at_least_two=prop_stats(x$final_agents>=2),
    viable=prop_stats(x$viability=="viable"),
    final_agents=mean_stats(x$final_agents),
    final_diversity=mean_stats(x$final_diversity),
    diversity_gain=mean_stats(x$diversity_gain),
    initial_diversity=mean_stats(x$initial_diversity),
    haploid_fraction=mean_stats(x$final_haploid_fraction))
  do.call(rbind,lapply(names(metrics),function(name) {
    stat <- metrics[[name]]
    data.frame(base,metric=name,n=unname(stat["n"]),mean=unname(stat["mean"]),
      mcse=unname(stat["mcse"]),lower=unname(stat["lower"]),upper=unname(stat["upper"]))
  }))
}))
write.csv(summary,file.path(out,"cell_summary.csv"),row.names=FALSE,na="NA")

paired <- list(); counter <- 0L
for (mode in unique(d$exploration)) for (world in unique(d$world))
 for (founder in sort(unique(d$founder_sd))) for (mutation in c(.05,.2)) {
  subset <- d[d$exploration==mode & d$world==world & d$founder_sd==founder,]
  lo <- subset[subset$mutation_sd==0,]; hi <- subset[subset$mutation_sd==mutation,]
  hi <- hi[match(lo$seed,hi$seed),]
  stopifnot(identical(lo$seed,hi$seed),identical(lo$initial_fingerprint,hi$initial_fingerprint))
  eligible <- lo$final_agents>=2 & hi$final_agents>=2
  viable <- lo$viability=="viable" & hi$viability=="viable"
  metrics <- list(survival_difference=as.numeric(hi$final_agents>0)-as.numeric(lo$final_agents>0),
    population_difference=hi$final_agents-lo$final_agents,
    diversity_difference_cosurvivors=hi$final_diversity[eligible]-lo$final_diversity[eligible],
    diversity_difference_both_viable=hi$final_diversity[viable]-lo$final_diversity[viable])
  for (metric in names(metrics)) {
    counter <- counter+1L; stat <- mean_stats(metrics[[metric]])
    paired[[counter]] <- data.frame(exploration=mode,world=world,founder_sd=founder,
      mutation_sd=mutation,reference_mutation=0,metric=metric,total_pairs=nrow(lo),
      n=unname(stat["n"]),mean=unname(stat["mean"]),mcse=unname(stat["mcse"]),
      lower=unname(stat["lower"]),upper=unname(stat["upper"]))
  }
 }
paired <- do.call(rbind,paired)
write.csv(paired,file.path(out,"paired_contrasts.csv"),row.names=FALSE,na="NA")
cat("rows",nrow(d),"cells",length(groups),"matched blocks",nlevels(blocks),"\n")
cat("initial matching: all blocks identical across mutation treatments\n")
cat("zero-founder/zero-mutation control: all measurable endpoints zero\n")
cat("viability counts:\n");print(table(d$exploration,d$world,d$viability))
cat("fixed-exploration cell means:\n")
print(summary[summary$exploration=="fixed" & summary$metric %in% c("survival","final_diversity"),],row.names=FALSE)
cat("paired mutation .2 versus zero:\n")
print(paired[paired$mutation_sd==.2 & paired$metric=="diversity_difference_cosurvivors",],row.names=FALSE)
writeLines(capture.output(sessionInfo()),file.path(out,"R-session-info.txt"))


# Founder-spread effects use the same paired seed blocks, with mutation fixed.
founder_contrasts <- list(); counter <- 0L
for (mode in unique(d$exploration)) for (world in unique(d$world))
 for (mutation in sort(unique(d$mutation_sd))) for (founder in c(.05,.2)) {
  x <- d[d$exploration==mode & d$world==world & d$mutation_sd==mutation,]
  lo <- x[x$founder_sd==0,]; hi <- x[x$founder_sd==founder,]
  hi <- hi[match(lo$seed,hi$seed),]
  eligible <- lo$final_agents>=2 & hi$final_agents>=2
  viable <- lo$viability=="viable" & hi$viability=="viable"
  metrics <- list(survival_difference=as.numeric(hi$final_agents>0)-as.numeric(lo$final_agents>0),
    population_difference=hi$final_agents-lo$final_agents,
    diversity_difference_cosurvivors=hi$final_diversity[eligible]-lo$final_diversity[eligible],
    diversity_difference_both_viable=hi$final_diversity[viable]-lo$final_diversity[viable])
  for (metric in names(metrics)) {
    counter <- counter+1L; stat <- mean_stats(metrics[[metric]])
    founder_contrasts[[counter]] <- data.frame(exploration=mode,world=world,mutation_sd=mutation,
      founder_sd=founder,reference_founder=0,metric=metric,total_pairs=nrow(lo),
      n=unname(stat["n"]),mean=unname(stat["mean"]),mcse=unname(stat["mcse"]),
      lower=unname(stat["lower"]),upper=unname(stat["upper"]))
  }
 }
write.csv(do.call(rbind,founder_contrasts),file.path(out,"founder_contrasts.csv"),row.names=FALSE,na="NA")

# Predeclared 2x2 contrast: change in F=.2 versus F=0 effect as M rises 0 to .2.
interactions <- list(); counter <- 0L
for (mode in unique(d$exploration)) for (world in unique(d$world)) {
  x <- d[d$exploration==mode & d$world==world,]
  cell <- function(f,m) {
    z <- x[x$founder_sd==f & x$mutation_sd==m,]
    z[order(z$seed),]
  }
  a <- cell(0,0); b <- cell(.2,0); c <- cell(0,.2); e <- cell(.2,.2)
  eligible <- a$final_agents>=2 & b$final_agents>=2 & c$final_agents>=2 & e$final_agents>=2
  delta <- (e$final_diversity-c$final_diversity)-(b$final_diversity-a$final_diversity)
  stat <- mean_stats(delta[eligible]); counter <- counter+1L
  interactions[[counter]] <- data.frame(exploration=mode,world=world,total_blocks=nrow(a),
    n=unname(stat["n"]),mean=unname(stat["mean"]),mcse=unname(stat["mcse"]),
    lower=unname(stat["lower"]),upper=unname(stat["upper"]))
}
write.csv(do.call(rbind,interactions),file.path(out,"interaction_contrasts.csv"),row.names=FALSE,na="NA")

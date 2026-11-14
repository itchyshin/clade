# From repo root: Rscript dev/data/behaviour-ploidy/analyze.R OUTDIR N_SEEDS [MAX_TICKS]
a <- commandArgs(trailingOnly=TRUE); stopifnot(length(a)%in%c(2L,3L))
out<-a[1]; ns<-as.integer(a[2]); horizon<-if(length(a)==3)as.integer(a[3]) else 1000L
stopifnot(ns>0,horizon>0)
d<-read.csv(file.path(out,"runs.csv")); x<-read.csv(file.path(out,"assay.csv"))
keys<-c("ploidy","mutation_sd","seed")
key<-function(z)do.call(paste,c(z[keys],sep="|"))
expected<-expand.grid(ploidy=1:2,mutation_sd=c(0,.05,.2),seed=20001:(20000+ns))
stopifnot(nrow(d)==6*ns,!anyDuplicated(key(d)),setequal(key(d),key(expected)),
 all(d$final_tick>=1 & d$final_tick<=horizon),all(d$initial_diversity>0),
 all((d$final_agents<2)==is.na(d$between)),
 all(d$final_haploid_fraction[d$final_agents>0]==as.numeric(d$ploidy[d$final_agents>0]==1)))
for(metric in c("final_diversity","between","within","deterministic_disagreement")) {
 stopifnot(all(is.na(d[[metric]])==(d$final_agents<2)),all(is.finite(d[[metric]][d$final_agents>=2])))
}
stopifnot(all(d$final_agents>=0),all(d$assay_draws>0),all(grepl("^[0-9a-f]{64}$",d$initial_fingerprint)))
blocks<-interaction(d[c("ploidy","seed")],drop=TRUE)
stopifnot(all(vapply(split(d$initial_fingerprint,blocks),function(z)length(unique(z))==1,logical(1))))
i<-match(key(x),key(d)); stopifnot(!anyNA(i),all(x$n==d$final_agents[i]),all(x$draws==d$assay_draws[i]))
trace_keys<-paste(key(x),x$context,sep="@")
expected_keys<-unlist(lapply(which(d$final_agents>=2),function(i)paste(key(d)[i],1:48,sep="@")))
stopifnot(!anyDuplicated(trace_keys),setequal(trace_keys,expected_keys))
A<-as.matrix(x[paste0("a",1:5)]); B<-as.matrix(x[paste0("b",1:5)])
stopifnot(all(A>=0),all(B>=0),all(A==floor(A)),all(B==floor(B)),
 all(rowSums(A)==x$n*x$draws),all(rowSums(B)==x$n*x$draws),
 all(x$cross>=0 & x$cross<=x$n*x$draws^2))
between<-(x$n*x$cross-rowSums(A*B))/(x$n*(x$n-1)*x$draws^2)
within<-1-x$cross/(x$n*x$draws^2)
stopifnot(max(abs(between-x$between))<1e-12,max(abs(within-x$within))<1e-12)
for(metric in c("between","within","deterministic_disagreement")) {
 z<-aggregate(x[[metric]],list(key=key(x)),mean)
 stopifnot(max(abs(z$x-d[[metric]][match(z$key,key(d))]))<1e-12)
}
scope<-new.env(parent=globalenv());sys.source("R/analysis.R",envir=scope)
d$viability<-vapply(seq_len(nrow(d)),function(i)scope$viability_report(
 data.frame(t=c(d$tick_of_min[i],d$final_tick[i]),n_agents=c(d$min_population[i],d$final_agents[i])),n_agents_init=50)$verdict,character(1))
write.csv(d,file.path(out,"runs_with_viability.csv"),row.names=FALSE,na="NA")
stats<-function(z){z<-z[is.finite(z)];n<-length(z);m<-if(n)mean(z) else NA_real_; se<-if(n>1)sd(z)/sqrt(n) else NA_real_;h<-if(n>1)qt(.975,n-1)*se else NA_real_;c(n=n,mean=m,mcse=se,lower=m-h,upper=m+h)}
summary<-list();count<-0
for(p in 1:2)for(m in c(0,.05,.2)) {
 z<-d[d$ploidy==p & d$mutation_sd==m,];v<-z[z$viability=="viable",]
 metrics<-list(survival=as.numeric(z$final_agents>0),viable=as.numeric(z$viability=="viable"),
 final_agents=z$final_agents,genetic_diversity_viable=v$final_diversity,
 between_viable=v$between,within_viable=v$within,
 deterministic_disagreement_viable=v$deterministic_disagreement,
 behavioral_entropy_last100_viable=v$behavioral_entropy_last100)
 for(metric in names(metrics)){count<-count+1; s<-stats(metrics[[metric]]);summary[[count]]<-data.frame(ploidy=p,mutation_sd=m,metric=metric,t(s),row.names=NULL)}
}
write.csv(do.call(rbind,summary),file.path(out,"cell_summary.csv"),row.names=FALSE,na="NA")
pairs<-list();count<-0
for(p in 1:2)for(m in c(.05,.2)) {
 lo<-d[d$ploidy==p & d$mutation_sd==0,];hi<-d[d$ploidy==p & d$mutation_sd==m,];hi<-hi[match(lo$seed,hi$seed),]
 stopifnot(identical(lo$seed,hi$seed),identical(lo$initial_fingerprint,hi$initial_fingerprint))
 eligible<-lo$viability=="viable" & hi$viability=="viable"
 for(metric in c("final_agents","final_diversity","between","within","deterministic_disagreement","behavioral_entropy_last100")) {
  keep<-if(metric=="final_agents")rep(TRUE,nrow(lo)) else eligible
  delta<-hi[[metric]][keep]-lo[[metric]][keep];s<-stats(delta);count<-count+1
  pairs[[count]]<-data.frame(ploidy=p,mutation_sd=m,reference=0,metric=metric,total_pairs=nrow(lo),t(s),
   operational_margin=if(metric=="between") .00625 else NA_real_,
   operationally_meaningful=NA,row.names=NULL)
 }
}
paired<-do.call(rbind,pairs);write.csv(paired,file.path(out,"paired_contrasts.csv"),row.names=FALSE,na="NA")
cat("Complete design:",nrow(d),"runs;",nlevels(blocks),"matched founder blocks;",nrow(x),"assay contexts\n")
cat("Independent recovery of B/W from integer sufficient statistics: passed\n")
print(with(d,table(ploidy,mutation_sd,viability)))
writeLines(capture.output(sessionInfo()),file.path(out,"R-session-info.txt"))
# Threshold flags remain provisional until endpoint-only precision checks pass.
rf<-file.path(out,"reassay.csv")
if(file.exists(rf)) {
 r<-read.csv(rf);stopifnot(!anyDuplicated(key(r)))
 expected_reassay<-d[d$seed<=20000+min(10,ns) & d$final_agents>=2,keys]
 stopifnot(setequal(key(r),key(expected_reassay)))
 stopifnot(all(is.finite(r$between)),all(is.finite(r$within)))
 ri<-match(key(r),key(d));r$original_between<-d$between[ri];r$viability<-d$viability[ri]
 stopifnot(all(r$draws==4*d$assay_draws[ri]))
 r$error<-r$between-r$original_between
 write.csv(r,file.path(out,"reassay_comparison.csv"),row.names=FALSE)
 precision<-list();pc<-0
 classify<-function(s)if(s["lower"]>.00625)"above" else if(s["upper"]<.00625)"below" else "uncertain"
 for(p in 1:2)for(m in c(.05,.2)) {
  z<-r[r$ploidy==p,];lo<-z[z$mutation_sd==0,];hi<-z[z$mutation_sd==m,];hi<-hi[match(lo$seed,hi$seed),]
  keep<-!is.na(hi$seed) & lo$viability=="viable" & hi$viability=="viable"
  original<-hi$original_between[keep]-lo$original_between[keep]
  repeated<-hi$between[keep]-lo$between[keep]
  u<-stats(original);v<-stats(repeated);err<-stats(repeated-original)
  enough<-u["n"]>=5
  agree<-if(enough)classify(u)==classify(v) else FALSE
  precise<-enough && agree && abs(err["mean"])<.00625/4 && err["mcse"]<.00625/4
  pc<-pc+1;precision[[pc]]<-data.frame(ploidy=p,mutation_sd=m,n=u["n"],
   original_mean=u["mean"],original_lower=u["lower"],original_upper=u["upper"],
   reassay_mean=v["mean"],reassay_lower=v["lower"],reassay_upper=v["upper"],
   numerical_difference=err["mean"],numerical_mcse=err["mcse"],precision_pass=unname(precise),row.names=NULL)
  select<-paired$ploidy==p & paired$mutation_sd==m & paired$metric=="between"
  if(precise)paired$operationally_meaningful[select]<-paired$lower[select]>.00625
 }
 precision<-do.call(rbind,precision)
 write.csv(precision,file.path(out,"precision_review.csv"),row.names=FALSE,na="NA")
 write.csv(paired,file.path(out,"paired_contrasts.csv"),row.names=FALSE,na="NA")
 print(precision,row.names=FALSE)
}

print(paired[paired$metric%in%c("between","within","final_diversity"),],row.names=FALSE)

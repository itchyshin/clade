# Rscript dev/data/performance-ploidy/analyze.R OUTDIR N_SEEDS [HORIZON]
a<-commandArgs(trailingOnly=TRUE);stopifnot(length(a)%in%c(2L,3L));out<-a[1];ns<-as.integer(a[2]);H<-if(length(a)==3)as.integer(a[3])else 1000L
r<-read.csv(file.path(out,"runs.csv"));w<-read.csv(file.path(out,"windows.csv"));c<-read.csv(file.path(out,"cohorts.csv"));g<-read.csv(file.path(out,"garden.csv"))
keys<-c("ploidy","mutation_sd","seed");key<-function(d)do.call(paste,c(d[keys],sep="|"))
expected<-expand.grid(ploidy=1:2,mutation_sd=c(0,.05,.2),seed=20001:(20000+ns));rk<-key(r)
stopifnot(nrow(r)==6*ns,!anyDuplicated(rk),setequal(rk,key(expected)),all(r$final_tick<=H),all(r$final_agents>=0),all(50+r$total_births-r$total_deaths==r$final_agents))
stopifnot(all(r$final_haploid_fraction==as.integer(r$ploidy==1)))
blocks<-interaction(r[c("ploidy","seed")],drop=TRUE);stopifnot(all(vapply(split(r$initial_fingerprint,blocks),function(z)length(unique(z))==1,logical(1))))
stopifnot(nrow(w)==2*nrow(r),!anyDuplicated(paste(key(w),w$window)),setequal(paste(key(w),w$window),as.vector(outer(rk,c("full","late"),paste))))
stopifnot(all(w$agent_ticks==w$post_agent_ticks+w$n_at_start-w$n_at_end),all(w$n_at_end==w$n_at_start+w$births-w$deaths),all(w$food>=0 & w$food<=2*w$agent_ticks),all(w$starvations<=w$deaths))
f<-w[w$window=="full",];f<-f[match(rk,key(f)),];stopifnot(all(f$births==r$total_births),all(f$deaths==r$total_deaths),max(abs(f$post_agent_ticks/H-r$mean_population))<1e-10)
if(nrow(c)) {
 c$observed<-tolower(as.character(c$followup_observed))=="true"
 stopifnot(!anyDuplicated(paste(key(c),c$id)),all(c$followup_tick==c$birth_tick+100),all(c$observed==(c$followup_tick<=H)),all(is.na(c$survived_100)==!c$observed),all(c$survived_100[c$observed]%in%c(0,1)))
}
for(i in seq_len(nrow(r)))stopifnot(sum(key(c)==rk[i])==r$total_births[i])
for(i in seq_len(nrow(w))){idx<-key(c)==key(w)[i] & c$birth_tick>=w$start_tick[i] & c$birth_tick<=w$cohort_end_tick[i];stopifnot(sum(idx)==w$cohort_births[i],sum(c$survived_100[idx])==w$recruits_100[i])}
check_garden<-function(g,expected_runs,draws=NULL) {
 expected_keys<-as.vector(outer(key(expected_runs),paste(rep(c(.5,20),each=5),1:5,sep="@"),paste,sep="@"))
 actual<-paste(key(g),g$amount,g$location,sep="@")
 stopifnot(!anyDuplicated(actual),setequal(actual,expected_keys),all(g$trials>0),all(g$successes>=0 & g$successes<=g$trials),all(g$idle_choices>=0 & g$idle_choices<=g$trials),all(g$food==g$successes*pmin(g$amount,2)))
 # BNN architecture 11-8-5:282 parameters,brain cost .001*282+.5/5=.382.
 expected_net<-5*g$food-1.382*g$trials+.5*g$idle_choices
 stopifnot(max(abs(g$net_energy-expected_net)/g$trials)<2e-5)
 if(!is.null(draws))stopifnot(all(g$draws==draws))
 invisible(TRUE)
}
check_garden(g,r)
ni<-match(key(g),rk);stopifnot(all(g$trials==r$final_agents[ni]*g$draws))
scope<-new.env(parent=globalenv());sys.source("R/analysis.R",envir=scope)
r$viability<-vapply(seq_len(nrow(r)),function(i)scope$viability_report(data.frame(t=c(r$tick_of_min[i],r$final_tick[i]),n_agents=c(r$min_population[i],r$final_agents[i])),n_agents_init=50)$verdict,character(1))
write.csv(r,file.path(out,"runs_with_viability.csv"),row.names=FALSE,na="NA")
stat<-function(z){z<-z[is.finite(z)];n<-length(z);m<-if(n)mean(z)else NA_real_;se<-if(n>1)sd(z)/sqrt(n)else NA_real_;h<-if(n>1)qt(.975,n-1)*se else NA_real_;c(n=n,mean=m,mcse=se,lower=m-h,upper=m+h)}
ratio<-function(x,y)ifelse(y>0,x/y,NA_real_)
garden_rates<-function(g){z<-data.frame(g[keys],food=g$food/g$trials,net=g$net_energy/g$trials);aggregate(z[c("food","net")],z[keys],mean)}
ga<-garden_rates(g)
values<-list();i<-0
for(j in seq_len(nrow(r))) {
 z<-r[j,];gw<-ga[match(rk[j],key(ga)),]
 metrics<-c(garden_food=gw$food,garden_net=gw$net,final_agents=z$final_agents,total_births=z$total_births)
 for(win in c("late","full")){
  x<-w[key(w)==rk[j] & w$window==win,]
  metrics<-c(metrics,setNames(c(ratio(x$food,x$agent_ticks),ratio(x$net_energy,x$agent_ticks),1000*ratio(x$births,x$agent_ticks),1000*ratio(x$deaths,x$agent_ticks),ratio(x$recruits_100,x$cohort_births),1000*ratio(x$recruits_100,x$cohort_agent_ticks)),paste0(win,c("_food","_net","_birth_yield","_death_yield","_survival100","_recruit_yield"))))
 }
 for(metric in names(metrics)){i<-i+1;values[[i]]<-data.frame(z[keys],viability=z$viability,metric=metric,value=unname(metrics[metric]),row.names=NULL)}
}
v<-do.call(rbind,values);write.csv(v,file.path(out,"run_metrics.csv"),row.names=FALSE,na="NA")
summaries<-list();pairs<-list();sidx<-0;pidx<-0;set.seed(20261114)
for(p in 1:2)for(metric in unique(v$metric)) {
 for(m in c(0,.05,.2)){
  z<-v[v$ploidy==p & v$mutation_sd==m & v$metric==metric,]
  if(!metric%in%c("final_agents","total_births"))z<-z[z$viability=="viable",]
  sidx<-sidx+1;summaries[[sidx]]<-data.frame(ploidy=p,mutation_sd=m,metric=metric,t(stat(z$value)),row.names=NULL)
 }
 for(m in c(.05,.2)){
  lo<-v[v$ploidy==p & v$mutation_sd==0 & v$metric==metric,];hi<-v[v$ploidy==p & v$mutation_sd==m & v$metric==metric,];hi<-hi[match(lo$seed,hi$seed),]
  keep<-if(metric%in%c("final_agents","total_births"))rep(TRUE,nrow(lo)) else lo$viability=="viable" & hi$viability=="viable"
  keep<-keep & is.finite(lo$value) & is.finite(hi$value);x<-lo$value[keep];y<-hi$value[keep];s<-stat(y-x)
  relative<-lower<-upper<-NA_real_
  if(length(x)>=5 && mean(x)>0){relative<-100*(mean(y)/mean(x)-1);boot<-replicate(2000,{b<-sample.int(length(x),replace=TRUE);if(mean(x[b])>0)100*(mean(y[b])/mean(x[b])-1)else NA_real_});ci<-quantile(boot,c(.025,.975),na.rm=TRUE);lower<-ci[1];upper<-ci[2]}
  pidx<-pidx+1;pairs[[pidx]]<-data.frame(ploidy=p,mutation_sd=m,metric=metric,total_pairs=ns,t(s),relative_percent=relative,relative_lower=lower,relative_upper=upper,practical_benefit=NA,row.names=NULL)
 }
}
summaries<-do.call(rbind,summaries);paired<-do.call(rbind,pairs)
precision<-NULL
if(file.exists(file.path(out,"reassay.csv"))) {
 rg<-read.csv(file.path(out,"reassay.csv"));er<-r[r$seed<=20000+min(10,ns),];check_garden(rg,er,256)
 ra<-garden_rates(rg);ga10<-ga[match(key(ra),key(ga)),];precision<-list();idx<-0
 for(p in 1:2)for(m in c(.05,.2)){
  ix0<-which(ra$ploidy==p & ra$mutation_sd==0);ix1<-match(paste(p,m,ra$seed[ix0],sep="|"),key(ra))
  eligible<-r$viability[match(key(ra)[ix0],rk)]=="viable" & r$viability[match(key(ra)[ix1],rk)]=="viable"
  old<-ga10$food[ix1]-ga10$food[ix0];new<-ra$food[ix1]-ra$food[ix0];error<-stat((new-old)[eligible])
  same_class<-FALSE;ci_old<-ci_new<-c(NA_real_,NA_real_)
  if(sum(eligible)>=5){
   x0<-ga10$food[ix0][eligible];y0<-ga10$food[ix1][eligible];x1<-ra$food[ix0][eligible];y1<-ra$food[ix1][eligible]
   b<-replicate(2000,sample.int(length(x0),replace=TRUE))
   rel0<-apply(b,2,function(z)100*(mean(y0[z])/mean(x0[z])-1));rel1<-apply(b,2,function(z)100*(mean(y1[z])/mean(x1[z])-1))
   ci_old<-quantile(rel0,c(.025,.975));ci_new<-quantile(rel1,c(.025,.975))
   classify<-function(ci)if(ci[1]>5)"benefit" else if(ci[2]< -5)"harm" else if(ci[1]>= -5 && ci[2]<=5)"within5" else "uncertain"
   same_class<-classify(ci_old)==classify(ci_new)
  }
  passed<-error["n"]>=5 && abs(error["mean"])<.003125 && error["mcse"]<.003125 && same_class
  idx<-idx+1;precision[[idx]]<-data.frame(ploidy=p,mutation_sd=m,n=error["n"],numerical_difference=error["mean"],numerical_mcse=error["mcse"],relative_lower_original=ci_old[1],relative_upper_original=ci_old[2],relative_lower_reassay=ci_new[1],relative_upper_reassay=ci_new[2],same_class=same_class,precision_pass=unname(passed),row.names=NULL)
  row<-paired$ploidy==p & paired$mutation_sd==m & paired$metric=="garden_food"
  if(passed)paired$practical_benefit[row]<-paired$relative_lower[row]>5
 }
 precision<-do.call(rbind,precision);write.csv(precision,file.path(out,"precision_review.csv"),row.names=FALSE,na="NA")
}
row<-paired$metric=="late_birth_yield" & paired$n>=5;paired$practical_benefit[row]<-paired$relative_lower[row]>5
write.csv(summaries,file.path(out,"cell_summary.csv"),row.names=FALSE,na="NA");write.csv(paired,file.path(out,"paired_contrasts.csv"),row.names=FALSE,na="NA")
cat("Complete design:",nrow(r),"runs;",nlevels(blocks),"matched founder blocks;",nrow(c),"birth cohorts;",nrow(g),"garden cases\n")
print(with(r,table(ploidy,mutation_sd,viability)))
print(paired[paired$metric%in%c("garden_food","garden_net","late_food","late_birth_yield","late_survival100","late_recruit_yield"),],row.names=FALSE)
if(!is.null(precision))print(precision,row.names=FALSE)
writeLines(capture.output(sessionInfo()),file.path(out,"R-session-info.txt"))

a<-commandArgs(TRUE);root<-a[1];source('R/analysis.R');src<-read.csv(file.path(root,'sources.csv'));r<-read.csv(file.path(root,'runs.csv'));w<-read.csv(file.path(root,'windows.csv'))
seeds<-sort(src$seed);stopifnot(length(seeds)>1,!anyDuplicated(seeds),all(src$status=='ok'),all(src$final_tick==1000),all(src$final_agents>=8),all(src$distinct_mu==8),all(src$mean_deterministic>0),all(src$assay_contexts==48))
key<-function(x)do.call(paste,c(x[c('density','threshold','food_rate','age_mode','seed','mono')],sep=':'));e<-expand.grid(density=c(48,96),threshold=c(80,120),food_rate=c(.05,.025),age_mode=c('fixed','staggered'),seed=seeds,mono=0:8)
stopifnot(nrow(r)==144*length(seeds),nrow(w)==20*nrow(r),!anyDuplicated(key(r)),setequal(key(r),key(e)))
src$viability<-vapply(seq_len(nrow(src)),function(i)viability_report(data.frame(t=c(src$tick_of_min[i],src$final_tick[i]),n_agents=c(src$min_population[i],src$final_agents[i])),n_agents_init=100)$verdict,character(1))
wg<-split(seq_len(nrow(w)),key(w));rk<-key(r);r$viability<-NA_character_;r$n800<-NA_integer_;r$stable<-r$min_population>=20
for(i in seq_len(nrow(r))){z<-w[wg[[rk[i]]],];z<-z[order(z$lo),];stopifnot(nrow(z)==20,all(z$lo==seq(1,1000,50)),z$nstart[1]==r$density[i],all(z$nend==z$nstart+z$births-z$deaths),all(z$pre_exposure==z$post_exposure+z$nstart-z$nend),all(z$nstart[-1]==head(z$nend,-1)),tail(z$nend,1)==r$final_agents[i],sum(z$pre_exposure)==r$exposure[i],sum(z$births)==r$births[i],sum(z$deaths)==r$deaths[i]);r$n800[i]<-z$nend[z$hi==800];r$viability[i]<-viability_report(data.frame(t=c(r$tick_of_min[i],r$final_tick[i]),n_agents=c(r$min_population[i],r$final_agents[i])),n_agents_init=r$density[i])$verdict}
for(ix in split(seq_len(nrow(r)),paste(r$density,r$threshold,r$food_rate,r$age_mode,r$seed))){z<-r[ix,];stopifnot(nrow(z)==9,length(unique(z$physical_hash))==1,length(unique(z$panel_hash))==1,all(z$panel_hash==src$panel_hash[match(z$seed,src$seed)]))}
write.csv(src,file.path(root,'sources_viability.csv'),row.names=FALSE);write.csv(r,file.path(root,'runs_viability.csv'),row.names=FALSE)
out<-list();j<-0
for(ix in split(seq_len(nrow(r)),paste(r$density,r$threshold,r$food_rate,r$age_mode,r$seed))){z<-r[ix,];z<-z[order(z$mono),];stopifnot(all(z$mono==0:8));for(t in c(800,1000)){y<-if(t==800)z$n800 else z$final_agents;j<-j+1;out[[j]]<-data.frame(density=z$density[1],threshold=z$threshold[1],food_rate=z$food_rate[1],age_mode=z$age_mode[1],seed=z$seed[1],tick=t,mix=y[1],control=mean(y[-1]),delta=y[1]-mean(y[-1]),all9_viable=all(z$viability=='viable'),all9_stable=all(z$stable))}}
b<-do.call(rbind,out);write.csv(b,file.path(root,'blocks.csv'),row.names=FALSE)
set.seed(20261114);summ<-list();j<-0
getz<-function(n,q,f,age,t){z<-b[b$density==n & b$threshold==q & b$food_rate==f & b$age_mode==age & b$tick==t,];z<-z[order(z$seed),];stopifnot(identical(z$seed,seeds));z}
F<-function(n,q,age,t)getz(n,q,.025,age,t)$delta-getz(n,q,.05,age,t)$delta
report<-function(d,type,label,t,mix=NA_real_,control=NA_real_){n<-length(d);mu<-mean(d);h<-qt(.975,n-1)*sd(d)/sqrt(n);bt<-quantile(replicate(2000,mean(sample(d,n,replace=TRUE))),c(.025,.975),names=FALSE);data.frame(type=type,label=label,tick=t,n=n,mean=mu,lower=mu-h,upper=mu+h,bootstrap_lower=bt[1],bootstrap_upper=bt[2],mix=mix,control=control)}
for(t in c(800,1000))for(age in c('fixed','staggered')){
 for(n in c(48,96))for(q in c(120,80)){
  for(f in c(.05,.025)){z<-getz(n,q,f,age,t);j<-j+1;summ[[j]]<-report(z$delta,'cell',paste(n,q,f,age),t,mean(z$mix),mean(z$control))}
  j<-j+1;summ[[j]]<-report(F(n,q,age,t),'food',paste(n,q,age),t)
 }
 for(n in c(48,96)){j<-j+1;summ[[j]]<-report(F(n,80,age,t)-F(n,120,age,t),'threshold_change',paste(n,age),t)}
 for(q in c(120,80)){j<-j+1;summ[[j]]<-report(F(96,q,age,t)-F(48,q,age,t),'density_change',paste(q,age),t)}
 j<-j+1;summ[[j]]<-report((F(96,80,age,t)-F(96,120,age,t))-(F(48,80,age,t)-F(48,120,age,t)),'interaction',age,t)
}
for(n in c(48,96))for(q in c(120,80))for(f in c(.05,.025))for(age in c('fixed','staggered')){x<-getz(n,q,f,age,1000);y<-getz(n,q,f,age,800);j<-j+1;summ[[j]]<-report(x$delta-y$delta,'time_change',paste(n,q,f,age),1000)}
summary<-do.call(rbind,summ);write.csv(summary,file.path(root,'summary.csv'),row.names=FALSE);print(table(src$viability));print(with(r,table(density,threshold,food_rate,viability)));print(summary[summary$tick==1000 & summary$type!='cell',],row.names=FALSE)

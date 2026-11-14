a<-commandArgs(TRUE);root<-a[1];source('R/analysis.R')
src<-read.csv(file.path(root,'sources.csv'),stringsAsFactors=FALSE);r<-read.csv(file.path(root,'runs.csv'),stringsAsFactors=FALSE);w<-read.csv(file.path(root,'windows.csv'),stringsAsFactors=FALSE)
stopifnot(length(unique(src$threshold))==1,all(src$status=="ok"));seeds<-sort(src$seed);stopifnot(length(seeds)>1,!anyDuplicated(seeds),all(src$final_tick==1000),all(src$final_agents>=8))
key<-function(x)do.call(paste,c(x[c('food_rate','age_mode','seed','mono')],sep=':'))
e<-expand.grid(food_rate=c(.05,.025),age_mode=c('fixed','staggered'),seed=seeds,mono=0:8)
stopifnot(nrow(r)==36*length(seeds),nrow(w)==20*nrow(r),!anyDuplicated(key(r)),setequal(key(r),key(e)))
stopifnot(all(src$distinct_mu==8),all(src$mean_deterministic>0),all(src$assay_contexts==48))
source_viable<-vapply(seq_len(nrow(src)),function(i)viability_report(data.frame(t=c(src$tick_of_min[i],src$final_tick[i]),n_agents=c(src$min_population[i],src$final_agents[i])),n_agents_init=100)$verdict,character(1));src$viability<-source_viable
wg<-split(seq_len(nrow(w)),key(w));rk<-key(r);r$viability<-NA_character_;r$stable<-r$min_population>=20;r$n800<-NA_integer_
for(i in seq_len(nrow(r))){z<-w[wg[[rk[i]]],];z<-z[order(z$lo),];stopifnot(nrow(z)==20,all(z$lo==seq(1,1000,50)),z$nstart[1]==96,all(z$nend==z$nstart+z$births-z$deaths),all(z$pre_exposure==z$post_exposure+z$nstart-z$nend),all(z$nstart[-1]==head(z$nend,-1)),tail(z$nend,1)==r$final_agents[i],sum(z$pre_exposure)==r$exposure[i],sum(z$births)==r$births[i],sum(z$deaths)==r$deaths[i]);r$n800[i]<-z$nend[z$hi==800];r$viability[i]<-viability_report(data.frame(t=c(r$tick_of_min[i],r$final_tick[i]),n_agents=c(r$min_population[i],r$final_agents[i])),n_agents_init=96)$verdict}
for(ix in split(seq_len(nrow(r)),paste(r$food_rate,r$age_mode,r$seed))){z<-r[ix,];stopifnot(nrow(z)==9,length(unique(z$physical_hash))==1,length(unique(z$panel_hash))==1,all(z$panel_hash==src$panel_hash[match(z$seed,src$seed)]))}
write.csv(src,file.path(root,'sources_viability.csv'),row.names=FALSE);write.csv(r,file.path(root,'runs_viability.csv'),row.names=FALSE)
out<-list();j<-0
for(ix in split(seq_len(nrow(r)),paste(r$food_rate,r$age_mode,r$seed))){z<-r[ix,];z<-z[order(z$mono),];stopifnot(all(z$mono==0:8));for(t in c(800,1000)){y<-if(t==800)z$n800 else z$final_agents;j<-j+1;out[[j]]<-data.frame(food_rate=z$food_rate[1],age_mode=z$age_mode[1],seed=z$seed[1],tick=t,mix=y[1],control=mean(y[-1]),delta=y[1]-mean(y[-1]),all9_viable=all(z$viability=='viable'),all9_stable=all(z$stable))}}
b<-do.call(rbind,out);write.csv(b,file.path(root,'blocks.csv'),row.names=FALSE)
set.seed(20261114);summ<-list();j<-0
getz<-function(rate,age,t){z<-b[b$food_rate==rate & b$age_mode==age & b$tick==t,];z[order(z$seed),]}
report<-function(d,type,label,t,vs=NA_real_,cs=NA_real_,viable=NA_real_){n<-length(d);mu<-mean(d);h<-qt(.975,n-1)*sd(d)/sqrt(n);bt<-quantile(replicate(2000,mean(sample(d,n,replace=TRUE))),c(.025,.975),names=FALSE);data.frame(type=type,label=label,tick=t,n=n,mean=mu,lower=mu-h,upper=mu+h,bootstrap_lower=bt[1],bootstrap_upper=bt[2],mix=vs,control=cs,all9_viable=viable)}
for(rate in c(.05,.025))for(age in c('fixed','staggered')){
 for(t in c(800,1000)){z<-getz(rate,age,t);j<-j+1;summ[[j]]<-report(z$delta,'cell',paste(rate,age),t,mean(z$mix),mean(z$control),sum(z$all9_viable))}
 x<-getz(rate,age,1000);y<-getz(rate,age,800);j<-j+1;summ[[j]]<-report(x$delta-y$delta,'change',paste(rate,age),1000)
}
for(t in c(800,1000)){
 for(age in c('fixed','staggered')){x<-getz(.025,age,t);y<-getz(.05,age,t);j<-j+1;summ[[j]]<-report(x$delta-y$delta,'food',age,t)}
 for(rate in c(.05,.025)){x<-getz(rate,'staggered',t);y<-getz(rate,'fixed',t);j<-j+1;summ[[j]]<-report(x$delta-y$delta,'age',as.character(rate),t)}
 x<-getz(.025,'staggered',t)$delta-getz(.025,'fixed',t)$delta;y<-getz(.05,'staggered',t)$delta-getz(.05,'fixed',t)$delta;j<-j+1;summ[[j]]<-report(x-y,'interaction','food_by_age',t)
}
out<-do.call(rbind,summ);write.csv(out,file.path(root,'summary.csv'),row.names=FALSE);print(table(src$viability));print(with(r,table(food_rate,age_mode,viability)));print(with(r,table(food_rate,age_mode,stable)));print(out,row.names=FALSE)

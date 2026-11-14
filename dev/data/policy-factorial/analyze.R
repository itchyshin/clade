a<-commandArgs(TRUE);root<-a[1];source('R/analysis.R')
r<-read.csv(file.path(root,'runs.csv'));w<-read.csv(file.path(root,'windows.csv'))
key<-function(x)do.call(paste,c(x[c('ploidy','food_rate','age_mode','seed','mono')],sep=':'))
e<-expand.grid(ploidy=1:2,food_rate=c(.05,.025,.0125),age_mode=c('fixed','staggered'),seed=20001:20100,mono=0:8)
stopifnot(nrow(r)==10800,!anyDuplicated(key(r)),setequal(key(r),key(e)),nrow(w)==216000)
wk<-key(w);wg<-split(seq_len(nrow(w)),wk);rk<-key(r)
r$viability<-NA_character_
for(i in seq_len(nrow(r))){
 z<-w[wg[[rk[i]]],];z<-z[order(z$lo),]
 stopifnot(nrow(z)==20,all(z$lo==seq(1,1000,50)),z$nstart[1]==48,all(z$nend==z$nstart+z$births-z$deaths),all(z$pre_exposure==z$post_exposure+z$nstart-z$nend),all(z$nstart[-1]==head(z$nend,-1)),tail(z$nend,1)==r$final_agents[i],sum(z$pre_exposure)==r$exposure[i],sum(z$births)==r$births[i],sum(z$deaths)==r$deaths[i])
 r$viability[i]<-viability_report(data.frame(t=c(r$tick_of_min[i],r$final_tick[i]),n_agents=c(r$min_population[i],r$final_agents[i])),n_agents_init=48)$verdict
}
write.csv(r,file.path(root,'runs_viability.csv'),row.names=FALSE)
groups<-split(seq_len(nrow(r)),paste(r$ploidy,r$food_rate,r$age_mode,r$seed));out<-list();j<-0
for(ix in groups){z<-r[ix,];z<-z[order(z$mono),];stopifnot(nrow(z)==9,all(z$mono==0:8));for(metric in c('population','extinct')){
 y<-if(metric=='population')z$final_agents else as.integer(z$final_agents==0)
 j<-j+1;out[[j]]<-data.frame(ploidy=z$ploidy[1],food_rate=z$food_rate[1],age_mode=z$age_mode[1],seed=z$seed[1],metric=metric,mix=y[1],control=mean(y[-1]),delta=y[1]-mean(y[-1]),all9_viable=all(z$viability=='viable'))
}}
b<-do.call(rbind,out);write.csv(b,file.path(root,'blocks.csv'),row.names=FALSE)
summaryrows<-list();j<-0;set.seed(20261114)
summarize<-function(z,type,label,comparison=NULL){
 d<-if(is.null(comparison))z$delta else z$delta-comparison$delta
 n<-length(d);m<-mean(d);se<-sd(d)/sqrt(n);h<-qt(.975,n-1)*se
 boot<-quantile(replicate(2000,mean(sample(d,n,replace=TRUE))),c(.025,.975),names=FALSE)
 data.frame(ploidy=z$ploidy[1],metric=z$metric[1],type=type,label=label,n=n,mean=m,lower=m-h,upper=m+h,bootstrap_lower=boot[1],bootstrap_upper=boot[2],mix=if(is.null(comparison))mean(z$mix)else NA,control=if(is.null(comparison))mean(z$control)else NA,all9_viable=if(is.null(comparison))sum(z$all9_viable)else NA)
}
for(p in 1:2)for(metric in c('population','extinct')){
 getz<-function(rate,age){z<-b[b$ploidy==p & b$metric==metric & b$food_rate==rate & b$age_mode==age,];z[order(z$seed),]}
 for(rate in c(.05,.025,.0125))for(age in c('fixed','staggered')){z<-getz(rate,age);j<-j+1;summaryrows[[j]]<-summarize(z,'cell',paste(rate,age))}
 for(rate in c(.05,.025,.0125)){z<-getz(rate,'staggered');q<-getz(rate,'fixed');stopifnot(identical(z$seed,q$seed));j<-j+1;summaryrows[[j]]<-summarize(z,'age_effect',as.character(rate),q)}
 for(rate in c(.025,.0125))for(age in c('fixed','staggered')){z<-getz(rate,age);q<-getz(.05,age);stopifnot(identical(z$seed,q$seed));j<-j+1;summaryrows[[j]]<-summarize(z,'food_effect',paste(rate,age),q)}
 for(age in c('fixed','staggered')){z<-getz(.0125,age);q<-getz(.025,age);j<-j+1;summaryrows[[j]]<-summarize(z,'regrowth_effect',age,q)}
 for(rate in c(.025,.0125)){
 z<-getz(rate,'staggered');q<-getz(rate,'fixed');u<-getz(.05,'staggered');v<-getz(.05,'fixed');z$delta<-z$delta-q$delta;u$delta<-u$delta-v$delta
 j<-j+1;summaryrows[[j]]<-summarize(z,'interaction',as.character(rate),u)
 }
 z<-getz(.0125,'staggered');q<-getz(.0125,'fixed');u<-getz(.025,'staggered');v<-getz(.025,'fixed');z$delta<-z$delta-q$delta;u$delta<-u$delta-v$delta
 j<-j+1;summaryrows[[j]]<-summarize(z,'regrowth_interaction','.0125 vs .025',u)
}
s<-do.call(rbind,summaryrows);write.csv(s,file.path(root,'factorial_summary.csv'),row.names=FALSE);print(with(r,table(ploidy,food_rate,age_mode,viability)));print(s[s$metric=='population',],row.names=FALSE)

a<-commandArgs(TRUE);p<-a[1];b<-read.csv(file.path(p,'blocks.csv'));seeds<-sort(unique(b$seed));stopifnot(nrow(b)==16*length(seeds),!anyDuplicated(b[c('seed','density','threshold','food_rate','age_mode')]),all(abs(b$population-(b$births-b$deaths))<1e-7))
getz<-function(n,q,f,age){z<-b[b$density==n & b$threshold==q & b$food_rate==f & b$age_mode==age,];z<-z[order(z$seed),];stopifnot(identical(z$seed,seeds));z}
F<-function(n,q,age,m)getz(n,q,.025,age)[[m]]-getz(n,q,.05,age)[[m]]
metrics<-c('population','births','deaths','food','exposure','food_rate_per1000',unlist(lapply(c('births','deaths','food','exposure'),function(m)paste0(m,'_age',1:4))),unlist(lapply(c('food','births','deaths'),function(m)paste0(m,'_rate_age',1:4,'_per1000'))), 'births_rate_per1000','deaths_rate_per1000')
rows<-list();j<-0;set.seed(20261114)
summarize<-function(v,type,label,metric){original<-length(v);v<-v[is.finite(v)];n<-length(v);if(n<2)return(data.frame(type=type,label=label,metric=metric,n=n,undefined=original-n,mean=NA,lower=NA,upper=NA,bootstrap_lower=NA,bootstrap_upper=NA));mu<-mean(v);h<-qt(.975,n-1)*sd(v)/sqrt(n);bt<-if(metric %in% c('population','births','deaths','food','exposure','food_rate_per1000','births_rate_per1000','deaths_rate_per1000'))quantile(replicate(2000,mean(sample(v,n,replace=TRUE))),c(.025,.975),names=FALSE)else c(NA,NA);data.frame(type=type,label=label,metric=metric,n=n,undefined=original-n,mean=mu,lower=mu-h,upper=mu+h,bootstrap_lower=bt[1],bootstrap_upper=bt[2])}
for(age in c('fixed','staggered'))for(metric in metrics){
 for(n in c(48,96))for(q in c(120,80)){j<-j+1;rows[[j]]<-summarize(F(n,q,age,metric),'food_effect',paste(n,q,age),metric)}
 for(n in c(48,96)){j<-j+1;rows[[j]]<-summarize(F(n,80,age,metric)-F(n,120,age,metric),'threshold_change',paste(n,age),metric)}
 for(q in c(120,80)){j<-j+1;rows[[j]]<-summarize(F(96,q,age,metric)-F(48,q,age,metric),'density_change',paste(q,age),metric)}
 j<-j+1;rows[[j]]<-summarize((F(96,80,age,metric)-F(96,120,age,metric))-(F(48,80,age,metric)-F(48,120,age,metric)),'interaction',age,metric)
}
s<-do.call(rbind,rows);write.csv(s,file.path(p,'summary.csv'),row.names=FALSE)
# Exact seed-level population decomposition holds for every food comparison and factorial contrast.
for(age in c('fixed','staggered'))for(n in c(48,96))for(q in c(120,80))stopifnot(all(abs(F(n,q,age,'population')-(F(n,q,age,'births')-F(n,q,age,'deaths')))<1e-7))
domrows<-list();di<-0
for(ix in split(seq_len(nrow(b)),paste(b$density,b$threshold,b$food_rate,b$age_mode))){z<-b[ix,];for(m in c('mix_birth_dominance','mix_food_dominance')){v<-z[[m]];v<-v[is.finite(v)];n<-length(v);mu<-if(n)mean(v) else NA_real_;h<-if(n>1)qt(.975,n-1)*sd(v)/sqrt(n) else NA_real_;di<-di+1;domrows[[di]]<-data.frame(density=z$density[1],threshold=z$threshold[1],food_rate=z$food_rate[1],age_mode=z$age_mode[1],metric=m,n=n,undefined=nrow(z)-n,mean=mu,lower=mu-h,upper=mu+h)}}
dom<-do.call(rbind,domrows);write.csv(dom,file.path(p,'policy-dominance.csv'),row.names=FALSE)

print(s[s$type %in% c('food_effect','threshold_change','density_change') & s$metric %in% c('population','births','deaths','food','exposure','food_rate_per1000'),],row.names=FALSE)

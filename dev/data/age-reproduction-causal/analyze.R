a<-commandArgs(TRUE);p<-a[1];b<-read.csv(file.path(p,'blocks.csv'));seeds<-sort(unique(b$seed));stopifnot(nrow(b)==64*length(seeds),!anyDuplicated(b[c('seed','gate','density','threshold','food_rate','age_mode')]),all(abs(b$population1000-(b$births-b$deaths))<1e-7))
getz<-function(g,n,q,f,age){z<-b[b$gate==g & b$density==n & b$threshold==q & b$food_rate==f & b$age_mode==age,];z<-z[order(z$seed),];stopifnot(identical(z$seed,seeds));z}
F<-function(g,n,q,age,m)getz(g,n,q,.025,age)[[m]]-getz(g,n,q,.05,age)[[m]]
T<-function(g,n,age,m)F(g,n,80,age,m)-F(g,n,120,age,m)
metrics<-c('population1000','population800','births','deaths','food','exposure',paste0('birth_age',1:4))
rows<-list();j<-0;set.seed(20261115)
report<-function(v,type,label,metric){n<-length(v);mu<-mean(v);h<-if(n>1)qt(.975,n-1)*sd(v)/sqrt(n) else NA_real_;bt<-if(n>1 && metric %in% c('population1000','population800','births','deaths'))quantile(replicate(2000,mean(sample(v,n,replace=TRUE))),c(.025,.975),names=FALSE)else c(NA,NA);data.frame(type=type,label=label,metric=metric,n=n,mean=mu,lower=mu-h,upper=mu+h,bootstrap_lower=bt[1],bootstrap_upper=bt[2])}
for(age in c('fixed','staggered'))for(m in metrics){
 for(n in c(48,96)){
  for(g in c('sham','young','old','both')){j<-j+1;rows[[j]]<-report(T(g,n,age,m),'threshold_effect',paste(g,n,age),m)}
  for(g in c('young','old','both')){j<-j+1;rows[[j]]<-report(T(g,n,age,m)-T('sham',n,age,m),'gate_effect_on_threshold',paste(g,n,age),m)}
  j<-j+1;rows[[j]]<-report(T('both',n,age,m)-T('young',n,age,m)-T('old',n,age,m)+T('sham',n,age,m),'gate_interaction_on_threshold',paste(n,age),m)
  for(q in c(120,80))for(g in c('sham','young','old','both')){j<-j+1;rows[[j]]<-report(F(g,n,q,age,m),'food_effect',paste(g,n,q,age),m)}
 }
}
s<-do.call(rbind,rows);write.csv(s,file.path(p,'summary.csv'),row.names=FALSE)
for(age in c('fixed','staggered'))for(g in c('sham','young','old','both'))for(n in c(48,96))stopifnot(all(abs(T(g,n,age,'population1000')-(T(g,n,age,'births')-T(g,n,age,'deaths')))<1e-7))
print(s[s$metric=='population1000' & s$type %in% c('threshold_effect','gate_effect_on_threshold','gate_interaction_on_threshold'),],row.names=FALSE)

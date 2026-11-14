a<-commandArgs(TRUE);out<-a[1]
b<-read.csv(file.path(out,'block_contrasts.csv'));x<-read.csv(file.path(out,'summary.csv'))
z0<-b[b$mode=='forage' & b$metric %in% c('food_rate','net_rate'),]
set.seed(20261115)
r<-lapply(split(z0,interaction(z0$ploidy,z0$source_mutation,z0$metric,drop=TRUE)),function(z){
 ci<-quantile(replicate(4000,mean(sample(z$delta,replace=TRUE))),c(.025,.975))
 ss<-x[x$guard=='all_blocks' & x$mode=='forage' & x$ploidy==z$ploidy[1] & x$source_mutation==z$source_mutation[1] & x$metric==z$metric[1],]
 data.frame(ploidy=z$ploidy[1],source_mutation=z$source_mutation[1],metric=z$metric[1],n=nrow(z),mean=mean(z$delta),sd=sd(z$delta),minimum=min(z$delta),maximum=max(z$delta),bootstrap_lower=ci[1],bootstrap_upper=ci[2],t_lower=ss$lower,t_upper=ss$upper)
})
write.csv(do.call(rbind,r),file.path(out,'robustness.csv'),row.names=FALSE)

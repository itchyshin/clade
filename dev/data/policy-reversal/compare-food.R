a<-commandArgs(TRUE);p<-a[1];base<-read.csv(file.path(p,'blocks.csv'));high<-read.csv(file.path(p,'high-blocks.csv'))
stopifnot(!anyDuplicated(base[c('seed','tick')]),!anyDuplicated(high[c('seed','tick')]))
z<-merge(base,high,by=c('seed','tick'),suffixes=c('_base','_high'));stopifnot(nrow(z)==2000)
metrics<-c('n_mix','n_control','advantage','density_mix','grass_mix','food_mix','effective_policies','dominant_frequency','composition','residual');out<-list();j<-0;set.seed(20261114)
for(t in sort(unique(z$tick)))for(m in metrics){
 x<-z[z$tick==t,];v<-x[[paste0(m,'_high')]]-x[[paste0(m,'_base')]];v<-v[is.finite(v)];n<-length(v);mu<-if(n)mean(v)else NA;h<-if(n>1)qt(.975,n-1)*sd(v)/sqrt(n)else NA;bt<-if(n>1)quantile(replicate(2000,mean(sample(v,n,replace=TRUE))),c(.025,.975),names=FALSE)else c(NA,NA)
 j<-j+1;out[[j]]<-data.frame(tick=t,metric=m,n=n,mean=mu,lower=mu-h,upper=mu+h,bootstrap_lower=bt[1],bootstrap_upper=bt[2])
}
y<-do.call(rbind,out);write.csv(y,file.path(p,'regrowth-effects.csv'),row.names=FALSE,na='NA');print(y[y$tick %in% c(300,600,1000) & y$metric %in% c('n_mix','n_control','advantage','grass_mix','effective_policies'),],row.names=FALSE)
cap<-aggregate(cbind(mix_cap_ticks,control_cap_ticks)~seed,high,sum);zcap<-merge(z[z$tick==1000,],cap,by='seed',suffixes=c('','_total'));v<-zcap[zcap$mix_cap_ticks_total==0 & zcap$control_cap_ticks_total==0,'advantage_high']-zcap[zcap$mix_cap_ticks_total==0 & zcap$control_cap_ticks_total==0,'advantage_base'];n<-length(v);mu<-if(n)mean(v)else NA;h<-if(n>1)qt(.975,n-1)*sd(v)/sqrt(n)else NA
write.csv(data.frame(n=n,mean=mu,lower=mu-h,upper=mu+h),file.path(p,'cap-free-sensitivity.csv'),row.names=FALSE,na='NA')

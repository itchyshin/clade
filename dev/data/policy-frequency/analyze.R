a<-commandArgs(TRUE);root<-a[1];r<-read.csv(file.path(root,'runs.csv'),stringsAsFactors=FALSE);old<-read.csv(file.path(root,'prior-blocks.csv'))
e<-expand.grid(seed=20001:20100,mode=c('natural','shuffle','balanced'),tick=seq(50,1000,50));key<-function(x)paste(x$seed,x$mode,x$tick,sep=':')
stopifnot(nrow(r)==6000,!anyDuplicated(key(r)),setequal(key(r),key(e)),all(r$pre_hash==r$post_hash))
parse<-function(x)as.integer(strsplit(x,':',fixed=TRUE)[[1]])
for(seed in 20001:20100){
 z<-r[r$seed==seed,];stopifnot(length(unique(z$pre_hash))==1, length(unique(z$counts_before))==1)
 for(mode in c('natural','shuffle','balanced')){
  x<-z[z$mode==mode,];x<-x[order(x$tick),];before<-parse(x$counts_before[1]);after<-parse(x$counts_after[1]);stopifnot(length(before)==8,length(after)==8,sum(before)==x$n[x$tick==600],sum(after)==sum(before),length(unique(x$counts_after))==1)
  if(mode%in%c('natural','shuffle'))stopifnot(all(before==after)) else stopifnot(max(after)-min(after)<=1)
  for(i in seq_len(nrow(x)))stopifnot(sum(parse(x$policy_counts[i]))==x$n[i])
  q<-old[old$seed==seed,];q<-q[order(q$tick),];stopifnot(nrow(q)==20,all(x$n[x$tick<=600]==q$n_mix[q$tick<=600]))
  if(mode=='natural')stopifnot(all(x$n==q$n_mix),all(abs(x$grass-q$grass_mix*900)<1e-6))
 }
}
b<-r[r$mode=='balanced',];s<-r[r$mode=='shuffle',];n<-r[r$mode=='natural',];colnames(b)[-c(1,3)]<-paste0(colnames(b)[-c(1,3)],'_balanced');colnames(s)[-c(1,3)]<-paste0(colnames(s)[-c(1,3)],'_shuffle');colnames(n)[-c(1,3)]<-paste0(colnames(n)[-c(1,3)],'_natural')
z<-merge(merge(b,s,by=c('seed','tick')),n,by=c('seed','tick'));z<-merge(z,old[,c('seed','tick','n_control')],by=c('seed','tick'));stopifnot(nrow(z)==2000)
z$restoration_effect<-z$n_balanced-z$n_shuffle;z$shuffle_effect<-z$n_shuffle-z$n_natural;z$balanced_advantage<-z$n_balanced-z$n_control;z$shuffle_advantage<-z$n_shuffle-z$n_control
z$reversal_effect<-as.integer(z$n_balanced<z$n_control)-as.integer(z$n_shuffle<z$n_control)
z$policies_restored<-vapply(seq_len(nrow(z)),function(i){before<-parse(z$counts_before_balanced[i]);after<-parse(z$counts_after_balanced[i]);sum(before==0 & after>0)},integer(1))
write.csv(z,file.path(root,'blocks.csv'),row.names=FALSE)
set.seed(20261114);ans<-list();j<-0
for(t in sort(unique(z$tick)))for(metric in c('n_natural','n_shuffle','n_balanced','n_control','restoration_effect','shuffle_effect','balanced_advantage','shuffle_advantage','reversal_effect','policies_restored','swaps_shuffle','swaps_balanced')){
 v<-z[z$tick==t,metric];n<-length(v);mu<-mean(v);h<-qt(.975,n-1)*sd(v)/sqrt(n);bt<-quantile(replicate(2000,mean(sample(v,n,replace=TRUE))),c(.025,.975),names=FALSE);j<-j+1;ans[[j]]<-data.frame(tick=t,metric=metric,n=n,mean=mu,lower=mu-h,upper=mu+h,bootstrap_lower=bt[1],bootstrap_upper=bt[2])
}
sum<-do.call(rbind,ans);write.csv(sum,file.path(root,'summary.csv'),row.names=FALSE);print(sum[sum$tick %in% c(600,700,800,900,1000) & sum$metric %in% c('n_natural','n_shuffle','n_balanced','n_control','restoration_effect','shuffle_effect','reversal_effect','policies_restored','swaps_shuffle','swaps_balanced'),],row.names=FALSE)

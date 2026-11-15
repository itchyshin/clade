a<-commandArgs(TRUE);p<-a[1];b<-read.csv(file.path(p,'blocks.csv'));out<-list();j<-0
for(n in c(48,96))for(q in c(120,80))for(age in c('fixed','staggered'))for(m in c('mix_birth_dominance','mix_food_dominance')){
 x<-subset(b,density==n & threshold==q & food_rate==.025 & age_mode==age);y<-subset(b,density==n & threshold==q & food_rate==.05 & age_mode==age);x<-x[order(x$seed),];y<-y[order(y$seed),];stopifnot(identical(x$seed,y$seed));d<-x[[m]]-y[[m]];d<-d[is.finite(d)];N<-length(d);mu<-if(N)mean(d) else NA_real_;h<-if(N>1)qt(.975,N-1)*sd(d)/sqrt(N) else NA_real_;j<-j+1;out[[j]]<-data.frame(density=n,threshold=q,age_mode=age,metric=m,n=N,undefined=nrow(x)-N,mean=mu,lower=mu-h,upper=mu+h)
}
s<-do.call(rbind,out);write.csv(s,file.path(p,'policy-dominance-food-contrast.csv'),row.names=FALSE);print(s,row.names=FALSE)

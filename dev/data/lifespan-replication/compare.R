a<-commandArgs(TRUE);p<-a[1];oldpath<-a[2]
new<-read.csv(file.path(p,'paired','seed-summary.csv'));old<-read.csv(oldpath)
seeds<-85001:85100;stopifnot(setequal(new$seed,seeds),setequal(old$seed,seeds))
ci<-function(x){stopifnot(length(x)==100,all(is.finite(x)));m<-mean(x);h<-qt(.975,99)*sd(x)/10;c(mean=m,lower=m-h,upper=m+h)}
metrics<-c('pop','pop200','pop400','pop600','pop800','pop_change','births','deaths',paste0('birth_age',1:4),paste0('birth_share',1:4),'cif','entry_age')
out<-list();j<-0
for(age in c('fixed','staggered')) for(co in c('all','complete')) for(metric in metrics){
 getT<-function(b) {
  v<-function(q,food){z<-b[b$age==age & b$cohort==co & b$q==q & b$food==food,];z<-z[order(z$seed),];stopifnot(identical(z$seed,seeds));z[[metric]]}
  (v(80,.025)-v(80,.05))-(v(120,.025)-v(120,.05))
 }
 x<-getT(new);y<-getT(old);ok<-is.finite(x)&is.finite(y)
 if(sum(ok)<2){m<-lo<-hi<-NA_real_}else{v<-x[ok]-y[ok];m<-mean(v);h<-qt(.975,length(v)-1)*sd(v)/sqrt(length(v));lo<-m-h;hi<-m+h}
 j<-j+1;out[[j]]<-data.frame(age,cohort=co,metric,old_mean=if(all(is.finite(y))) mean(y) else NA,new_mean=if(all(is.finite(x))) mean(x) else NA,change=m,lower=lo,upper=hi,n=sum(ok),planned=100)
}
write.csv(do.call(rbind,out),file.path(p,'paired','lifespan-comparison.csv'),row.names=FALSE)
cat('Paired lifespan differences use the 100 matched source seeds.\n')

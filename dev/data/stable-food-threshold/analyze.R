args<-commandArgs(TRUE);p<-args[1];life<-args[2]
r<-read.csv(file.path(p,paste0(life,'-runs.csv')));t<-read.csv(file.path(p,paste0(life,'-timing.csv')))
seeds<-sort(unique(r$seed));stopifnot(identical(seeds,85001:85100),nrow(r)==7200,nrow(t)==14400)
stopifnot(!anyDuplicated(r[c('seed','threshold','food','age_mode','mono')]))
ci<-function(x,allow_missing=FALSE) {
 if(!allow_missing)stopifnot(length(x)==100,all(is.finite(x)))
 n0<-length(x);x<-x[is.finite(x)];n<-length(x);if(n<2)return(c(mean=if(n)mean(x) else NA,lower=NA,upper=NA,n=n,planned=n0))
 m<-mean(x);h<-qt(.975,n-1)*sd(x)/sqrt(n);c(mean=m,lower=m-h,upper=m+h,n=n,planned=n0)
}
rows<-list();j<-0
for(seed in seeds) for(q in c(80,120)) for(food in c(.05,.025)) for(age in c('fixed','staggered')) {
 x<-r[r$seed==seed&r$threshold==q&r$food==food&r$age_mode==age,];x<-x[order(x$mono),];stopifnot(nrow(x)==9,identical(x$mono,0:8))
 for(co in c('all','complete')) {
  a<-t[t$seed==seed&t$threshold==q&t$food==food&t$age_mode==age&t$cohort==co,];a<-a[order(a$mono),];stopifnot(nrow(a)==9,identical(a$mono,0:8))
  j<-j+1;y<-data.frame(seed,q,food,age,cohort=co,pop=x$final[1]-mean(x$final[-1]),pop800=x$pop800[1]-mean(x$pop800[-1]),births=x$births[1]-mean(x$births[-1]),deaths=x$deaths[1]-mean(x$deaths[-1]),cif=a$cif_birth50[1]-mean(a$cif_birth50[-1]),entry_age=a$entry_age[1]-mean(a$entry_age[-1]),cif_mix=a$cif_birth50[1],cif_control=mean(a$cif_birth50[-1]),entry_age_mix=a$entry_age[1],entry_age_control=mean(a$entry_age[-1]))
  for(tt in c(200,400,600))y[[paste0('pop',tt)]]<-x[[paste0('pop',tt)]][1]-mean(x[[paste0('pop',tt)]][-1])
  for(i in 1:4) {
   count<-x[[paste0('birth_age',i)]];y[[paste0('birth_age',i)]]<-count[1]-mean(count[-1])
   frac<-ifelse(x$births>0,count/x$births,NA_real_);y[[paste0('birth_share',i)]]<-frac[1]-mean(frac[-1])
  }
  stopifnot(abs(y$pop-(y$births-y$deaths))<1e-7,abs(y$births-sum(y[paste0('birth_age',1:4)]))<1e-7);rows[[j]]<-y
 }
}
b<-do.call(rbind,rows);b$pop_change<-b$pop-b$pop800;write.csv(b,file.path(p,'seed-summary.csv'),row.names=FALSE)
metrics<-c('pop','pop200','pop400','pop600','pop800','pop_change','births','deaths',paste0('birth_age',1:4),paste0('birth_share',1:4),'cif','entry_age','cif_mix','cif_control','entry_age_mix','entry_age_control')
res<-list();j<-0
for(age in c('fixed','staggered')) for(co in c('all','complete')) for(metric in metrics) {
 vals<-function(q,food){z<-b[b$age==age&b$cohort==co&b$q==q&b$food==food,];z<-z[order(z$seed),];stopifnot(identical(z$seed,seeds));z[[metric]]}
 a<-vals(80,.025)-vals(80,.05);d<-vals(120,.025)-vals(120,.05)
 for(contrast in c('food80','food120','interaction')) {
  x<-switch(contrast,food80=a,food120=d,interaction=a-d);maymiss<-metric %in% c(paste0('birth_share',1:4),'cif','entry_age','cif_mix','cif_control','entry_age_mix','entry_age_control')
  v<-ci(x,maymiss);j<-j+1;res[[j]]<-data.frame(age,cohort=co,metric,contrast,mean=v[1],lower=v[2],upper=v[3],n=v[4],planned=v[5])
 }
}
write.csv(do.call(rbind,res),file.path(p,'effects.csv'),row.names=FALSE)
cat('100 seed blocks, factorial contrasts; timing rows explicitly report finite denominators.\n')

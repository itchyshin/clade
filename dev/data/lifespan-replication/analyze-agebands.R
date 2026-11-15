a<-commandArgs(TRUE);p<-a[1];old<-read.csv(a[2]);r<-read.csv(file.path(p,'agebands.csv'));stopifnot(nrow(r)==14400)
rows<-list();j<-0
for(seed in c(85001:85100,87001:87100))for(q in c(80,120))for(food in c(.05,.025))for(age in c('fixed','staggered')) {
 x<-r[r$seed==seed&r$threshold==q&r$food==food&r$age_mode==age,];x<-x[order(x$mono),];stopifnot(nrow(x)==9,identical(x$mono,0:8))
 j<-j+1;y<-data.frame(seed,q,food,age)
 for(metric in c('young','age50_99','age100_149','age150_299','age300_plus'))y[[metric]]<-x[[metric]][1]-mean(x[[metric]][-1])
 rows[[j]]<-y
}
b<-do.call(rbind,rows);write.csv(b,file.path(p,'ageband-seeds.csv'),row.names=FALSE)
res<-list();j<-0
for(group in c('paired','fresh'))for(age in c('fixed','staggered'))for(metric in c('young','age50_99','age100_149','age150_299','age300_plus')) {
 seeds<-if(group=='paired')85001:85100 else 87001:87100
 getv<-function(z,m,q,f){x<-z[z$age==age&z$q==q&z$food==f,];x<-x[order(x$seed),];stopifnot(identical(x$seed,seeds));x[[m]]}
 z<-b[b$seed %in% seeds,];T<-(getv(z,metric,80,.025)-getv(z,metric,80,.05))-(getv(z,metric,120,.025)-getv(z,metric,120,.05));m<-mean(T);h<-qt(.975,99)*sd(T)/10
 j<-j+1;res[[j]]<-data.frame(group,age,metric,mean=m,lower=m-h,upper=m+h)
 if(group=='paired' && metric %in% c('young','age150_299')) {
  o<-old[old$cohort=='all',];oldmetric<-if(metric=='young')'birth_age1' else 'birth_age4';Told<-(getv(o,oldmetric,80,.025)-getv(o,oldmetric,80,.05))-(getv(o,oldmetric,120,.025)-getv(o,oldmetric,120,.05));diff<-T-Told;m<-mean(diff);h<-qt(.975,99)*sd(diff)/10
  j<-j+1;res[[j]]<-data.frame(group='paired_change_400_minus_300',age,metric,mean=m,lower=m-h,upper=m+h)
 }
}
write.csv(do.call(rbind,res),file.path(p,'ageband-effects.csv'),row.names=FALSE)
cat('Age-band interactions and paired lifespan changes use independent source blocks.\n')

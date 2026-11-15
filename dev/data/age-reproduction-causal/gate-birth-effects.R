a<-commandArgs(TRUE);p<-a[1];b<-read.csv(file.path(p,'age-births-by-seed.csv'));seeds<-sort(unique(b$seed));rows<-list();j<-0
getz<-function(g,n,q,f,age,group){z<-b[b$gate==g & b$density==n & b$threshold==q & b$food_rate==f & b$age_mode==age & b$group==group,];z<-z[order(z$seed),];stopifnot(identical(z$seed,seeds));z}
for(n in c(48,96))for(q in c(120,80))for(f in c(.05,.025))for(age in c('fixed','staggered'))for(group in c('mixture','control'))for(g in c('young','old','both'))for(m in paste0('birth_age',1:4)){
 d<-getz(g,n,q,f,age,group)[[m]]-getz('sham',n,q,f,age,group)[[m]];N<-length(d);mu<-mean(d);h<-if(N>1)qt(.975,N-1)*sd(d)/sqrt(N)else NA_real_;j<-j+1;rows[[j]]<-data.frame(gate=g,density=n,threshold=q,food_rate=f,age_mode=age,group=group,metric=m,n=N,mean=mu,lower=mu-h,upper=mu+h)
}
s<-do.call(rbind,rows);write.csv(s,file.path(p,'gate-birth-effects.csv'),row.names=FALSE);print(head(s),row.names=FALSE)

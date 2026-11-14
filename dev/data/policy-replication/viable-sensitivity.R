a<-commandArgs(TRUE);p<-a[1];b<-read.csv(file.path(p,'blocks.csv'));out<-list();j<-0
for(rate in c(.05,.025))for(age in c('fixed','staggered'))for(t in c(800,1000)){
 z<-subset(b,food_rate==rate & age_mode==age & tick==t & all9_viable);n<-nrow(z);m<-if(n)mean(z$delta) else NA_real_;h<-if(n>1)qt(.975,n-1)*sd(z$delta)/sqrt(n) else NA_real_;j<-j+1;out[[j]]<-data.frame(food_rate=rate,age_mode=age,tick=t,n=n,mean=m,lower=m-h,upper=m+h)
}
s<-do.call(rbind,out);write.csv(s,file.path(p,'viable-sensitivity.csv'),row.names=FALSE);print(s,row.names=FALSE)

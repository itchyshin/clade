a<-commandArgs(TRUE);root<-a[1];x<-read.csv(file.path(root,'demography-blocks.csv'));out<-list();j<-0
for(hi in c(600,1000))for(lo in c(300,600))if(lo<hi)for(m in setdiff(names(x),c('seed','lo','hi'))){z<-x[x$lo==lo & x$hi==hi,m];z<-z[is.finite(z)];n<-length(z);mu<-if(n)mean(z)else NA;h<-if(n>1)qt(.975,n-1)*sd(z)/sqrt(n)else NA;j<-j+1;out[[j]]<-data.frame(lo=lo,hi=hi,metric=m,n=n,mean=mu,lower=mu-h,upper=mu+h)}
y<-do.call(rbind,out);write.csv(y,file.path(root,'demography-summary.csv'),row.names=FALSE,na='NA');print(y[y$lo==600 & y$hi==1000,],row.names=FALSE)

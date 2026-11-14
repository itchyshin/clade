a<-commandArgs(TRUE);p<-a[1];b<-read.csv(file.path(p,'age-wave-blocks.csv'));o<-list();j<-0
for(t in sort(unique(b$tick)))for(m in c('fixed_advantage','staggered_advantage','staggered_minus_fixed')){z<-b[b$tick==t,m];n<-length(z);mu<-mean(z);h<-qt(.975,n-1)*sd(z)/sqrt(n);j<-j+1;o[[j]]<-data.frame(tick=t,metric=m,n=n,mean=mu,lower=mu-h,upper=mu+h)}
x<-do.call(rbind,o);write.csv(x,file.path(p,'age-wave-summary.csv'),row.names=FALSE);print(x[x$tick %in% c(250,400,600,750,850,1000),],row.names=FALSE)

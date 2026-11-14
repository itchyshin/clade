a<-commandArgs(TRUE);root<-a[1];name<-a[2];x<-read.csv(file.path(root,paste0(name,'-forage-blocks.csv')));out<-list();j<-0
for(t in sort(unique(x$tick)))for(metric in c('mixture_food_rate','control_food_rate','food_rate_difference','grass_difference')){
 z<-x[x$tick==t,metric];z<-z[is.finite(z)];n<-length(z);m<-if(n)mean(z)else NA;h<-if(n>1)qt(.975,n-1)*sd(z)/sqrt(n)else NA;j<-j+1;out[[j]]<-data.frame(tick=t,metric=metric,n=n,mean=m,lower=m-h,upper=m+h)
}
y<-do.call(rbind,out);write.csv(y,file.path(root,paste0(name,'-forage-summary.csv')),row.names=FALSE,na='NA');print(y[y$tick %in% c(300,600,1000),],row.names=FALSE)

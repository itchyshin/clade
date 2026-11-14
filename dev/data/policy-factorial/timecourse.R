a<-commandArgs(TRUE);root<-a[1];w<-read.csv(file.path(root,'windows.csv'));w<-w[w$food_rate==.05 & w$age_mode=='fixed' & w$hi %in% c(300,600,1000),];set.seed(20261114)
ans<-list();j<-0
for(p in 1:2)for(t in c(300,600,1000)){
 z<-w[w$ploidy==p & w$hi==t,];g<-split(z,z$seed);a<-do.call(rbind,lapply(g,function(x){x<-x[order(x$mono),];stopifnot(all(x$mono==0:8));c(mix=x$nend[1],control=mean(x$nend[-1]))}));d<-a[,1]-a[,2];rr<-100*(mean(a[,1])/mean(a[,2])-1);bt<-replicate(2000,{ii<-sample.int(nrow(a),replace=TRUE);100*(mean(a[ii,1])/mean(a[ii,2])-1)});q<-quantile(bt,c(.025,.975));j<-j+1;ans[[j]]<-data.frame(ploidy=p,tick=t,mix=mean(a[,1]),control=mean(a[,2]),mean_difference=mean(d),relative=rr,relative_lower=q[1],relative_upper=q[2])
};write.csv(do.call(rbind,ans),file.path(root,'baseline-timecourse.csv'),row.names=FALSE)
changes<-list()
for(p in 1:2){
 one<-function(t){z<-w[w$ploidy==p & w$hi==t,];g<-split(z,z$seed);vapply(g,function(x){x<-x[order(x$mono),];x$nend[1]-mean(x$nend[-1])},numeric(1))}
 d<-one(1000)-one(300);n<-length(d);h<-qt(.975,n-1)*sd(d)/sqrt(n)
 changes[[p]]<-data.frame(ploidy=p,n=n,mean=mean(d),lower=mean(d)-h,upper=mean(d)+h)
}
write.csv(do.call(rbind,changes),file.path(root,'baseline-time-change.csv'),row.names=FALSE)

a<-commandArgs(TRUE);root<-a[1];b<-read.csv(file.path(root,'blocks.csv'));a1<-b[b$tick==1000,];z<-b[b$tick==600,];a1<-a1[order(a1$seed),];z<-z[order(z$seed),];stopifnot(identical(a1$seed,z$seed));out<-list();j<-0
for(m in c('advantage','composition','residual','effective_policies','grass_mix','density_mix')){d<-a1[[m]]-z[[m]];d<-d[is.finite(d)];n<-length(d);h<-qt(.975,n-1)*sd(d)/sqrt(n);j<-j+1;out[[j]]<-data.frame(metric=m,n=n,mean=mean(d),lower=mean(d)-h,upper=mean(d)+h)}
write.csv(do.call(rbind,out),file.path(root,'changes-600-1000.csv'),row.names=FALSE)

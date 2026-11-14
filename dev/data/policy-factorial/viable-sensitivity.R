a<-commandArgs(TRUE);root<-a[1];b<-read.csv(file.path(root,'blocks.csv'));b<-b[b$metric=='population',];ans<-list();j<-0
for(p in 1:2)for(f in c(.05,.025,.0125)){
 a<-b[b$ploidy==p & b$food_rate==f & b$age_mode=='staggered',];q<-b[b$ploidy==p & b$food_rate==f & b$age_mode=='fixed',];a<-a[order(a$seed),];q<-q[order(q$seed),];ok<-a$all9_viable & q$all9_viable;d<-a$delta[ok]-q$delta[ok];n<-length(d);se<-if(n>1)sd(d)/sqrt(n) else NA;h<-if(n>1)qt(.975,n-1)*se else NA;j<-j+1;ans[[j]]<-data.frame(ploidy=p,food_rate=f,n=n,mean=if(n)mean(d) else NA,lower=if(n)mean(d)-h else NA,upper=if(n)mean(d)+h else NA)
};write.csv(do.call(rbind,ans),file.path(root,'viable-sensitivity.csv'),row.names=FALSE)

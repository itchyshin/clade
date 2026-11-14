a<-commandArgs(TRUE);root<-a[1];r<-read.csv(file.path(root,'runs.csv'),stringsAsFactors=FALSE)
parse<-function(x)as.integer(strsplit(x,':',fixed=TRUE)[[1]])
effective<-function(x){v<-parse(x);n<-sum(v);if(!n)NA_real_ else 1/sum((v/n)^2)}
r$effective<-vapply(r$policy_counts,effective,numeric(1));r$present<-vapply(r$policy_counts,function(x)sum(parse(x)>0),integer(1))
r$effective_after<-vapply(r$counts_after,effective,numeric(1));r$present_after<-vapply(r$counts_after,function(x)sum(parse(x)>0),integer(1))
out<-list();j<-0
for(t in sort(unique(r$tick)))for(mode in c('natural','shuffle','balanced'))for(m in c('effective','present','effective_after','present_after')){
 z<-r[r$tick==t & r$mode==mode,m];z<-z[is.finite(z)];n<-length(z);mu<-if(n)mean(z) else NA;h<-if(n>1)qt(.975,n-1)*sd(z)/sqrt(n)else NA;j<-j+1;out[[j]]<-data.frame(tick=t,mode=mode,metric=m,n=n,mean=mu,lower=mu-h,upper=mu+h)
};x<-do.call(rbind,out);write.csv(x,file.path(root,'policy-summary.csv'),row.names=FALSE);print(x[x$tick %in% c(600,650,800,1000) & x$metric %in% c('effective','effective_after'),],row.names=FALSE)

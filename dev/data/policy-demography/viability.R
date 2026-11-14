a<-commandArgs(TRUE);p<-a[1];source('R/analysis.R');r<-read.csv(file.path(p,'runs.csv'));out<-list();j<-0
for(s in 20001:20100)for(m in c('natural','shuffle','balanced')){x<-r[r$seed==s & r$mode==m,];x<-x[order(x$tick),];q<-viability_report(data.frame(t=c(0,x$tick),n_agents=c(48,x$n)),n_agents_init=48);j<-j+1;out[[j]]<-data.frame(seed=s,mode=m,verdict=q$verdict,n_final=q$n_final,n_min_checkpoint=q$n_min)}
v<-do.call(rbind,out);write.csv(v,file.path(p,'viability.csv'),row.names=FALSE);print(table(v$mode,v$verdict));print(range(v$n_min_checkpoint))

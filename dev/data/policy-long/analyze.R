a<-commandArgs(TRUE); root<-a[1];source('R/analysis.R')
r<-read.csv(file.path(root,'runs.csv'));w<-read.csv(file.path(root,'windows.csv'))
key<-function(x)do.call(paste,c(x[c('ploidy','food_rate','seed','mono')],sep=':'))
e<-expand.grid(ploidy=1:2,food_rate=c(.025,.0125),seed=20001:20100,mono=0:8)
stopifnot(nrow(r)==3600,!anyDuplicated(key(r)),setequal(key(r),key(e)),nrow(w)==72000)
wk<-key(w);wg<-split(seq_len(nrow(w)),wk);r$viability<-NA_character_
for(i in seq_len(nrow(r))) {
 z<-w[wg[[key(r[i,])]],];z<-z[order(z$lo),]
 stopifnot(nrow(z)==20,all(z$lo==seq(1,1000,50)),all(z$hi==z$lo+49),z$nstart[1]==48,
  all(z$nend==z$nstart+z$births-z$deaths),all(z$pre_exposure==z$post_exposure+z$nstart-z$nend),
  all(z$nstart[-1]==head(z$nend,-1)),tail(z$nend,1)==r$final_agents[i],sum(z$pre_exposure)==r$exposure[i],sum(z$births)==r$births[i],sum(z$deaths)==r$deaths[i],abs(sum(z$food)-r$food[i])<1e-6,abs(sum(z$net)-r$net[i])<1e-5)
 r$viability[i]<-viability_report(data.frame(t=c(r$tick_of_min[i],r$final_tick[i]),n_agents=c(r$min_population[i],r$final_agents[i])),n_agents_init=48)$verdict
}
write.csv(r,file.path(root,'runs_viability.csv'),row.names=FALSE)
blocks<-list();j<-0
for(ix in split(seq_len(nrow(r)),paste(r$ploidy,r$food_rate,r$seed))) {
 z<-r[ix,]; stopifnot(nrow(z)==9,setequal(z$mono,0:8));mix<-z[z$mono==0,];control<-z[z$mono>0,];
 for(tick in c(300,600,1000)){
  ww<-w[wk%in%key(z) & w$hi==tick,];ww<-ww[order(ww$mono),];stopifnot(nrow(ww)==9,identical(as.integer(ww$mono),0:8))
  for(metric in c('population','extinct')) {
   values<-if(metric=='population')ww$nend else as.numeric(ww$nend==0)
   j<-j+1;blocks[[j]]<-data.frame(ploidy=mix$ploidy,food_rate=mix$food_rate,seed=mix$seed,tick=tick,metric=metric,mix=values[1],control=mean(values[-1]),delta=values[1]-mean(values[-1]),all_viable=all(z$viability=='viable'))
  }
 }
}
b<-do.call(rbind,blocks);write.csv(b,file.path(root,'blocks.csv'),row.names=FALSE)
set.seed(20261114);out<-list();j<-0
for(ix in split(seq_len(nrow(b)),interaction(b$ploidy,b$food_rate,b$tick,b$metric,drop=TRUE))){
 z0<-b[ix,];for(guard in c('all','all9_viable')){
 z<-if(guard=='all')z0 else z0[z0$all_viable,];n<-nrow(z);m<-if(n)mean(z$delta)else NA;se<-if(n>1)sd(z$delta)/sqrt(n)else NA;h<-if(n>1)qt(.975,n-1)*se else NA
 rel<-lo<-hi<-NA_real_;if(n>1&&mean(z$control)>0&&z0$metric[1]=='population'){
 rel<-100*(mean(z$mix)/mean(z$control)-1);bt<-replicate(2000,{i<-sample.int(n,n,TRUE);d<-mean(z$control[i]);if(d>0)100*(mean(z$mix[i])/d-1)else NA_real_});q<-quantile(bt,c(.025,.975),na.rm=TRUE);lo<-q[1];hi<-q[2]}
 j<-j+1;out[[j]]<-data.frame(ploidy=z0$ploidy[1],food_rate=z0$food_rate[1],tick=z0$tick[1],metric=z0$metric[1],guard=guard,n=n,all9_viable=sum(z0$all_viable),mix=if(n)mean(z$mix)else NA,control=if(n)mean(z$control)else NA,mean=m,lower=m-h,upper=m+h,relative=rel,relative_lower=lo,relative_upper=hi)
 }}
s<-do.call(rbind,out);write.csv(s,file.path(root,'summary.csv'),row.names=FALSE);print(with(r,table(ploidy,food_rate,viability)));print(s[s$tick==1000 & s$guard=='all',],row.names=FALSE)

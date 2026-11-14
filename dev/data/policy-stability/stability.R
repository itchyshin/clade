a<-commandArgs(TRUE);p<-a[1];s<-read.csv(file.path(p,'sources_viability.csv'));r<-read.csv(file.path(p,'runs_viability.csv'));b<-read.csv(file.path(p,'blocks.csv'))
cat('Source runs:',nrow(s),'stable throughout:',sum(s$min_population>=20),'endpoint viable:',sum(s$viability=='viable'),'cap ticks:',sum(s$source_cap_ticks),'min range:',range(s$min_population),'peak max:',max(s$source_max),'\n')
cat('Assay runs:',nrow(r),'stable throughout:',sum(r$min_population>=20),'endpoint viable:',sum(r$viability=='viable'),'cap ticks:',sum(r$cap_ticks),'min range:',range(r$min_population),'peak max:',max(r$max_population),'\n')
print(with(r,table(food_rate,age_mode,stable)));print(with(r,table(food_rate,age_mode,viability)));print(aggregate(cbind(cap_ticks,max_population,min_population)~food_rate+age_mode,r,function(x)mean(x)))
seeds<-split(r,r$seed);v<-vapply(seeds,function(z)all(z$stable),logical(1));cat('Blocks with all 36 stable:',sum(v),'/',length(v),'\n')
sourceok<-s$seed[s$min_population>=20];both<-as.integer(names(v)[v]);fully<-intersect(sourceok,both);cat('Blocks with source and all 36 stable:',length(fully),'/',length(seeds),'\n')
out<-list();j<-0
for(rate in c(.05,.025))for(age in c('fixed','staggered'))for(t in c(800,1000)){
 z<-subset(b,food_rate==rate & age_mode==age & tick==t & seed %in% fully);n<-nrow(z);m<-if(n)mean(z$delta) else NA_real_;h<-if(n>1)qt(.975,n-1)*sd(z$delta)/sqrt(n) else NA_real_;j<-j+1;out[[j]]<-data.frame(food_rate=rate,age_mode=age,tick=t,n=n,mean=m,lower=m-h,upper=m+h)
};write.csv(do.call(rbind,out),file.path(p,'stable-block-sensitivity.csv'),row.names=FALSE);print(do.call(rbind,out),row.names=FALSE)

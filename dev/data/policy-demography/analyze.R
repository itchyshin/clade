a<-commandArgs(TRUE);p<-a[1];r<-read.csv(file.path(p,'runs.csv'),stringsAsFactors=FALSE);prior<-read.csv(file.path(p,'prior-runs.csv'),stringsAsFactors=FALSE)
key<-function(x)paste(x$seed,x$mode,x$tick,sep=':');expected<-expand.grid(seed=20001:20100,mode=c('natural','shuffle','balanced'),tick=seq(50,1000,50))
stopifnot(nrow(r)==6000,nrow(prior)==6000,!anyDuplicated(key(r)),setequal(key(r),key(expected)),setequal(key(r),key(prior)))
r<-r[order(key(r)),];prior<-prior[order(key(prior)),];stopifnot(identical(key(r),key(prior)))
for(col in names(prior))stopifnot(identical(as.character(r[[col]]),as.character(prior[[col]])))
parse<-function(x)as.integer(strsplit(x,':',fixed=TRUE)[[1]])
for(type in c('births_parent_age','deaths_age','exposure_age'))for(j in 1:4)r[[paste0(type,j)]]<-vapply(r[[type]],function(x)parse(x)[j],integer(1))
r$births<-rowSums(r[paste0('births_parent_age',1:4)]);r$deaths<-rowSums(r[paste0('deaths_age',1:4)]);r$net<-r$births-r$deaths
for(seed in 20001:20100)for(mode in c('natural','shuffle','balanced')){x<-r[r$seed==seed & r$mode==mode,];x<-x[order(x$tick),];stopifnot(all(x$net==diff(c(48,x$n))))}
vars<-c('n','births','deaths','net',paste0('births_parent_age',1:4),paste0('deaths_age',1:4),paste0('exposure_age',1:4))
s<-r[r$mode=='shuffle',c('seed','tick',vars)];b<-r[r$mode=='balanced',c('seed','tick',vars)];z<-merge(b,s,by=c('seed','tick'),suffixes=c('_balanced','_shuffle'));stopifnot(nrow(z)==2000)
for(v in vars)z[[paste0(v,'_diff')]]<-z[[paste0(v,'_balanced')]]-z[[paste0(v,'_shuffle')]]
write.csv(z,file.path(p,'blocks.csv'),row.names=FALSE)
rows<-list();j<-0
for(t in c(650,700,750,800,850,900,950,1000))for(period in c('interval','cumulative'))for(v in vars){
 if(v=='n' && period=='cumulative')next
 subset<-if(period=='interval') z[z$tick==t,] else z[z$tick>600 & z$tick<=t,]
 mat<-sapply(20001:20100,function(seed){w<-subset[subset$seed==seed,];c(sum(w[[paste0(v,'_balanced')]]),sum(w[[paste0(v,'_shuffle')]]))})
 d<-mat[1,]-mat[2,];n<-length(d);h<-qt(.975,n-1)*sd(d)/sqrt(n);j<-j+1
 rows[[j]]<-data.frame(tick=t,period=period,metric=v,n=n,balanced=mean(mat[1,]),shuffle=mean(mat[2,]),difference=mean(d),lower=mean(d)-h,upper=mean(d)+h)
}
out<-do.call(rbind,rows);write.csv(out,file.path(p,'summary.csv'),row.names=FALSE)
print(out[out$tick %in% c(650,700,750,800,1000) & out$metric %in% c('n','births','deaths','net') & (out$period=='interval'|out$tick%in%c(800,1000)),],row.names=FALSE)
print(out[out$tick==800 & out$period=='cumulative' & grepl('births_parent_age|deaths_age|exposure_age',out$metric),],row.names=FALSE)

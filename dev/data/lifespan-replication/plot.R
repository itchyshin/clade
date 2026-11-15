a<-commandArgs(TRUE);p<-a[1];old<-read.csv(a[2]);pair<-read.csv(file.path(p,'paired','effects.csv'));fresh<-read.csv(file.path(p,'fresh','effects.csv'))
old$study<-'300 ticks / matched';pair$study<-'400 ticks / matched';fresh$study<-'400 ticks / new seeds';z<-rbind(old,pair,fresh)
z<-z[z$cohort=='all' & z$contrast=='interaction' & z$metric %in% c('pop','birth_age1','birth_age4'),]
stopifnot(nrow(z)==18)
png(file.path(p,'lifespan-comparison.png'),width=1500,height=720,res=140)
par(mfrow=c(1,3),mar=c(8,4,3,1))
for(metric in c('pop','birth_age1','birth_age4')) {
 x<-z[z$metric==metric,];ylim<-range(c(x$lower,x$upper,0),finite=TRUE);ttl<-switch(metric,pop='Final population',birth_age1='Births: parents under 50',birth_age4='Births: parents 150 or older')
 plot(NA,xlim=c(.5,3.5),ylim=ylim,xaxt='n',xlab='',ylab='Food-by-threshold interaction',main=ttl);axis(1,at=1:3,labels=c('300 / matched','400 / matched','400 / new'),las=2,cex.axis=.75);abline(h=0,col='grey60',lty=2)
 for(age in c('fixed','staggered')){
  s<-x[x$age==age,];s<-s[match(c('300 ticks / matched','400 ticks / matched','400 ticks / new seeds'),s$study),];off<-if(age=='fixed') -.12 else .12;col<-if(age=='fixed') '#176a88' else '#ad5d32';xx<-1:3+off
  segments(xx,s$lower,xx,s$upper,col=col);segments(xx-.04,s$lower,xx+.04,s$lower,col=col);segments(xx-.04,s$upper,xx+.04,s$upper,col=col);points(xx,s$mean,pch=if(age=='fixed')16 else 17,col=col,cex=1.1)
 }
 if(metric=='pop')legend('bottomleft',c('Same-age founders','Staggered founders'),col=c('#176a88','#ad5d32'),pch=c(16,17),bty='n',cex=.7)
}
dev.off()

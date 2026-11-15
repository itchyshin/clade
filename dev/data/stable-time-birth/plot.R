args<-commandArgs(TRUE);p<-args[1];z<-read.csv(file.path(p,'effects.csv'))
png(file.path(p,'birth-incidence.png'),width=1400,height=1000,res=150)
par(mfrow=c(2,2),mar=c(4,4,3,1))
for(age in c('fixed','staggered')) for(food in c(.05,.025)) {
 plot(NA,xlim=c(0,100),ylim=c(0,1),xlab='Young reproductive opportunities blocked (%)',ylab='Probability of birth within 50 ticks',main=paste(if(age=='fixed') 'Same-age founders' else 'Staggered founders',if(food==.05) ' / original food' else ' / limited food'))
 for(group in c('birth_mix','birth_control')) {
  x<-z[z$age==age & z$food==food & z$cohort=='all' & z$metric==group & z$contrast=='absolute',];x<-x[order(x$dose),]
  col<-if(group=='birth_mix') '#176a88' else '#ad5d32';lo<-pmax(0,x$lower);hi<-pmin(1,x$upper);ok<-hi>lo+1e-12
  if(any(ok)) {segments(x$dose[ok],lo[ok],x$dose[ok],hi[ok],col=col);segments(x$dose[ok]-1,lo[ok],x$dose[ok]+1,lo[ok],col=col);segments(x$dose[ok]-1,hi[ok],x$dose[ok]+1,hi[ok],col=col)}
  lines(x$dose,x$mean,type='b',pch=if(group=='birth_mix') 16 else 17,col=col,lwd=2)
 }
 legend('bottomleft',legend=c('Mixture','Mean single-policy controls'),col=c('#176a88','#ad5d32'),pch=c(16,17),lty=1,bty='n',cex=.75)
}
dev.off()

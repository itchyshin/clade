a<-commandArgs(TRUE);p<-a[1];x<-read.csv(file.path(p,'summary.csv'))
png(file.path(p,'long-mixture.png'),width=1400,height=1000,res=150)
par(mfrow=c(2,2),mar=c(4,5,3,1),oma=c(0,0,2,0))
for(pl in 1:2)for(rate in c(.025,.0125)){
 z<-x[x$ploidy==pl & x$food_rate==rate & x$metric=='population' & x$guard=='all',];z<-z[order(z$tick),]
 plot(z$tick,z$mean,type='b',pch=19,ylim=range(c(z$lower,z$upper,0)),xlab='Tick',ylab='Mixture minus balanced controls (agents)',main=paste(if(pl==1)'Haploid' else 'Diploid',', regrowth',rate))
 segments(z$tick,z$lower,z$tick,z$upper,lwd=2);abline(h=0,lty=2,col='grey60')
}
mtext('100 matched seed blocks; 95% t intervals; all populations included',outer=TRUE,cex=.85)
dev.off()

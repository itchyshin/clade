a<-commandArgs(TRUE);p<-a[1];s<-read.csv(file.path(p,'summary.csv'));png(file.path(p,'reversal.png'),width=1500,height=1100,res=150)
par(mfrow=c(2,2),mar=c(4,5,3,1),oma=c(0,0,2,0))
linepair<-function(m1,m2,title,ylab,labs){
 a<-s[s$metric==m1,];b<-s[s$metric==m2,];plot(a$tick,a$mean,type='l',lwd=2,col='#167D9A',ylim=range(c(a$lower,a$upper,b$lower,b$upper),na.rm=TRUE),xlab='Tick',ylab=ylab,main=title);lines(b$tick,b$mean,col='#B45B24',lwd=2,lty=2);legend('topright',labs,col=c('#167D9A','#B45B24'),lty=c(1,2),lwd=2,bty='n',cex=.8)
}
linepair('n_mix','n_control','Population','Agents',c('Mixture','Mean control'))
linepair('grass_mix','grass_control','Standing food','Grass per cell',c('Mixture','Mean control'))
linepair('surviving_policies','effective_policies','Policy concentration','Number of policies',c('Present','Effective'))
a<-s[s$metric=='advantage',];b<-s[s$metric=='composition',];c<-s[s$metric=='residual',];plot(a$tick,a$mean,type='l',lwd=2,ylim=range(c(a$mean,b$mean,c$mean,0)),xlab='Tick',ylab='Population difference',main='Accounting identity');lines(b$tick,b$mean,col='#167D9A',lwd=2);lines(c$tick,c$mean,col='#B45B24',lwd=2,lty=2);abline(h=0,col='grey60',lty=3);legend('topright',c('Total advantage','Composition association','Remainder'),col=c('black','#167D9A','#B45B24'),lty=c(1,1,2),lwd=2,bty='n',cex=.75)
mtext('Original food, fixed-age haploids | 100 matched seed blocks',outer=TRUE,cex=.9);dev.off()

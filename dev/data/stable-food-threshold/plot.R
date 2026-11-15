args<-commandArgs(TRUE);p<-args[1];z<-read.csv(file.path(p,'effects.csv'))
z<-z[z$cohort=='all' & z$contrast=='interaction' & z$metric %in% c('pop200','pop400','pop600','pop800','pop'),]
z$tick<-as.integer(sub('pop','',ifelse(z$metric=='pop','pop1000',z$metric)));yl<-range(c(z$lower,z$upper,0),finite=TRUE)
png(file.path(p,'interaction-over-time.png'),width=1300,height=800,res=150)
par(mar=c(4.5,5,2.5,1));plot(NA,xlim=c(160,1040),ylim=yl,xlab='Simulation tick',ylab='Food-by-threshold interaction (individuals)',main='Mixture population relative to balanced controls');abline(h=0,col='grey60',lty=2)
for(age in c('fixed','staggered')) {
 x<-z[z$age==age,];x<-x[order(x$tick),];col<-if(age=='fixed') '#176a88' else '#ad5d32';off<-if(age=='fixed') -8 else 8
 segments(x$tick+off,x$lower,x$tick+off,x$upper,col=col);segments(x$tick+off-3,x$lower,x$tick+off+3,x$lower,col=col);segments(x$tick+off-3,x$upper,x$tick+off+3,x$upper,col=col)
 lines(x$tick+off,x$mean,type='b',pch=if(age=='fixed') 16 else 17,col=col,lwd=2)
}
legend('topleft',legend=c('Same-age founders','Staggered founders'),col=c('#176a88','#ad5d32'),pch=c(16,17),lty=1,bty='n')
dev.off()

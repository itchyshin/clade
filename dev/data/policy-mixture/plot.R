a<-commandArgs(TRUE);out<-a[1];x<-read.csv(file.path(out,'summary.csv'))
png(file.path(out,'policy-mixture.png'),width=1600,height=1150,res=160)
par(mfrow=c(2,2),mar=c(4,5,3,1),oma=c(0,0,2,0))
for(j in 1:4) {
 metric<-c('food_rate','net_rate','birth_yield','final_agents')[j]
 mode<-if(j<=2)'forage' else 'demography'
 d<-x[x$metric==metric & x$mode==mode & x$guard=='all_blocks',];d<-d[order(d$ploidy,d$source_mutation),]
 if(j==2){y<-d$mean;lo<-d$lower;hi<-d$upper;yl<-'Net energy difference per agent tick'} else {y<-d$relative_percent;lo<-d$relative_lower;hi<-d$relative_upper;yl<-'Change from balanced controls (%)'}
 plot(1:6,y,ylim=range(c(lo,hi,0),na.rm=TRUE),pch=19,col=rep(c('#167D9A','#B45B24'),each=3),xaxt='n',xlab='',ylab=yl,main=c('Equal-density food intake','Equal-density energy gain','Demographic birth yield','Demographic final population')[j])
 segments(1:6,lo,1:6,hi,lwd=2,col=rep(c('#167D9A','#B45B24'),each=3));abline(h=0,lty=2,col='grey60')
 axis(1,1:6,c('Hap 0','.05','.20','Dip 0','.05','.20'))
}
mtext('Mixture minus mean of all eight monocultures | 100 seed blocks per cell | 95% intervals',outer=TRUE,cex=.85)
dev.off()

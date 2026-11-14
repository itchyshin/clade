a<-commandArgs(TRUE);out<-a[1];x<-read.csv(file.path(out,'factorial_summary.csv'))
png(file.path(out,'factorial.png'),width=1500,height=1050,res=150)
par(mfrow=c(2,2),mar=c(4,5,3,1),oma=c(0,0,2,0))
for(metric in c('population','extinct'))for(p in 1:2){
 d<-x[x$type=='cell' & x$metric==metric & x$ploidy==p,];rate<-c(.05,.025,.0125);ages<-c('fixed','staggered');factor<-if(metric=='extinct')100 else 1
 d$pos<-match(as.numeric(sub(' .*','',d$label)),rate)+ifelse(grepl('staggered',d$label),.08,-.08)
 plot(d$pos,d$mean*factor,ylim=range(c(d$lower,d$upper,0)*factor),xlim=c(.7,3.3),xaxt='n',xlab='Food regime: initial grass / regrowth',ylab=if(metric=='population')'Mixture advantage (agents)' else 'Extinction difference (percentage points)',main=if(p==1)'Haploid' else 'Diploid',pch=ifelse(grepl('staggered',d$label),17,16),col=ifelse(grepl('staggered',d$label),'#B45B24','#167D9A'))
 segments(d$pos,d$lower*factor,d$pos,d$upper*factor,col=ifelse(grepl('staggered',d$label),'#B45B24','#167D9A'),lwd=2);abline(h=0,lty=2,col='grey60');axis(1,1:3,c('.50 / .05','.25 / .025','.25 / .0125'))
 if(metric=='population' && p==1)legend('topright',c('Fixed age 50','Ages 25–72'),col=c('#167D9A','#B45B24'),pch=c(16,17),bty='n',cex=.8)
}
mtext('Mixture minus mean of eight controls at tick 1,000 | 100 matched seeds | 95% intervals',outer=TRUE,cex=.85)
dev.off()

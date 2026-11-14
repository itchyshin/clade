args <- commandArgs(TRUE)
out <- args[1]
x <- read.csv(file.path(out, 'paired_contrasts.csv'))
png(file.path(out, 'performance-ploidy.png'), width=1500, height=1100, res=160)
par(mfrow=c(2,2), mar=c(4,4.8,3,1), oma=c(0,0,2,0))
metrics <- c('garden_food','late_food','late_birth_yield','late_survival100')
titles <- c('Standardized food intake','Food intake in populations','Births per agent time','Offspring surviving 100 ticks')
for (j in seq_along(metrics)) {
 d <- x[x$metric==metrics[j],]; d <- d[order(d$ploidy,d$mutation_sd),]
 if (j==4) {y<-100*d$mean; lo<-100*d$lower; hi<-100*d$upper; yl<-'Change (percentage points)'} else {
 y<-d$relative_percent;lo<-d$relative_lower;hi<-d$relative_upper;yl<-'Change from mutation SD 0 (%)'
 }
 plot(seq_len(nrow(d)),y,ylim=range(c(lo,hi,0)),xaxt='n',xlab='',ylab=yl,main=titles[j],pch=19,col=rep(c('#167D9A','#B45B24'),each=2))
 abline(h=0,col='grey60',lty=2)
 segments(seq_along(y),lo,seq_along(y),hi,lwd=2,col=rep(c('#167D9A','#B45B24'),each=2))
 axis(1,1:4,c('Hap .05','Hap .20','Dip .05','Dip .20'))
}
mtext('Corrected reproduction kernel | 100 matched viable seed pairs per contrast | 95% intervals',outer=TRUE,cex=.85)
dev.off()

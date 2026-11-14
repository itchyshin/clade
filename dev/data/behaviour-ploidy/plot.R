a<-commandArgs(trailingOnly=TRUE);stopifnot(length(a)==1L);out<-a[1]
s<-read.csv(file.path(out,"cell_summary.csv"))
png(file.path(out,"behaviour-ploidy.png"),width=1800,height=1500,res=180)
par(mfrow=c(2,2),mar=c(4.2,4.8,3,1),oma=c(0,0,2,0))
metrics<-c("genetic_diversity_viable","between_viable","within_viable","behavioral_entropy_last100_viable")
titles<-c("Inherited genetic variation","Differences between individuals","Randomness within individuals","Population action entropy")
labels<-c("Mean genetic-weight distance","RMS difference in choice probabilities","Probability repeated choices disagree","Mean action entropy (nats)")
cols<-c("#0072B2","#D55E00")
for(j in seq_along(metrics)) {
 z<-s[s$metric==metrics[j],]
 if(j==2){stopifnot(all(z$lower>0));for(n in c("mean","lower","upper"))z[[n]]<-sqrt(2*z[[n]]/5)}
 top<-if(j==4)log(5)*1.08 else max(z$upper)*1.2
 plot(NA,xlim=c(-.005,.205),ylim=c(0,top),xlab="Offspring mutation SD",ylab=labels[j],main=titles[j])
 for(p in 1:2) {
  x<-z[z$ploidy==p,];x<-x[order(x$mutation_sd),]
  lines(x$mutation_sd,x$mean,type="b",pch=c(16,17)[p],col=cols[p],lwd=2)
  segments(x$mutation_sd,x$lower,x$mutation_sd,x$upper,col=cols[p])
  segments(x$mutation_sd-.0015,x$lower,x$mutation_sd+.0015,x$lower,col=cols[p])
  segments(x$mutation_sd-.0015,x$upper,x$mutation_sd+.0015,x$upper,col=cols[p])
 }
 if(j==1)legend("topleft",c("Haploid","Diploid, selfing allowed"),col=cols,pch=c(16,17),lty=1,bty="n",cex=.75)
 if(j==4)abline(h=log(5),lty=3,col="grey50")
 mtext(if(min(z$n)==max(z$n))paste0(z$n[1]," viable seeds per cell") else
  paste0("Viable seeds per cell: ",min(z$n)," to ",max(z$n)),side=3,line=.25,cex=.65)
}
mtext("Matched founders and fixed exploration; 95% Monte Carlo intervals",outer=TRUE,cex=1)
dev.off()

# From repo root: Rscript dev/data/matched-founders/plot.R OUTDIR
args <- commandArgs(trailingOnly=TRUE)
stopifnot(length(args)==1L)
out <- args[1L]
s <- read.csv(file.path(out,"cell_summary.csv"))
png(file.path(out,"matched-founders.png"),width=1800,height=1500,res=180)
par(mfrow=c(2,2),mar=c(4.2,4.4,3,1),oma=c(0,0,2,0))
cols <- c("#0072B2","#E69F00","#009E73")
diversity_max <- max(s$upper[s$exploration=="fixed" & s$metric=="final_diversity"],na.rm=TRUE)
for (world in c("benign","costly")) for (metric in c("final_diversity","viable")) {
  z <- s[s$exploration=="fixed" & s$world==world & s$metric==metric,]
  y <- if(metric=="viable") c(0,1.12) else c(0,diversity_max*1.18)
  plot(NA,xlim=c(-.01,.21),ylim=y,xlab="Offspring mutation SD",
    ylab=if(metric=="viable") "Fraction viable (all 100 seeds)" else "Genetic distance (N >= 2)",
    main=paste(if(world=="benign") "Low movement cost" else "High movement cost"))
  for (i in 1:3) {
    x <- z[z$founder_sd==c(0,.05,.2)[i],]; x <- x[order(x$mutation_sd),]
    lines(x$mutation_sd,x$mean,type="b",pch=c(16,17,15)[i],col=cols[i],lwd=2)
    varied <- is.finite(x$lower) & is.finite(x$upper) & x$lower < x$upper
    arrows(x$mutation_sd[varied],x$lower[varied],x$mutation_sd[varied],x$upper[varied],
      angle=90,code=3,length=.035,col=cols[i])
  }
  if(world=="benign" && metric=="final_diversity") legend("topleft",
    legend=c("Founder SD 0","Founder SD 0.05","Founder SD 0.20"),
    col=cols,pch=c(16,17,15),lty=1,bty="n",cex=.75)
  if(metric=="final_diversity") mtext(if(world=="benign") "100 eligible seeds per cell" else
    "87 to 91 eligible out of 100 seeds per cell",side=3,line=.25,cex=.65)
}
mtext("Matched founders: fixed exploration; means and 95% Monte Carlo intervals",outer=TRUE,cex=1)
dev.off()

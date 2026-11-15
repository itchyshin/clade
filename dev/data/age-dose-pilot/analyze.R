args <- commandArgs(TRUE)
p <- args[1]
d <- read.csv(file.path(p,'individual-summary.csv'))
d <- subset(d, seed >= 81001 & seed <= 81005)
stopifnot(nrow(d)==900)
# The seed, not the simulation or its individual events, is the independent unit.
mean_ci <- function(x) {
 x <- x[is.finite(x)]; n <- length(x)
 if(n<2) return(c(mean=if(n) mean(x) else NA,lo=NA,hi=NA,n=n))
 m <- mean(x); h <- qt(.975,n-1)*sd(x)/sqrt(n)
 c(mean=m,lo=m-h,hi=m+h,n=n)
}
rows <- list(); i <- 0
for(q in c(80,120)) for(food in c(.05,.025)) for(group in c("mixture","control")) for(dose in c(0,25,50,75,100)) {
 x <- d[d$threshold==q & d$food==food & d$dose==dose & if(group=="mixture") d$mono==0 else d$mono>0, ]
 for(seed in 81001:81005) {
  z <- x[x$seed==seed,]; stopifnot(nrow(z)==if(group=="mixture") 1 else 8)
  i <- i+1; rows[[i]] <- data.frame(seed,q,food,group,dose,final=mean(z$final),young_births=mean(z$young_births),all_births=mean(z$births),eligible=sum(z$eligible),blocked=sum(z$blocked),followed=sum(z$followed_50),later_birth=sum(z$subsequent_birth_50),energy_before=sum(z$blocked_energy_before),energy_after=sum(z$blocked_energy_after))
 }
}
b <- do.call(rbind,rows); write.csv(b,file.path(p,"seed-summary.csv"),row.names=FALSE)
res <- list(); i <- 0
for(q in c(80,120)) for(food in c(.05,.025)) for(group in c("mixture","control")) for(dose in c(0,25,50,75,100)) {
 x <- b[b$q==q & b$food==food & b$group==group & b$dose==dose, ]; base <- b[b$q==q & b$food==food & b$group==group & b$dose==0, ]; x<-x[order(x$seed),];base<-base[order(base$seed),];stopifnot(identical(x$seed,base$seed))
 for(metric in c("young_births","all_births","final")) {
  z<-mean_ci(x[[metric]]-base[[metric]]); i<-i+1;res[[i]]<-data.frame(q,food,group,dose,metric,estimate=z[1],lower=z[2],upper=z[3],n=z[4])
 }
}
write.csv(do.call(rbind,res),file.path(p,"paired-effects.csv"),row.names=FALSE)
cat("5 independent source blocks; 900 pilot assays; paired t intervals are exploratory.\n")

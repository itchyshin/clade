args <- commandArgs(TRUE); p <- args[1]
r <- read.csv(file.path(p,'runs.csv')); t <- read.csv(file.path(p,'timing.csv'))
stopifnot(!anyDuplicated(r[c('seed','dose','food','age_mode','mono')]),nrow(t)==2*nrow(r))
seeds <- sort(unique(r$seed)); stopifnot(length(seeds)==100,identical(seeds,83001:83100))
stopifnot(nrow(r)==180*length(seeds),all(t$n>0),all(is.finite(t$cif_birth50)))
ci <- function(x) {
 stopifnot(length(x)==100,all(is.finite(x)))
 m <- mean(x); h <- qt(.975,length(x)-1)*sd(x)/sqrt(length(x))
 c(mean=m,lower=m-h,upper=m+h)
}
rr <- list();j <- 0
for(seed in seeds) for(food in c(.05,.025)) for(age in c('fixed','staggered')) for(dose in c(0,25,50,75,100)) {
 x <- r[r$seed==seed & r$food==food & r$age_mode==age & r$dose==dose,];stopifnot(nrow(x)==9,setequal(x$mono,0:8));x<-x[order(x$mono),]
 for(cohort in c('all','complete')) {
  a <- t[t$seed==seed & t$food==food & t$age_mode==age & t$dose==dose & t$cohort==cohort,];stopifnot(nrow(a)==9,setequal(a$mono,0:8));a<-a[order(a$mono),]
  j<-j+1;rr[[j]]<-data.frame(seed,food,age,dose,cohort,pop_mix=x$final[1],pop_control=mean(x$final[-1]),births_mix=x$births[1],births_control=mean(x$births[-1]),birth_mix=a$cif_birth50[1],birth_control=mean(a$cif_birth50[-1]),death_mix=a$cif_death50[1],death_control=mean(a$cif_death50[-1]),energy_entry_mix=a$energy_at_entry[1],energy_birth_mix=a$energy_at_birth[1],mix_n=a$n[1],censor_before50=a$censored_before50[1])
 }
}
b<-do.call(rbind,rr);b$pop_delta<-b$pop_mix-b$pop_control;b$birth_delta<-b$birth_mix-b$birth_control
write.csv(b,file.path(p,'seed-summary.csv'),row.names=FALSE)
result<-list();j<-0
for(food in c(.05,.025)) for(age in c('fixed','staggered')) for(cohort in c('all','complete')) for(dose in c(0,25,50,75,100)) {
 x<-b[b$food==food & b$age==age & b$cohort==cohort & b$dose==dose,];x<-x[order(x$seed),]
 z<-b[b$food==food & b$age==age & b$cohort==cohort & b$dose==0,];z<-z[order(z$seed),];stopifnot(identical(x$seed,z$seed))
 for(metric in c('pop_mix','pop_control','pop_delta','births_mix','births_control','birth_mix','birth_control','birth_delta','death_mix','energy_entry_mix','energy_birth_mix')) {
  for(contrast in c('absolute','difference_vs_sham')) {
   v<-x[[metric]];if(contrast=='difference_vs_sham')v<-v-z[[metric]]
   q<-ci(v);j<-j+1;result[[j]]<-data.frame(food,age,cohort,dose,metric,contrast,mean=q[1],lower=q[2],upper=q[3],min_seed=min(v),max_seed=max(v))
  }
 }
}
write.csv(do.call(rbind,result),file.path(p,'effects.csv'),row.names=FALSE)
cat('100 independent source blocks; paired t intervals; all simulation outcomes retained.\n')

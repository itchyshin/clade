library(survival)
p<-commandArgs(TRUE)[1];z<-read.csv(file.path(p,'audited/timing.csv'))
# Independent survival::survfit/Aalen-Johansen reconstruction on 24 pilot cells.
check_seeds<-if(grepl('/pilot/?$',p)) c(82001,82002) else c(83001,83002)
select<-subset(z,seed %in% check_seeds & mono %in% c(0,1) & dose %in% c(0,50,100) & food==.05 & age_mode=='fixed')
stopifnot(nrow(select)==24)
for(i in seq_len(nrow(select))) {
 a<-select[i,];d<-read.csv(file.path(p,a$seed,'cohorts.csv'));d<-d[d$dose==a$dose & d$food==a$food & d$age_mode==a$age_mode & d$mono==a$mono,]
 if(a$cohort=='complete')d<-d[d$entry_tick<=d$end_tick-50,]
 stopifnot(nrow(d)==a$n,nrow(d)>0)
 birth<-ifelse(d$birth_tick>0,d$birth_tick-d$entry_tick,Inf)
 death<-ifelse(d$death_tick>0,d$death_tick-d$entry_tick,Inf)
 censor<-pmin(50,d$end_tick-d$entry_tick)
 times<-pmin(birth,death,censor)
 state<-ifelse(birth<=death & birth<=censor,'birth',ifelse(death<=censor,'death','censor'))
 state<-factor(state,levels=c('censor','birth','death'))
 fit<-survfit(Surv(times,state)~1)
 cif<-tail(fit$pstate,1);stopifnot(abs(cif[1,'birth']-a$cif_birth50)<1e-10,abs(cif[1,'death']-a$cif_death50)<1e-10)
}
cat('PASS: 24 run/cohort Aalen-Johansen estimates match survival::survfit.\n')

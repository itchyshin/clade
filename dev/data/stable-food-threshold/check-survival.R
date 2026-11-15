library(survival)
args<-commandArgs(TRUE);p<-args[1];life<-args[2];seeds<-as.integer(args[3:4]);z<-read.csv(file.path(p,'audited',paste0(life,'-timing.csv')))
select<-subset(z,seed %in% seeds & mono %in% c(0,1) & threshold %in% c(80,120) & food==.05 & age_mode=='fixed')
stopifnot(nrow(select)==16)
for(i in seq_len(nrow(select))) {
 a<-select[i,];d<-read.csv(file.path(p,life,a$seed,'cohorts.csv'));d<-d[d$threshold==a$threshold & d$food==a$food & d$age_mode==a$age_mode & d$mono==a$mono,]
 if(a$cohort=='complete')d<-d[d$entry_tick<=d$end_tick-50,]
 stopifnot(nrow(d)==a$n)
 if(nrow(d)==0){stopifnot(is.na(a$cif_birth50));next}
 birth<-ifelse(d$birth_tick>0,d$birth_tick-d$entry_tick,Inf);death<-ifelse(d$death_tick>0,d$death_tick-d$entry_tick,Inf);censor<-pmin(50,d$end_tick-d$entry_tick)
 times<-pmin(birth,death,censor);state<-factor(ifelse(birth<=death & birth<=censor,'birth',ifelse(death<=censor,'death','censor')),levels=c('censor','birth','death'))
 fit<-survfit(Surv(times,state)~1);x<-tail(fit$pstate,1);stopifnot(abs(x[1,'birth']-a$cif_birth50)<1e-10,abs(x[1,'death']-a$cif_death50)<1e-10)
}
cat('PASS: 16 run/cohort competing-risk estimates match survival::survfit.\n')

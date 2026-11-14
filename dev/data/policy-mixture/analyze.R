a <- commandArgs(TRUE);out <- a[1];n <- as.integer(a[2]);stopifnot(!is.na(n),n>0)
source('R/analysis.R')
read <- function(name) read.csv(file.path(out,paste0(name,'.csv')),stringsAsFactors=FALSE)
r<-read('runs');w<-read('windows');c<-read('cohorts');d<-read('deaths');panels<-read('panels');policies<-read('policies')
c$observed<-c$observed %in% c(TRUE,'true','1')
key<-function(x) do.call(paste,c(x[c('ploidy','source_mutation','seed','mode','mono')],sep=':'))
bkey<-function(x) do.call(paste,c(x[c('ploidy','source_mutation','seed')],sep=':'))
expected<-expand.grid(ploidy=1:2,source_mutation=c(0,.05,.2),seed=20000+seq_len(n),mode=c('forage','demography'),mono=0:8)
stopifnot(nrow(r)==108*n,!anyDuplicated(key(r)),setequal(key(r),key(expected)),nrow(panels)==6*n,nrow(policies)==48*n)
stopifnot(!anyDuplicated(bkey(panels)),setequal(bkey(panels),bkey(expected)))
wg<-split(seq_len(nrow(w)),key(w));cg<-split(seq_len(nrow(c)),key(c));dg<-split(seq_len(nrow(d)),key(d));pg<-split(seq_len(nrow(policies)),bkey(policies))
for (ix in pg) {z<-policies[ix,];stopifnot(nrow(z)==8,setequal(z$policy,1:8),!anyDuplicated(z$source_index))}
# Physical hashes must match all9 assemblages and all3 source regimes for a seed/ploidy.
stopifnot(all(vapply(split(r$physical_hash,paste(r$ploidy,r$seed)),function(x)length(unique(x))==1,logical(1))))
stopifnot(all(vapply(split(r$panel_hash,bkey(r)),function(x)length(unique(x))==1,logical(1))))
stopifnot(all(r$panel_hash==panels$panel_hash[match(bkey(r),bkey(panels))]))
r$viability<-NA_character_
for(i in seq_len(nrow(r))) {
 k<-key(r[i,]);z<-w[wg[[k]],];z<-z[order(z$lo),];h<-if(r$mode[i]=='forage')50 else 300
 stopifnot(nrow(z)==h/50,all(z$lo==seq(1,h,50)),all(z$hi==z$lo+49),z$nstart[1]==48,
  all(z$nend==z$nstart+z$births-z$deaths),all(z$pre_exposure==z$post_exposure+z$nstart-z$nend),
  z$nend[nrow(z)]==r$final_agents[i],all(z$nstart[-1]==head(z$nend,-1)),
  sum(z$pre_exposure)==r$exposure[i],sum(z$births)==r$births[i],sum(z$deaths)==r$deaths[i],
  abs(sum(z$food)-r$food[i])<1e-6,abs(sum(z$net_energy)-r$net_energy[i])<1e-5,
  all(z$food>=-1e-8),all(z$food<=2*z$pre_exposure+1e-8),
  abs(5*sum(z$food)-1.382*r$exposure[i]+.5*sum(z$idle)-r$uncapped_reward[i])<1e-5,
  abs(r$uncapped_reward[i]-r$net_energy[i]-r$clipping[i])<1e-5,r$clipping[i]>=-2e-4*r$exposure[i])
 if(r$mode[i]=='forage')stopifnot(r$exposure[i]==2400,r$final_agents[i]==48,r$births[i]==0,r$deaths[i]==0)
 co<-c[cg[[k]],];de<-d[dg[[k]],]
 stopifnot(nrow(co)==r$births[i],nrow(de)==r$deaths[i],!anyDuplicated(co$id),!anyDuplicated(de$id),all(co$parent>0),all(co$follow==co$birth+100),all(co$observed==(co$follow<=h)))
 eligible<-co$observed
 stopifnot(sum(eligible)==r$cohort_births[i],sum(co$survived[eligible])==r$recruits100[i],all(co$survived[!eligible]==-1),sum(co$parent<=48)==r$founder_births[i])
 stopifnot(sum(z$pre_exposure[z$hi<=h-100])==r$cohort_exposure[i])
 if(nrow(co)) {
  dt<-de$tick[match(co$id,de$id)]
  stopifnot(all(is.na(dt)|dt>co$birth),all(co$survived[eligible]==as.integer(is.na(dt[eligible])|dt[eligible]>co$follow[eligible])))
 }
 r$viability[i]<-viability_report(data.frame(t=c(r$tick_of_min[i],r$final_tick[i]),n_agents=c(r$min_population[i],r$final_agents[i])),n_agents_init=48)$verdict
}
write.csv(r,file.path(out,'runs_with_viability.csv'),row.names=FALSE)
rate<-function(x,y)ifelse(y>0,x/y,NA_real_)
r$food_rate<-rate(r$food,r$exposure);r$net_rate<-rate(r$net_energy,r$exposure);r$reward_rate<-rate(r$uncapped_reward,r$exposure)
r$birth_yield<-1000*rate(r$births,r$exposure);r$death_yield<-1000*rate(r$deaths,r$exposure)
r$survival100<-rate(r$recruits100,r$cohort_births);r$recruit_yield<-1000*rate(r$recruits100,r$cohort_exposure)
metrics<-c('food_rate','net_rate','reward_rate','birth_yield','death_yield','final_agents','births','survival100','recruit_yield','founder_births')
contrasts<-list();j<-0
for(ix in split(seq_len(nrow(r)),paste(bkey(r),r$mode))) {
 z<-r[ix,];mix<-z[z$mono==0,];mono<-z[z$mono>0,];stopifnot(nrow(mix)==1,nrow(mono)==8,setequal(mono$mono,1:8))
 for(metric in metrics) {
  # A missing monoculture value makes the complete benchmark missing.
  control<-mean(mono[[metric]]);delta<-mix[[metric]]-control
  j<-j+1;contrasts[[j]]<-data.frame(ploidy=mix$ploidy,source_mutation=mix$source_mutation,seed=mix$seed,mode=mix$mode,metric=metric,
    mix=mix[[metric]],control=control,delta=delta,all_viable=all(z$viability=='viable'))
 }
}
blocks<-do.call(rbind,contrasts);write.csv(blocks,file.path(out,'block_contrasts.csv'),row.names=FALSE,na='NA')
summary<-list();j<-0;set.seed(20261114)
for(ix in split(seq_len(nrow(blocks)),interaction(blocks$ploidy,blocks$source_mutation,blocks$mode,blocks$metric,drop=TRUE))) {
 z0<-blocks[ix,]
 for(guard in c('all_blocks','all9_viable')) {
  z<-if(guard=='all9_viable')z0[z0$all_viable,] else z0
  z<-z[is.finite(z$delta),];nn<-nrow(z);m<-if(nn)mean(z$delta) else NA_real_;se<-if(nn>1)sd(z$delta)/sqrt(nn) else NA_real_;h<-if(nn>1)qt(.975,nn-1)*se else NA_real_
  rp<-rl<-ru<-NA_real_
  if(nn>1 && mean(z$control)>0 && z0$metric[1] %in% c('food_rate','birth_yield','recruit_yield','final_agents','births','founder_births')) {
   rp<-100*(mean(z$mix)/mean(z$control)-1)
   bt<-replicate(2000,{ii<-sample.int(nn,nn,TRUE);100*(mean(z$mix[ii])/mean(z$control[ii])-1)})
   ci<-quantile(bt,c(.025,.975),na.rm=TRUE);rl<-ci[1];ru<-ci[2]
  }
  classify<-function(lo,hi,margin)if(!is.finite(lo)||!is.finite(hi))'unknown' else if(lo>margin)'benefit' else if(hi< -margin)'harm' else if(lo>= -margin && hi<=margin)'within_margin' else 'uncertain'
  cl<-if(z0$mode[1]=='forage' && z0$metric[1]=='food_rate')classify(rl,ru,5) else if(z0$mode[1]=='forage' && z0$metric[1]=='net_rate')classify(m-h,m+h,.05) else 'secondary'
  j<-j+1;summary[[j]]<-data.frame(ploidy=z0$ploidy[1],source_mutation=z0$source_mutation[1],mode=z0$mode[1],metric=z0$metric[1],guard=guard,total_blocks=nrow(z0),all9_viable=sum(z0$all_viable),n=nn,mix=if(nn)mean(z$mix) else NA_real_,control=if(nn)mean(z$control) else NA_real_,mean=m,mcse=se,lower=m-h,upper=m+h,relative_percent=rp,relative_lower=rl,relative_upper=ru,classification=cl,wins=sum(z$delta>0),ties=sum(z$delta==0))
 }
}
ans<-do.call(rbind,summary);write.csv(ans,file.path(out,'summary.csv'),row.names=FALSE,na='NA')
cat('Complete balanced design:',nrow(r),'runs;',nrow(panels),'panels;',nrow(c),'births;',nrow(d),'deaths\n')
print(with(r,table(ploidy,source_mutation,mode,viability)))
print(ans[ans$guard=='all_blocks' & ((ans$mode=='forage' & ans$metric %in% c('food_rate','net_rate'))|(ans$mode=='demography' & ans$metric %in% c('birth_yield','survival100','final_agents'))),],row.names=FALSE)

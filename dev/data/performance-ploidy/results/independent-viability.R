a<-commandArgs(trailingOnly=TRUE);root<-a[[1]];source('R/analysis.R');d<-read.csv(file.path(root,'runs.csv'))
d$viability<-vapply(seq_len(nrow(d)),function(i)viability_report(data.frame(t=c(d$tick_of_min[i],d$final_tick[i]),n_agents=c(d$min_population[i],d$final_agents[i])),n_agents_init=50)$verdict,character(1))
write.csv(d,file.path(root,'independent_viability.csv'),row.names=FALSE,na='NA')

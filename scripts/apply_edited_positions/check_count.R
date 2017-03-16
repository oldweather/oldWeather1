# Script to check the effect of using the ship histories on
#  the number of obs with positions.

library(IMMA)

ships<-list.files(path='imma_new')

for(ship in ships) {

  f1<-sprintf("../../imma/%s",ship)
  o1<-ReadObs(f1)
  w1<-which(!is.na(o1[['LAT']]) & !is.na(o1[['LON']]))
  w11<-which(!is.na(o1[['HR']]))
  f2<-sprintf("imma_new/%s",ship)
  o2<-ReadObs(f2)
  w2<-which(!is.na(o2[['LAT']]) & !is.na(o2[['LON']]))
  w21<-which(!is.na(o2[['HR']]))
  print(sprintf("%-30s %5d %5d %5d %5d %5d %5d",ship,length(o1[,1]),length(o2[,1]),
                length(w1),length(w2),length(w11),length(w21)))
}  

# Script to check the effect of using the ship histories on
#  the number of obs with positions.

library(IMMA)

ships<-list.files(path='/scratch/hadpb/oW1.update/original/')
sums<-c(0,0,0,0,0,0)

for(ship in ships) {

  f1<-sprintf("/scratch/hadpb/oW1.update/original/%s",ship)
  o1<-ReadObs(f1)
  w1<-which(!is.na(o1[['LAT']]) & !is.na(o1[['LON']]))
  w11<-which(!is.na(o1[['HR']]))
  f2<-sprintf("/scratch/hadpb/oW1.update/updated/%s",ship)
  o2<-ReadObs(f2)
  w2<-which(!is.na(o2[['LAT']]) & !is.na(o2[['LON']]))
  w21<-which(!is.na(o2[['HR']]))
  print(sprintf("%-30s %7d %7d %7d %7d %7d %7d",ship,length(o1[,1]),length(o2[,1]),
                length(w1),length(w2),length(w11),length(w21)))
  sums<-sums+c(length(o1[,1]),length(o2[,1]),length(w1),length(w2),length(w11),length(w21))
  
}  
print("-------------------------------------------------")
print(sprintf("%-30s %7d %7d %7d %7d %7d %7d"," ",sums[1],sums[2],sums[3],sums[4],sums[5],sums[6]))

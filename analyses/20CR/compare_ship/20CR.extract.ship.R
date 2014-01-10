# Get pressures from 20CR, for a selected ship.

ship<-'Nw_Zealnd'
start<-c(1919,2,1) # Y,m,d
end<-c(1919,12,30)

library(GSDF.TWCR)

c.date<-chron(dates=sprintf("%04d/%02d/%02d",start[1],start[2],start[3]),
          times=sprintf("%02d:00:00",0),
          format=c(dates='y/m/d',times='h:m:s'))
e.date<-chron(dates=sprintf("%04d/%02d/%02d",end[1],end[2],end[3]),
          times=sprintf("%02d:00:00",0),
          format=c(dates='y/m/d',times='h:m:s'))

obs<-NULL
analysis<-NULL

while(c.date<=e.date) {

  year<-as.numeric(as.character(years(c.date)))
  month<-months(c.date)
  day<-days(c.date)

  for(hour in c(0,6,12,18)) {

    o<-TWCR.get.obs.1file(year,month,day,hour,version='3.3.8')
    w<-grep(ship,o$Name)
    if(is.null(obs)) obs<-o[w,]
    else obs<-rbind(obs,o[w,])

  }

  c.date<-c.date+1 # forward 1 day
}

print(length(obs$UID))

# Get mean and spread from 3.3.8 and 3.2.1 for each ob.
new.mean<-rep(NA,length(obs$UID))
new.spread<-rep(NA,length(obs$UID))
old.mean<-rep(NA,length(obs$UID))
old.spread<-rep(NA,length(obs$UID))
for(i in seq_along(obs$UID)) {

  year<-as.integer(substr(obs$UID[i],1,4))
  month<-as.integer(substr(obs$UID[i],5,6))
  day<-as.integer(substr(obs$UID[i],7,8))
  hour<-as.integer(substr(obs$UID[i],9,10))
  new<-TWCR.get.slice.at.hour('prmsl','mean',year,month,day,hour,
                              version='3.3.8',opendap=F)
  new.mean[i]<-GSDF.interpolate.ll(new,obs$Latitude[i],obs$Longitude[i])
  new<-TWCR.get.slice.at.hour('prmsl','spread',year,month,day,hour,
                              version='3.3.8',opendap=F)
  new.spread[i]<-GSDF.interpolate.ll(new,obs$Latitude[i],obs$Longitude[i])
  old<-TWCR.get.slice.at.hour('prmsl','mean',year,month,day,hour,
                              version='3.2.1',opendap=F)
  old.mean[i]<-GSDF.interpolate.ll(old,obs$Latitude[i],obs$Longitude[i])
  old<-TWCR.get.slice.at.hour('prmsl','spread',year,month,day,hour,
                              version='3.2.1',opendap=F)
  old.spread[i]<-GSDF.interpolate.ll(old,obs$Latitude[i],obs$Longitude[i])

}

# Output the result
fileConn<-file(sprintf("obs.%s",ship))
writeLines(sprintf("%s %f %f %f %f %f %f %f %f",obs$UID,
                   obs$SLP,
                   obs$Pressure.after.vertical.interpolation,
                   obs$Mean.analysis.pressure.difference,
                   obs$Analysis.pressure.spread,
                   new.mean,new.spread,
                   old.mean,old.spread),
                   fileConn)
close(fileConn)

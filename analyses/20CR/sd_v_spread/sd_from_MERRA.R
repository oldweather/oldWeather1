# Calculate the weather standard deviation 1981-2010 from MERRA.
#  Just for one time in the seasonal cycle.

library(GSDF.MERRA)

variable<-'SLP'

Month<-3
Day<-12
Hour<-6

Accumulator<-array(dim=c(30,194940))

for(Year in seq(1981,2010)) {

   p<-MERRA.get.slice.at.hour(variable,Year,Month,Day,Hour)
   Accumulator[Year-1980,]<-as.vector(p$data)

 }

 s<-sd(Accumulator)

 merra.sd<-MERRA.get.slice.at.hour(variable,1981,Month,Day,Hour)
 merra.sd$data[]<-s

 name<-sprintf("MERRA.%s.sd.%02d.%02d.%02d.rdata",variable,Month,Day,Hour)
 save(merra.sd,file=name)

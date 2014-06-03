# Make standard deviations 1981-2010 from 20CR.
#  Store the results as Rdata files

library(GSDF.TWCR)
library(chron)
library(parallel)

base.dir<-'/Volumes/DataDir/20CR/version_3.2.1/hourly/standard.deviations'
variable<-'air.2m'
base.dir<-sprintf("%s/%s",base.dir,variable)
dir.create(base.dir)

c.date<-chron(dates="1981/01/01",
          times="00:00:00",
          format=c(dates='y/m/d',times='h:m:s'))

t<-TWCR.get.slice.at.hour(variable,1969,3,12,6)
data.length<-length(as.vector(t$data))
n.count<-seq(1,365*24)

make.sd<-function(n.count) {
  
   n.date<-c.date+n.count-1
   Month<-months(n.date)
   Day<-days(n.date)

   for(Hour in c(0,6,12,18)) {
     
     f.name<-sprintf("%s/sd.%02d.%02d.%02d.rdata",
                    base.dir,Month,Day,Hour)
     if(file.exists(f.name)) return()
     
     Accumulator<-array(dim=c(30,data.length))

      for(Year in seq(1981,2010)) {

         p<-TWCR.get.slice.at.hour(variable,Year,Month,Day,Hour)
         Accumulator[Year-1980,]<-as.vector(p$data)

      }

      s<-apply(Accumulator,2,sd)

      twcr.sd<-TWCR.get.slice.at.hour(variable,1981,Month,Day,Hour)
      twcr.sd$data[]<-s

      save(twcr.sd,file=f.name,compress=TRUE)

    }
    gc(verbose=F)
 }
     
f<-mclapply(n.count,make.sd,mc.cores=2,mc.preschedule=FALSE)

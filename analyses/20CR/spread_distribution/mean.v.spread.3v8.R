# Compare empirical values of the spread uncertainty (derived
#  by comparing 333 with 338) with theoretical estimates.

library(GSDF.TWCR)
library(grid)
library(lattice)
library(chron)

variable<-'prmsl'

Year<-1918
Month<-3
Day<-1
Hour<-0

c.date<-chron(dates=sprintf("%04d/%02d/%02d",Year,Month,Day),
          times=sprintf("%02d:00:00",Hour),
          format=c(dates='y/m/d',times='h:m:s'))
n.count<-seq(0,100)

read.obs.file<-function(n.count) {
   n.date<-c.date+n.count
   Year<-as.numeric(as.character(years(n.date)))
   Month<-months(n.date)
   Day<-days(n.date)
   
   result<-NULL
   for(Hour in c(0,6,12,18)) {

     v3<-TWCR.get.slice.at.hour(variable,Year,Month,Day,Hour,
                                version='3.3.3',type='mean')
     v3.spread<-TWCR.get.slice.at.hour(variable,Year,Month,Day,Hour,
                                version='3.3.3',type='spread')
     v8<-TWCR.get.slice.at.hour(variable,Year,Month,Day,Hour,
                                version='3.3.8',type='mean')
     v8.spread<-TWCR.get.slice.at.hour(variable,Year,Month,Day,Hour,
                                version='3.3.8',type='spread')
     sd<-TWCR.get.slice.at.hour(variable,Year,Month,Day,Hour,
                                version=2,type='standard.deviation')
     s2<-sqrt(v3.spread$data**2+v8.spread$data**2)
     s.frac<-(sd$data*sqrt(2)/s2)
     #w<-which(s2/sd$data<1) 
     result<-c(result,((v3$data-v8$data)/s2)/s.frac)

    }
    return(result)
 }
f<-lapply(n.count,read.obs.file)
# Pack all the daily results together
scaled.differences<-do.call('c',f)
#w<-which(abs(scaled.differences)<1) 
sd.sd<-sd(scaled.differences)

range<-c(-5,5)
f.x<-seq(range[1],range[2],(range[2]-range[1])/100)
         
pdf('mean.error.distribution.pdf',width=11,height=7)
trellis.par.set('fontsize',list('text'=16))

gp_blue  = gpar(col=rgb(0,0,1,1),fill=rgb(0,0,1,1),lwd=2)
gp_red  = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1),lwd=2)
gp_grey  = gpar(col=rgb(0.2,0.2,0.2,1),fill=rgb(0.2,0.2,0.2,1))

pushViewport(viewport(width=1.0,height=1.0,x=0.0,y=0.0,
                          just=c("left","bottom"),name="vp_main"))

#           ylim=c(0,0.005),
w<-which(scaled.differences>=range[1] & scaled.differences<= range[2])
print(histogram(scaled.differences[w],breaks=100,
           main='Normalised difference in mean (3.3.3 - 3.3.8)',
           xlim=range,
           type='density',
           panel = function(...) {
             panel.histogram(...)
             grid.lines(x=unit(f.x,'native'),
                        y=unit(dnorm(f.x,sd=1),'native'),
                        gp=gp_red)
             grid.lines(x=unit(f.x,'native'),
                        y=unit(dnorm(f.x,sd=sd.sd),'native'),
                        gp=gp_blue)
             }),newpage=F)

upViewport(0)

dev.off()

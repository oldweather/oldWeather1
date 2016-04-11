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
n.count<-seq(0,20)

read.obs.file<-function(n.count) {
   n.date<-c.date+n.count
   Year<-as.numeric(as.character(years(n.date)))
   Month<-months(n.date)
   Day<-days(n.date)
   
   result<-NULL
   for(Hour in c(0,6,12,18)) {

     v3.spread<-TWCR.get.slice.at.hour(variable,Year,Month,Day,Hour,
                                version='3.3.3',type='spread')
     v8.spread<-TWCR.get.slice.at.hour(variable,Year,Month,Day,Hour,
                                version='3.3.8',type='spread')
     sd<-TWCR.get.slice.at.hour(variable,Year,Month,Day,Hour,
                                version=2,type='standard.deviation')
     r<-v3.spread$data**2/v8.spread$data**2
     s2<-sqrt((v3.spread$data**2+v8.spread$data**2)/2)
     w<-which(s2<sd$data*0.05 & s2>sd$data*0.0)
     result<-c(result,r[w])

    }
    return(result)
 }
f<-lapply(n.count,read.obs.file)
# Pack all the daily results together
scaled.differences<-do.call('c',f)
sd.sd<-sd(scaled.differences)

range<-c(0.25,2)
f.x<-seq(range[1],range[2],(range[2]-range[1])/100)
         
pdf('spread.ratio.distribution.pdf',width=11,height=7)
trellis.par.set('fontsize',list('text'=16))

gp_blue  = gpar(col=rgb(0,0,1,1),fill=rgb(0,0,1,1),lwd=2)
gp_red  = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1),lwd=2)
gp_grey  = gpar(col=rgb(0.2,0.2,0.2,1),fill=rgb(0.2,0.2,0.2,1))

pushViewport(viewport(width=1.0,height=1.0,x=0.0,y=0.0,
                          just=c("left","bottom"),name="vp_main"))

#           ylim=c(0,0.005),
print(histogram(scaled.differences,breaks=200,
           main='Ratio of spread**2 (3.3.3/3.3.8)',
           xlim=range,
           type='density',
           panel = function(...) {
             panel.histogram(...)
             #grid.lines(x=unit(f.x,'native'),
             #           y=unit(df(f.x,df1=55,df2=55),'native'),
             #           gp=gp_red)
             grid.lines(x=unit(f.x,'native'),
                        y=unit(df(f.x,df1=75,df2=75),'native'),
                        gp=gp_blue)
             }),newpage=F)
upViewport(0)

dev.off()

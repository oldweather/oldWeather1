# Make scatter plots from the 20CR obs feedback files
# Compare analyses in 3.3.2 with those in 3.3.8

library(GSDF.TWCR)
library(grid)
library(hexbin)
library(chron)

Year<-1918
Month<-1
Day<-1
Hour<-0

obs.2<-NULL
obs.8<-NULL

c.date<-chron(dates=sprintf("%04d/%02d/%02d",Year,Month,Day),
          times=sprintf("%02d:00:00",Hour),
          format=c(dates='y/m/d',times='h:m:s'))
n.count<-seq(0,100)

read.obs.file<-function(n.count) {
   n.date<-c.date+n.count
   Year<-as.numeric(as.character(years(n.date)))
   Month<-months(n.date)
   Day<-days(n.date)
   
   for(Hour in c(0,6,12,18)) {
 
      o.2<-TWCR.get.obs.1file(Year,Month,Day,Hour,version='3.3.2')
      o.2$oW.obs<-grepl('9931',o.2$UID) # Find the oW obs
      if(is.null(obs.2)) { obs.2<<-o.2
      } else obs.2<<-rbind(obs.2,o.2)
      o.8<-TWCR.get.obs.1file(Year,Month,Day,Hour,version='3.3.8')
      o.8$oW.obs<-grepl('9931',o.8$UID) # Find the oW obs
      if(is.null(obs.8)) { obs.8<<-o.8
      } else obs.8<<-rbind(obs.8,o.8)

    }
 }
f<-lapply(n.count,read.obs.file)

# Get rid of the outliers
range<-c(0,3)
w<-which(obs.8$Analysis.pressure.spread>range[2])
is.na(obs.8$Analysis.pressure.spread[w])<-T
w<-which(obs.2$Analysis.pressure.spread>range[2])
is.na(obs.2$Analysis.pressure.spread[w])<-T

png('tst.png',width=1200,height=600)
trellis.par.set('fontsize',list('text'=18))

gp_blue  = gpar(col=rgb(0,0,1,1),fill=rgb(0,0,1,1),lwd=2)
gp_red  = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1),lwd=2)
gp_grey  = gpar(col=rgb(0.8,0.8,0.8,1),fill=rgb(0.8,0.8,0.8,1))

pushViewport(viewport(width=0.45,height=0.9,x=0.05,y=0.05,
                          just=c("left","bottom"),name="vp_main"))


l<-lm(obs.2$Analysis.pressure.spread[-which(obs.2$oW.obs)]~obs.8$Analysis.pressure.spread[-which(obs.8$oW.obs)])
print(hexbinplot(obs.2$Analysis.pressure.spread[-which(obs.2$oW.obs)]~obs.8$Analysis.pressure.spread[-which(obs.8$oW.obs)],
           aspect=1,
           main='Original obs',
           xlab = "Spread in 3.3.8", ylab = "Spread in 3.3.3",
           xlim=range,ylim=range,
           panel = function(...) {
             panel.hexbinplot(...)
             grid.lines(x=unit(range,'native'),
                        y=unit(range,'native'),
                        gp=gp_grey)
             grid.lines(x=unit(range,'native'),
                        y=unit(range*l$coefficients[2]+l$coefficients[1],'native'),
                        gp=gp_blue)
             }),newpage=F)

upViewport(0)
pushViewport(viewport(width=0.45,height=0.9,x=0.5,y=0.05,
                          just=c("left","bottom"),name="vp_main"))


l<-lm(obs.2$Analysis.pressure.spread[which(obs.2$oW.obs)]~obs.8$Analysis.pressure.spread[which(obs.8$oW.obs)])
print(hexbinplot(obs.2$Analysis.pressure.spread[which(obs.2$oW.obs)]~obs.8$Analysis.pressure.spread[which(obs.8$oW.obs)],
           aspect=1,
           main='oldWeather obs',
           xlab = "Spread in 3.3.8", ylab = "Spread in 3.3.3",
           xlim=range,ylim=range,
           panel = function(...) {
             panel.hexbinplot(...)
             grid.lines(x=unit(range,'native'),
                        y=unit(range,'native'),
                        gp=gp_grey)
             grid.lines(x=unit(range,'native'),
                        y=unit(range*l$coefficients[2]+l$coefficients[1],'native'),
                        gp=gp_blue)
             }),newpage=F)

upViewport(0)

dev.off()

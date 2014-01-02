# Make scatter plots from the 20CR obs feedback files
# Compare analyses in 3.3.3 with those in 3.3.8

library(TWCR)
library(grid)

Year<-1918
Month<-8
Day<-12
Hour<-6

obs.3<-TWCR.get.obs.1file(Year,Month,Day,Hour,version='3.3.3')
obs.3$oW.obs<-grepl('9931',obs.3$UID) # Find the oW obs
obs.8<-TWCR.get.obs.1file(Year,Month,Day,Hour,version='3.3.8')
obs.8$oW.obs<-grepl('9931',obs.8$UID) # Find the oW obs

png('tst.png',width=800,height=800)
range<-c(0,2)

pushViewport(viewport(width=1,height=1,x=0,y=0,
                          just=c("left","bottom"),name="vp_main"))
pushViewport(plotViewport(margins=c(5,5,1,1)))
pushViewport(dataViewport(range,range))

#tics<-pretty(range,n=5)
grid.xaxis(main=T)
grid.text('Analysis spread at ob (3.3.3)',y=unit(-3,"lines"))
grid.yaxis(,main=T)
grid.text('Analysis spread at ob (3.3.8)',x=unit(-3.5,"lines"), rot=90)

gp_blue  = gpar(col=rgb(0,0,1,1),fill=rgb(0,0,1,1),lwd=2)
gp_red  = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1),lwd=2)
gp_grey  = gpar(col=rgb(0.8,0.8,0.8,1),fill=rgb(0.8,0.8,0.8,1))
grid.lines(x=unit(range,'native'),
            y=unit(range,'native'),
            gp=gp_grey)

grid.points(x=unit(obs.3$Analysis.pressure.spread[-which(obs.3$oW.obs)],"native"),
            y=unit(obs.8$Analysis.pressure.spread[-which(obs.8$oW.obs)],"native"),
            size=unit('0.02','npc'),
            pch=20,
            gp=gp_blue)
l<-lm(obs.8$Analysis.pressure.spread[-which(obs.8$oW.obs)]~obs.3$Analysis.pressure.spread[-which(obs.3$oW.obs)])
grid.lines(x=unit(range,'native'),
           y=unit(range*l$coefficients[2]+l$coefficients[1],'native'),
           gp=gp_blue)

grid.points(x=unit(obs.3$Analysis.pressure.spread[which(obs.3$oW.obs)],"native"),
            y=unit(obs.8$Analysis.pressure.spread[which(obs.8$oW.obs)],"native"),
            size=unit('0.02','npc'),
            pch=20,
            gp=gp_red)
l<-lm(obs.8$Analysis.pressure.spread[which(obs.8$oW.obs)]~obs.3$Analysis.pressure.spread[which(obs.3$oW.obs)])
grid.lines(x=unit(range,'native'),
           y=unit(range*l$coefficients[2]+l$coefficients[1],'native'),
           gp=gp_red)

popViewport()
popViewport()
upViewport()
dev.off()

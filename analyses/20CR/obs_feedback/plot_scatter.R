# Make scatter plots from the 20CR obs feedback files

library(TWCR)
library(grid)

Year<-1918
Month<-3
Day<-12
Hour<-6

Version<-'3.3.3'

obs<-TWCR.get.obs(Year,Month,Day,Hour,version=Version)

height<-obs$V7
is.na(height[height==9999])<-T
observed.pressure<-obs$V11
is.na(observed.pressure[observed.pressure==10000])<-T  # Missing data
modified.obs<-obs$V10
is.na(modified.obs[modified.obs>9000])<-T
l<-lm(modified.obs~height+1)
modified.obs<-l$residuals+l$coefficients[1]
mean.analysis<-obs$V22
is.na(mean.analysis[mean.analysis>1000])<-T
mean.analysis<-mean.analysis+modified.obs
spread.analysis<-obs$V23
is.na(spread.analysis[spread.analysis>1000])<-T
w<-grep('9931',obs$V1) # Find the oW obs

png('tst.png',width=1000,height=1000)
range<-c(950,1050)

pushViewport(viewport(width=1,height=1,x=0,y=0,
                          just=c("left","bottom"),name="vp_main"))
pushViewport(plotViewport(margins=c(5,5,1,1)))
pushViewport(dataViewport(range,range))

#tics<-pretty(range,n=5)
grid.xaxis(main=T)
grid.text('Observed Pressure',y=unit(-3,"lines"))
grid.yaxis(,main=T)
grid.text('Analysis Pressure',x=unit(-3.5,"lines"), rot=90)

gp_blue  = gpar(col=rgb(0,0,1,1),fill=rgb(0,0,1,1))
gp_red  = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
gp_grey  = gpar(col=rgb(0.8,0.8,0.8,1),fill=rgb(0.8,0.8,0.8,1))
grid.lines(x=unit(range,'native'),
            y=unit(range,'native'),
            gp=gp_grey)

grid.polyline(x=unit(as.vector(rbind(modified.obs,modified.obs)),"native"),
              y=unit(as.vector(rbind(mean.analysis-spread.analysis*2,
                                     mean.analysis+spread.analysis*2)),'native'),
               id.lengths=rep(2,length(modified.obs)),
               gp=gp_blue)

grid.polyline(x=unit(as.vector(rbind(modified.obs[w],modified.obs[w])),"native"),
              y=unit(as.vector(rbind(mean.analysis[w]-spread.analysis[w]*2,
                                     mean.analysis[w]+spread.analysis[w]*2)),'native'),
               id.lengths=rep(2,length(modified.obs[w])),
               gp=gp_red)

popViewport()
popViewport()
upViewport()
dev.off()

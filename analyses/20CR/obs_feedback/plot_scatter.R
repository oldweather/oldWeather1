# Make scatter plots from the 20CR obs feedback files

library(TWCR)
library(grid)

Year<-1918
Month<-8
Day<-12
Hour<-6

Version<-'3.3.8'

# Get obs used in single assimilation run
local.TWCR.get.obs<-function(year,month,day,hour,version=2) {
    base.dir<-TWCR:::TWCR.get.data.dir(version)
    of.name<-sprintf(
                "%s/observations/%04d/prepbufrobs_assim_%04d%02d%02d%02d.txt",base.dir,
                year,year,month,day,hour)
    if(!file.exists(of.name)) stop("No obs file fior given date")
            o<-read.table(pipe(sprintf("cut -c1-160 %s",of.name)),
                      header=F,stringsAsFactors=F,
                      colClasses=c('character','integer','character',
                                   rep('numeric',20)))
        o$odates<-chron(dates=sprintf("%04d/%02d/%02d",as.integer(substr(o$V1,1,4)),
                                                     as.integer(substr(o$V1,5,6)),
                                                     as.integer(substr(o$V1,7,8))),
          times=sprintf("%02d:00:00",as.integer(substr(o$V1,9,10))),
          format=c(dates='y/m/d',times='h:m:s'))
        o<-o[,seq(1,23)] # Truncate to regular section
        o$V4<-as.numeric(o$V4)
        o$V5<-as.numeric(o$V5)
        o<-o[(o$V4<=360 & o$V5<=90),] # Throw away obs outside possible range
    # Process the obs to set missing correctly and flag oW obs
        o$height<-o$V7
        is.na(o$height[o$height==9999])<-T
        o$observed.pressure<-o$V11
        is.na(o$observed.pressure[o$observed.pressure==10000])<-T 
        o$modified.obs<-o$V10
        is.na(o$modified.obs[o$modified.obs>9000])<-T
    # Adjust to sea-level with a linear model
        l<-lm(o$modified.obs~o$height+1)
        o$modified.obs<-l$residuals+l$coefficients[1]
        o$mean.analysis<-o$V22
        is.na(o$mean.analysis[o$mean.analysis>1000])<-T
        o$mean.analysis<-o$mean.analysis+o$modified.obs
        o$spread.analysis<-o$V23
        is.na(o$spread.analysis[o$spread.analysis>1000])<-T
        o$oW.obs<-grepl('9931',o$V1) # Find the oW obs
    return(o)
}

obs<-local.TWCR.get.obs(Year,Month,Day,Hour,version=Version)

png('tst.png',width=1000,height=1000)
range<-c(980,1040)

pushViewport(viewport(width=1,height=1,x=0,y=0,
                          just=c("left","bottom"),name="vp_main"))
pushViewport(plotViewport(margins=c(5,5,1,1)))
pushViewport(dataViewport(range,range))

#tics<-pretty(range,n=5)
grid.xaxis(main=T)
grid.text('Observed Pressure',y=unit(-3,"lines"))
grid.yaxis(,main=T)
grid.text('Analysis Pressure',x=unit(-3.5,"lines"), rot=90)

gp_blue  = gpar(col=rgb(0,0,1,1),fill=rgb(0,0,1,1),lwd=2)
gp_red  = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1),lwd=2)
gp_grey  = gpar(col=rgb(0.8,0.8,0.8,1),fill=rgb(0.8,0.8,0.8,1))
grid.lines(x=unit(range,'native'),
            y=unit(range,'native'),
            gp=gp_grey)

grid.polyline(x=unit(as.vector(rbind(obs$modified.obs,obs$modified.obs)),"native"),
              y=unit(as.vector(rbind(obs$mean.analysis-obs$spread.analysis*2,
                                     obs$mean.analysis+obs$spread.analysis*2)),'native'),
               id.lengths=rep(2,length(obs$modified.obs)),
               gp=gp_blue)

grid.polyline(x=unit(as.vector(rbind(obs$modified.obs[which(obs$oW.obs)],
                                     obs$modified.obs[which(obs$oW.obs)])),"native"),
              y=unit(as.vector(rbind(obs$mean.analysis[which(obs$oW.obs)]-
                                       obs$spread.analysis[which(obs$oW.obs)]*2,
                                     obs$mean.analysis[which(obs$oW.obs)]+
                                       obs$spread.analysis[which(obs$oW.obs)]*2)),
                               'native'),
               id.lengths=rep(2,length(obs$modified.obs[which(obs$oW.obs)])),
               gp=gp_red)

popViewport()
popViewport()
upViewport()
dev.off()

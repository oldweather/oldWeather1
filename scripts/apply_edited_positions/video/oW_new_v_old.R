#!/usr/bin/Rscript --no-save

# Show the oldWeather 1 obs mapped to a single year.
# Compare new v old obs.

library(GSDF)
library(GSDF.WeatherMap)
library(getopt)
library(lubridate)
library(RColorBrewer)
library(IMMA)

opt = getopt(matrix(c(
  'month',  'm', 2, "integer",
  'day',    'e', 2, "integer",
  'hour',   'h', 2, "integer"
  
),ncol=4,byrow=TRUE))
if ( is.null(opt$month) )  { stop("Month not specified") }
if ( is.null(opt$day) )    { stop("Day not specified") }
if ( is.null(opt$hour) )   { stop("Hour not specified") }

Imagedir<-sprintf("%s/images/oW1.update.hourly",Sys.getenv('SCRATCH'))
if(!file.exists(Imagedir)) dir.create(Imagedir,recursive=TRUE)

Options<-WeatherMap.set.option(NULL)
Options<-WeatherMap.set.option(Options,'land.colour',rgb(0,0,0,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'sea.colour',rgb(100,100,100,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'ice.colour',Options$land.colour)
Options<-WeatherMap.set.option(Options,'background.resolution','high')

Options<-WeatherMap.set.option(Options,'lat.min',-90)
Options<-WeatherMap.set.option(Options,'lat.max',90)
Options<-WeatherMap.set.option(Options,'lon.min',-180)
Options<-WeatherMap.set.option(Options,'lon.max',180)
Options$vp.lon.min<- -180
Options$vp.lon.max<-  180
Options$obs.size<- 1.0

land<-WeatherMap.get.land(Options)
land<-GSDF:::GSDF.pad.longitude(land)

get.obs.for.hour.original<-function(month,day,hour,duration) {
  start<-ymd_hms(sprintf("%04d-%02d-%02d %02d:30:00",1920,month,day,hour))-
    hours(duration/2)
  end<-start+hours(duration)
  fns<-list.files(sprintf("%s/oW1.update/original",Sys.getenv('SCRATCH')))
  original<-NULL
  for(file in fns) {
    obs<-ReadObs(sprintf("%s/oW1.update/original/%s",
                          Sys.getenv('SCRATCH'),file))
    result.dates<-ymd_hms(sprintf("%04d-%02d-%02d %02d:%02d:00",
                                1920,
                                as.integer(obs$MO),
                                as.integer(obs$DY),
                                as.integer(obs$HR),
                                as.integer((obs$HR%%1)*60)))
    w<-which(result.dates>=start & result.dates<end)
    if(length(w)==0) next
    if(is.null(original)) {
      original<-obs[w,]
    } else {
      cols <- intersect(colnames(original), colnames(obs))
      original<-rbind(original[,cols], obs[w,cols])
    }
   }
  gc(verbose=FALSE)
 return(original)
}
get.obs.for.hour.updated<-function(month,day,hour,duration) {
  start<-ymd_hms(sprintf("%04d-%02d-%02d %02d:30:00",1920,month,day,hour))-
    hours(duration/2)
  end<-start+hours(duration)
  fns<-list.files(sprintf("%s/oW1.update/updated",Sys.getenv('SCRATCH')))
  original<-NULL
  for(file in fns) {
    obs<-ReadObs(sprintf("%s/oW1.update/updated/%s",
                          Sys.getenv('SCRATCH'),file))
    result.dates<-ymd_hms(sprintf("%04d-%02d-%02d %02d:%02d:00",
                                1920,
                                as.integer(obs$MO),
                                as.integer(obs$DY),
                                as.integer(obs$HR),
                                as.integer((obs$HR%%1)*60)))
    w<-which(result.dates>=start & result.dates<end)
    if(length(w)==0) next
    if(is.null(original)) {
      original<-obs[w,]
    } else {
      cols <- intersect(colnames(original), colnames(obs))
      original<-rbind(original[,cols], obs[w,cols])
    }
   }
  gc(verbose=FALSE)
 return(original)
}


plot.hour<-function(month,day,hour) {    

    image.name<-sprintf("%02d-%02d:%02d.png",month,day,hour)
    ifile.name<-sprintf("%s/%s",Imagedir,image.name)
    if(file.exists(ifile.name) && file.info(ifile.name)$size>0) return()

    obs.orig<-get.obs.for.hour.original(month,day,hour,12)
    obs.updated<-get.obs.for.hour.updated(month,day,hour,12)
    
     png(ifile.name,
             width=1080*16/9,
             height=1080,
             bg=Options$sea.colour,
             pointsize=24,
             type='cairo-png')
    Options$label<-sprintf("%02d-%02d-%02d",month,day,hour)
  
  	   pushViewport(dataViewport(c(Options$vp.lon.min,Options$vp.lon.max),
  				     c(Options$lat.min,Options$lat.max),
  				      extension=0))
      WeatherMap.draw.land(land,Options)
    
    Options$obs.size<- 2
    Options<-WeatherMap.set.option(Options,'obs.colour',rgb(255,0,0,255,
                                                       maxColorValue=255))
    if(length(obs.orig$LAT)>0) {
             obs.orig$Latitude<-obs.orig$LAT
             obs.orig$Longitude<-obs.orig$LON
             WeatherMap.draw.obs(obs.orig,Options)
           }
    Options$obs.size<- 1.0
    Options<-WeatherMap.set.option(Options,'obs.colour',rgb(255,215,0,255,
                                                       maxColorValue=255))
    if(length(obs.updated$LAT)>0) {
             obs.updated$Latitude<-obs.updated$LAT
             obs.updated$Longitude<-obs.updated$LON
             WeatherMap.draw.obs(obs.updated,Options)
           }
    
      Options<-WeatherMap.set.option(Options,'land.colour',rgb(100,100,100,255,
                                                           maxColorValue=255))
      WeatherMap.draw.label(Options)
    dev.off()
  }


plot.hour(opt$month,opt$day,opt$hour)


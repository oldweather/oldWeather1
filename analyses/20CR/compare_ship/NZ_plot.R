# Plot the New Zealand's pressure observations along with the
#  reanalysis mean and spread along her route.

library(grid)
library(chron)

o<-read.table('obs.Nw_Zealnd')
dates<-chron(dates=sprintf("%4s/%2s/%2s",substr(o$V1,1,4),
                                            substr(o$V1,5,6),
                                            substr(o$V1,7,8)),
             times=sprintf("%2s:00:00",substr(o$V1,9,10)),
             format=c(dates = "y/m/d", times = "h:m:s"))
#tics=pretty(dates)
#ticl=attr(tics,'labels')
#if(is.null(ticl)) ticl<-dates(tics) # For R versions before 2.12
tics=dates(c("1919/02/01","1919/04/01","1919/06/01","1919/08/01",
           "1919/10/01","1919/12/01"),format="y/m/d")
ticl=c("1919/02","1919/04","1919/06","1919/08",
           "1919/10","1919/12")
                     

pdf(file="NZ_comparison.pdf",
    width=10,height=6,family='Helvetica',
    paper='special',pointsize=12)

#png(filename="NZ_comparison.png",width=600,height=400,pointsize=12) 
# Margin round the page - printers never seem to line up perfectly
pushViewport(viewport(width=0.98,height=0.98,x=0.01,y=0.01,
                      just=c("left","bottom"),name="Page",clip='off'))
   pushViewport(plotViewport(margins=c(4,4.5,1,0)))
      pushViewport(dataViewport(dates,c(970,1040)))
      
      # Mark the major ports
         gp=gpar(col=rgb(0.9,0.9,0.9,1),fill=rgb(0.9,0.9,0.9,1))
         p.y<-c(975,975,1045,1045)
         p.x<-chron(dates=c("1919/02/11","1919/02/21",
                            "1919/02/21","1919/02/11"),
                    times=rep("00:0:01",4),
                    format=c(dates = "y/m/d", times = "h:m:s"))
         grid.polygon(x=unit(p.x,'native'),
                      y=unit(p.y,'native'),
                      gp=gp)
         grid.text('UK',
                   x=unit((as.numeric(p.x[1])+as.numeric(p.x[2]))/2,'native'),
                   y=unit(970,'native'),
                   just=c('center','center'))

         p.x<-chron(dates=c("1919/03/03","1919/03/06",
                            "1919/03/06","1919/03/03"),
                    times=rep("00:0:01",4),
                    format=c(dates = "y/m/d", times = "h:m:s"))
         grid.polygon(x=unit(p.x,'native'),
                      y=unit(p.y,'native'),
                      gp=gp)
         grid.text(' Suez',
                   x=unit((as.numeric(p.x[1])+as.numeric(p.x[2]))/2,'native'),
                   y=unit(970,'native'),
                   just=c('center','center'))

         p.x<-chron(dates=c("1919/03/14","1919/05/01",
                            "1919/05/01","1919/03/14"),
                    times=rep("00:0:01",4),
                    format=c(dates = "y/m/d", times = "h:m:s"))
         grid.polygon(x=unit(p.x,'native'),
                      y=unit(p.y,'native'),
                      gp=gp)
         grid.text('India',
                   x=unit((as.numeric(p.x[1])+as.numeric(p.x[2]))/2,'native'),
                   y=unit(970,'native'),
                   just=c('center','center'))

         p.x<-chron(dates=c("1919/05/15","1919/08/16",
                            "1919/08/16","1919/05/15"),
                    times=rep("00:0:01",4),
                    format=c(dates = "y/m/d", times = "h:m:s"))
         grid.polygon(x=unit(p.x,'native'),
                      y=unit(p.y,'native'),
                      gp=gp)
         grid.text('Australia',
                   x=unit((as.numeric(p.x[1])+as.numeric(p.x[2]))/2,'native'),
                   y=unit(970,'native'),
                   just=c('center','center'))

         p.x<-chron(dates=c("1919/08/20","1919/10/03",
                            "1919/10/03","1919/08/20"),
                    times=rep("00:0:01",4),
                    format=c(dates = "y/m/d", times = "h:m:s"))
         grid.polygon(x=unit(p.x,'native'),
                      y=unit(p.y,'native'),
                      gp=gp)
         grid.text('New Zealand',
                   x=unit((as.numeric(p.x[1])+as.numeric(p.x[2]))/2,'native'),
                   y=unit(970,'native'),
                   just=c('center','center'))

         p.x<-chron(dates=c("1919/11/08","1919/12/04",
                            "1919/12/04","1919/11/08"),
                    times=rep("00:0:01",4),
                    format=c(dates = "y/m/d", times = "h:m:s"))
         grid.polygon(x=unit(p.x,'native'),
                      y=unit(p.y,'native'),
                      gp=gp)
         grid.text('North America',
                   x=unit((as.numeric(p.x[1])+as.numeric(p.x[2]))/2,'native'),
                   y=unit(970,'native'),
                   just=c('center','center'))
      
         grid.xaxis(at=as.numeric(tics),label=ticl,main=T)
         grid.text('Date',y=unit(-3,'lines'))
         grid.yaxis(main=T)
         grid.text('Sea-level pressure (hPa)',x=unit(-4,'lines'),rot=90)
         

         # Analysis spreads
         gp=gpar(col=rgb(0.8,0.8,1,1),fill=rgb(0.8,0.8,1,1))
         for(i in seq_along(o$V1)) {
            x<-c(dates[i]-0.125,dates[i]+0.25,
                 dates[i]+0.125,dates[i]-0.125)
            y<-c(o$V8[i]/100-(o$V9[i]/100)*2,
                 o$V8[i]/100-(o$V9[i]/100)*2,
                 o$V8[i]/100+(o$V9[i]/100)*2,
                 o$V8[i]/100+(o$V9[i]/100)*2)
            grid.polygon(x=unit(x,'native'),
                         y=unit(y,'native'),
                      gp=gp)
          }
         gp=gpar(col=rgb(0.4,0.4,1,1),fill=rgb(0.4,0.4,1,1))
         for(i in seq_along(o$V1)) {
            x<-c(dates[i]-0.125,dates[i]+0.25,
                 dates[i]+0.125,dates[i]-0.125)
            y<-c(o$V6[i]/100-(o$V7[i]/100)*2,
                 o$V6[i]/100-(o$V7[i]/100)*2,
                 o$V6[i]/100+(o$V7[i]/100)*2,
                 o$V6[i]/100+(o$V7[i]/100)*2)
            grid.polygon(x=unit(x,'native'),
                         y=unit(y,'native'),
                      gp=gp)
          }
            
        # Observation
         gp=gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1))
         grid.points(x=unit(dates,'native'),
                     y=unit(o$V2,'native'),
                     size=unit(0.005,'npc'),
                     pch=20,
                     gp=gp)
      popViewport()
   popViewport()
popViewport()
     

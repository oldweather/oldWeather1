library(grid)

p<-read.table('ports.txt',sep='\t',quote='',stringsAsFactors=FALSE)

png(filename='ports.png',width=600,height=300)

pushViewport(dataViewport(xData=c(-180,180),yData=c(-90,90)))

   grid.points(x=unit(p$V2,'native'),y=unit(p$V3,'native'),
               size=unit(0.005,'npc'),pch=20)

upViewport()
dev.off()

# Transfer logbook images from Gina's disc to MO MASS system

ArchiveDir <- 'moose:/adhoc/users/philip.brohan/logbook_images/NA_WW1/'
SourceDir <- '/media/External_113/data/ADM_disc_7'

process.dir<-function(dir.name) {
  moose.dir<-ArchiveDir
 files<-list.files(dir.name,pattern="\\.") # only want jpgs really
  if(length(files)>0) pack.contents(dir.name,moose.dir)
  dirs<-list.dirs(dir.name,recursive=FALSE)
  for(dir in dirs) {
    process.dir(dir)
  }
}

pack.contents<-function(dir.name,moose.dir) {
  dir.base<-basename(dir.name)
  dir.base<-gsub("\\s+","_",dir.base)
  dir.base<-gsub("\\[","",dir.base)
  dir.base<-gsub("\\]","",dir.base)
  dir.base<-gsub("ADM.53","ADM53",dir.base)
  t.dir<-tempdir()
  tar.file<-sprintf("%s/%s.tgz",tempdir(),dir.base)
  cat("cd \"",dir.name,"\"\n",sep="")
  command<-sprintf("tar -czf %s --no-recursion *.*",
                   tar.file)
  cat("mkdir -p ",t.dir,"\n")
  cat(command,"\n")
  cat("moo put ",tar.file,moose.dir,"\n")
  cat("rm -r ",t.dir,"\n")
}
  
process.dir(SourceDir)

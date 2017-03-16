# Run a daily oldWeather render task on SPICE

library(lubridate)

current.day<-ymd("1920-01-02")
end.day<-ymd("1920-12-31")

peak.no.jobs<-500

while(current.day<=end.day) {
  in.system<-system('squeue --user hadpb',intern=TRUE)
  n.new.jobs<-peak.no.jobs-length(in.system)
  while(n.new.jobs<8) {
   Sys.sleep(10)
   in.system<-system('squeue --user hadpb',intern=TRUE)
   n.new.jobs<-peak.no.jobs-length(in.system)
  }
  for(hour in c(0,3,6,9,12,18,21)) {
      sink('ICOADS3.daily.slm')
      cat('#!/bin/ksh -l\n')
      cat('#SBATCH --output=/scratch/hadpb/slurm_output/oW1.hourly-%j.out\n')
      cat('#SBATCH --qos=normal\n')
      cat('#SBATCH --mem=5000\n')
      cat('#SBATCH --ntasks=1\n')
      cat('#SBATCH --ntasks-per-core=2\n')
      cat('#SBATCH --time=10\n')
      cat(sprintf("./oW_new_v_old.R --month=%d --day=%d --hour=%d\n",
                     month(current.day),day(current.day),hour))
      sink()
      system('sbatch ICOADS3.daily.slm')
      unlink('sbatch ICOADS3.daily.slm')
   }
   current.day<-current.day+days(1)
}

#!/usr/bin/env python

# Get the total distance travelled by the ships from the IMMA files

import os
import glob
import sys
sys.path.append("%s/../../../pyIMMA" % os.path.dirname(__file__))
import IMMA
from math import sin, cos, sqrt, atan2, radians

# IMMA files hav lat:lon - use Haversine to convert to km
def hdist(lat1,lon1,lat2,lon2):
    R = 6373.0 # radius of Earth (km)
    # Convert inputs degrees->radians
    rlat1 = radians(lat1)
    rlon1 = radians(lon1)
    rlat2 = radians(lat2)
    rlon2 = radians(lon2)
    dlon = rlon2 - rlon1
    dlat = rlat2 - rlat1
    a = sin(dlat / 2)**2 + cos(rlat1) * cos(rlat2) * sin(dlon / 2)**2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))
    distance = R * c
    return distance

total = 0
for file in glob.glob("%s/../../imma/*.imma.gz" %  os.path.dirname(__file__)):
   llat = None
   llon = None
   obs = IMMA.get(file)
   for ob in obs:
       if (ob['LAT'] is None or ob['LON'] is None):
           continue
       dist = None
       if llat is not None and llon is not None:
           dist = hdist(llat,llon,ob['LAT'],ob['LON'])
       llat = ob['LAT']
       llon = ob['LON']
       if dist is not None:
           total += dist
   print("%s %f" % (file,total))


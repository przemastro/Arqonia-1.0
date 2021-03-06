#!/usr/bin/env python

import numpy as np
import pyfits
from scipy import ndimage
import pylab
import numpy
import math
import os
import time
import ConfigParser
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure


env = ConfigParser.RawConfigParser()
env.read('../resources/env.properties')
backendInputFits = env.get('FilesCatalogs', 'catalog.backendInputFits');
frontendInputFits = env.get('FilesCatalogs', 'catalog.frontendInputFits');



def plot(fileName, conversionType):
   try:
      fn = backendInputFits+fileName+".fits"
      sig_fract = 5.0
      percent_fract = 0.01
      hdulist = pyfits.open(fn)
      img_data_raw = hdulist[0].data
      width = float(img_data_raw.shape[1])/100
      height = float(img_data_raw.shape[0])/100
      hdulist.close()
      img_data_raw = numpy.array(img_data_raw, dtype=float)
      sky, num_iter = sky_mean_sig_clip(img_data_raw, sig_fract, percent_fract, max_iter=1)
      img_data = img_data_raw - sky
      min_val = 0.0

      #plotting
      if(conversionType == "Power"):
         new_img = power(img_data, power_index=3.0, scale_min = min_val)
         Rotated_Plot = ndimage.rotate(new_img, 180)
         Flipped_Plot = np.fliplr(Rotated_Plot)
         fig = Figure(figsize=(width, height))
         fig.figimage(Flipped_Plot, cmap='gray')
         resultFile = conversionType+"_"+fileName
         canvas = FigureCanvas(fig)
         canvas.print_figure(frontendInputFits+resultFile+".png")
      elif(conversionType == "Linear"):
         new_img = linear(img_data, scale_min = min_val)
         Rotated_Plot = ndimage.rotate(new_img, 180)
         Flipped_Plot = np.fliplr(Rotated_Plot)
         fig = Figure(figsize=(width, height))
         fig.figimage(Flipped_Plot, cmap='gray')
         resultFile = conversionType+"_"+fileName
         canvas = FigureCanvas(fig)
         canvas.print_figure(frontendInputFits+resultFile+".png")
      elif(conversionType == "Hist"):
         new_img = histeq(img_data_raw, num_bins=256)
         Rotated_Plot = ndimage.rotate(new_img, 180)
         Flipped_Plot = np.fliplr(Rotated_Plot)
         fig = Figure(figsize=(width, height))
         fig.figimage(Flipped_Plot, cmap='gray')
         resultFile = conversionType+"_"+fileName
         canvas = FigureCanvas(fig)
         canvas.print_figure(frontendInputFits+resultFile+".png")

      looper=1
      while(looper<100):
          time.sleep(1)
          if os.path.isfile(frontendInputFits+resultFile+".png"):
              break
          else:
              looper = looper + 1
              continue
   except(RuntimeError, TypeError, NameError):
       print 'errors in convertPlots function'

def power(inputArray, power_index=3.0, scale_min=None, scale_max=None):
    imageData=numpy.array(inputArray, copy=True)

    if scale_min == None:
        scale_min = imageData.min()
    if scale_max == None:
        scale_max = imageData.max()
    factor = 1.0 / math.pow((scale_max - scale_min), power_index)
    indices0 = numpy.where(imageData < scale_min)
    indices1 = numpy.where((imageData >= scale_min) & (imageData <= scale_max))
    indices2 = numpy.where(imageData > scale_max)
    imageData[indices0] = 0.0
    imageData[indices2] = 1.0
    imageData[indices1] = numpy.power((imageData[indices1] - scale_min), power_index)*factor

    return imageData


def sky_mean_sig_clip(input_arr, sig_fract, percent_fract, max_iter=100, low_cut=True, high_cut=True):
    work_arr = numpy.ravel(input_arr)
    old_sky = numpy.mean(work_arr)
    sig = work_arr.std()
    upper_limit = old_sky + sig_fract * sig
    lower_limit = old_sky - sig_fract * sig
    if low_cut and high_cut:
        indices = numpy.where((work_arr < upper_limit) & (work_arr > lower_limit))
    else:
        if low_cut:
            indices = numpy.where((work_arr > lower_limit))
        else:
            indices = numpy.where((work_arr < upper_limit))
    work_arr = work_arr[indices]
    new_sky = numpy.mean(work_arr)
    iteration = 0
    while ((math.fabs(old_sky - new_sky)/new_sky) > percent_fract) and (iteration < max_iter) :
        iteration += 1
        old_sky = new_sky
        sig = work_arr.std()
        upper_limit = old_sky + sig_fract * sig
        lower_limit = old_sky - sig_fract * sig
        if low_cut and high_cut:
            indices = numpy.where((work_arr < upper_limit) & (work_arr > lower_limit))
        else:
            if low_cut:
                indices = numpy.where((work_arr > lower_limit))
            else:
                indices = numpy.where((work_arr < upper_limit))
        work_arr = work_arr[indices]
        new_sky = numpy.mean(work_arr)
    return (new_sky, iteration)


def linear(inputArray, scale_min=None, scale_max=None):
    imageData=numpy.array(inputArray, copy=True)

    if scale_min == None:
        scale_min = imageData.min()
    if scale_max == None:
        scale_max = imageData.max()

    imageData.clip(min=scale_min, max=scale_max)
    imageData = (imageData -scale_min) / (scale_max - scale_min)
    indices = numpy.where(imageData < 0)
    imageData[indices] = 0.0

    return imageData


def histeq(inputArray, num_bins=1024):

    imageData=numpy.array(inputArray, copy=True)

    # histogram equalisation: we want an equal number of pixels in each intensity range
    sortedDataIntensities=numpy.sort(numpy.ravel(imageData))
    median=numpy.median(sortedDataIntensities)

    # Make cumulative histogram of data values, simple min-max used to set bin sizes and range
    dataCumHist=numpy.zeros(num_bins)
    minIntensity=sortedDataIntensities.min()
    maxIntensity=sortedDataIntensities.max()
    histRange=maxIntensity-minIntensity
    binWidth=histRange/float(num_bins-1)
    for i in range(len(sortedDataIntensities)):
        binNumber=int(math.ceil((sortedDataIntensities[i]-minIntensity)/binWidth))
        addArray=numpy.zeros(num_bins)
        onesArray=numpy.ones(num_bins-binNumber)
        onesRange=range(binNumber, num_bins)
        numpy.put(addArray, onesRange, onesArray)
        dataCumHist=dataCumHist+addArray

    # Make ideal cumulative histogram
    idealValue=dataCumHist.max()/float(num_bins)
    idealCumHist=numpy.arange(idealValue, dataCumHist.max()+idealValue, idealValue)

    # Map the data to the ideal
    for y in range(imageData.shape[0]):
        for x in range(imageData.shape[1]):
            # Get index corresponding to dataIntensity
            intensityBin=int(math.ceil((imageData[y][x]-minIntensity)/binWidth))

    # Guard against rounding errors (happens rarely I think)
    if intensityBin<0:
        intensityBin=0
    if intensityBin>len(dataCumHist)-1:
        intensityBin=len(dataCumHist)-1

    # Get the cumulative frequency corresponding intensity level in the data
    dataCumFreq=dataCumHist[intensityBin]

    # Get the index of the corresponding ideal cumulative frequency
    idealBin=numpy.searchsorted(idealCumHist, dataCumFreq)
    idealIntensity=(idealBin*binWidth)+minIntensity
    imageData[y][x]=idealIntensity

    scale_min = imageData.min()
    scale_max = imageData.max()
    imageData.clip(min=scale_min, max=scale_max)
    imageData = (imageData -scale_min) / (scale_max - scale_min)
    indices = numpy.where(imageData < 0)
    imageData[indices] = 0.0

    return imageData
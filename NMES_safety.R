########################################################################
# Function to calculate NMES power per area (I_rms/cm2)
# author: Monica Perusquia-Hernandez
# date: 2021.03.08
########################################################################

NMES_power <- function(...) {
  paremeters <- list(...)
  
  methodRMS <- paremeters[[1]] # PWM or SAE
  i_amp <- paremeters[[2]]   # Instant current amplitude
  pulseWidth_PW <- paremeters[[3]] * 1e-06 # parameter in microseconds, resulting value in seconds
  cycleDuration <- paremeters[[4]] * 1e-03 # parameter in in milliseconds, resulting value in seconds
  electrodeArea <- paremeters[[5]]  # Area of the electrode in cm^2
  samplingRate <- paremeters[[6]]  # in Hz: 100 000 data points every 1 second
  pulseTrainDuration_PT <- paremeters[[7]] # in seconds
  
  # Calculated parameters
  delayBetweenPulses_PD <- cycleDuration - (2 * pulseWidth_PW) # in seconds
  numberPulsesInTrain <- pulseTrainDuration_PT / cycleDuration # it must be an integer result for simplicity
  
  # Wave
  currentWave <- rep(
    c(rep(i_amp, pulseWidth_PW*samplingRate),
      rep(-i_amp, pulseWidth_PW*samplingRate),
      rep(0, delayBetweenPulses_PD*samplingRate)),
    numberPulsesInTrain
  )
  
  # Timeline
  sampleNumber <- c(1:length(currentWave))
  
  # Convert as data frame
  currentWave_df <- as.data.frame(sampleNumber)
  currentWave_df$currentWave <- currentWave
  
  # Select only one cycle
  oneCycleCurrent <- currentWave_df[1:(cycleDuration * samplingRate),]
  
  # Method selection to calculate RMS
  if (methodRMS == "SAE") {
    I_rms_oneCycleCurrent <- sqrt(mean(oneCycleCurrent$currentWave^2))
    PWM_dutyCycleAverageCurrent <- NA
  }
  if (methodRMS == "PWM") {
    # prepare for PWM
    oneCycleCurrent_abs <- abs(oneCycleCurrent)
    
    # calculate Duty Cycle D
    dutyCycle_D <- (2*pulseWidth_PW) / cycleDuration
    
    # calculate apparent average current
    PWM_dutyCycleAverageCurrent <- dutyCycle_D * i_amp
    PWM_dutyCycleAverageCurrent
    
    # calculate RMS from PWM
    I_rms_oneCycleCurrent <- (1/sqrt(dutyCycle_D)) * PWM_dutyCycleAverageCurrent
  }
  
  # Surface area
  I_rms_oneCycleCurrent_per_area <- I_rms_oneCycleCurrent / electrodeArea
  
  # Formatting the output as dataframe
  power_surface <- data.frame (I_rms  = I_rms_oneCycleCurrent,
                               PWM_dutyCycleAverageCurrent = PWM_dutyCycleAverageCurrent,
                               I_rms_per_area = I_rms_oneCycleCurrent_per_area
  )
  return(power_surface)
  
}


########################################################################
# Use case
########################################################################

# Parameters
# methodRMS <- "PWM"
methodRMS <- "SAE"
i_amp <- 18   # Instant current amplitude
pulseWidth_PW <- 50 # parameter in microseconds
electrodeArea <- 1.44  # Area of the electrode in cm^2
samplingRate <- 100000  # in Hz: 100 000 data points every 1 second
pulseTrainDuration_PT <- 2 # in seconds

cycleDuration <- 20 # parameter in in milliseconds

# If you want to input the number of cycles per second (cycle frequency) instead, 
# simply use the following two lines and input the cycleDuration in the function:

# cycleFrequency <- 10 # In Hertz [Hz]
# cycleDuration <- 1 / cycleFrequency # Result in seconds

# Call the function
# The output is as: I_rms_oneCycleCurrent, PWM_dutyCycleAverageCurrent, I_rms_oneCycleCurrent_per_area
NMES_power(methodRMS, i_amp, pulseWidth_PW, cycleDuration, electrodeArea, samplingRate, pulseTrainDuration_PT)


########################################################################
#### Plots examples
########################################################################

# library(tidyverse) 
# library(plotly) # for interactive plotting

# # Plot wave to verify shape and parameters
# plot <- ggplot(data=currentWave_df, aes(x=sampleNumber, y=currentWave)) +
#   geom_line(color="blue")
# plot <- ggplotly(plot) # Turn to an interactive plot
# plot # display the plot
# 
# # Plot the one cycle
# plot <- ggplot(data=oneCycleCurrent, aes(x=sampleNumber, y=currentWave)) +
#   geom_line(color="red")
# plot <- ggplotly(plot) # Turn to an interactive plot
# plot # display the plot



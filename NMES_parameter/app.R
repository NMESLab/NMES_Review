########################################################################
# Shiny web application to calculate NMES power per area (I_rms/cm2)
# author: Monica Perusquia-Hernandez
# date: 2021.03.10
########################################################################

########################################################################
# Libraries

library(shiny)
library(tidyverse)
library(plotly) # for interactive plotting

########################################################################
# Required functions

calculateParameters <- function(i_amp,pulseWidth_PW,cycleDuration,electrodeArea,samplingRate,pulseTrainDuration_PT,cycleFrequency) {
    # Parameter transformations
    pulseWidth_PW <- pulseWidth_PW * 1e-06 # from microseconds to seconds
    cycleDuration <- cycleDuration * 1e-03 # from milliseconds to seconds

    if(is.na(cycleDuration)){
        cycleDuration <- 1 / cycleFrequency # Result in seconds
    } else {
        cycleFrequency <- 1 / cycleDuration # Result in Hz
    }
    
    delayBetweenPulses_PD <- cycleDuration - (2 * pulseWidth_PW) # in seconds
    numberPulsesInTrain <- pulseTrainDuration_PT / cycleDuration # it must be an integer result for simplicity
    
    # Formatting the output as dataframe, consider using shiny switch next time
    wave_parameters <- data.frame ( i_amp = i_amp,
                                    pulseWidth_PW = pulseWidth_PW,
                                    cycleDuration = cycleDuration,
                                    cycleFrequency = cycleFrequency,
                                    electrodeArea = electrodeArea,
                                    samplingRate = samplingRate,
                                    pulseTrainDuration_PT = pulseTrainDuration_PT,
                                    delayBetweenPulses_PD  = delayBetweenPulses_PD,
                                    numberPulsesInTrain = numberPulsesInTrain
    )
    return(wave_parameters)
}

constructNMESwave <- function(wave_parameters) {
    # Wave
    currentWave <- rep(
        c(rep(wave_parameters$i_amp, wave_parameters$pulseWidth_PW*wave_parameters$samplingRate),
          rep(-wave_parameters$i_amp, wave_parameters$pulseWidth_PW*wave_parameters$samplingRate),
          rep(0, wave_parameters$delayBetweenPulses_PD*wave_parameters$samplingRate)),
        wave_parameters$numberPulsesInTrain
    )
    
    # Timeline
    sampleNumber <- c(1:length(currentWave))
    
    # Convert as data frame
    currentWave_df <- as.data.frame(sampleNumber)
    currentWave_df$currentWave <- currentWave
    
    # Select only one cycle
    oneCycleCurrent <- currentWave_df[1:(wave_parameters$cycleDuration * wave_parameters$samplingRate),]
    
    return(list(currentWave_df,oneCycleCurrent))
}

NMES_power <- function(methodRMS,i_amp,pulseWidth_PW,cycleDuration,electrodeArea,samplingRate,pulseTrainDuration_PT,oneCycleCurrent) {
    # methodRMS  # PWM or Sample-wise
    # i_amp  # Instant current amplitude
    # pulseWidth_PW # in seconds
    # cycleDuration # in seconds
    # electrodeArea  # Area of the electrode in cm^2
    # samplingRate  # in Hz: 100 000 data points every 1 second
    # pulseTrainDuration_PT # in seconds
    
    # Method selection to calculate RMS
    if (methodRMS == "Sample-wise") {
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
# Shiny App

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("NMES parameter calculator"),
    
    fluidRow(
        
        # Sidebar 
        column(4,
               wellPanel(
                   numericInput(inputId = "i_amp",
                                label = "Current amplitude of the pulses in mA:",
                                value = 18),
                   
                   numericInput(inputId = "pulseWidth_PW",
                                label = "Pulse Width in microseconds:",
                                value = 50),
                   
                   numericInput(inputId = "electrodeArea",
                                label = "Electrode Area in cm2:",
                                value = 1.44),
                   
                   numericInput(inputId = "pulseTrainDuration_PT",
                                label = "Duration of the pulse train in seconds:",
                                value = 1),
                   
                   numericInput(inputId = "samplingRate",
                                label = "Sampling rate for plotting:",
                                value = 100000),
                   
                   radioButtons(
                       inputId = "duration_freq_cycle_rb",
                       label = "Choose a your preferred input:",
                       choices = c("Cycle_duration", "Cycle_frequency"),
                       selected = "Cycle_duration",
                       inline = TRUE
                   ),
                   
                   numericInput(inputId = "Cycle",
                                label = "Input value:",
                                value = 20),
                   
                   radioButtons(
                       inputId = "methodRMS_rb",
                       label = "Choose a method:",
                       choices = c("PWM", "Sample-wise"), # Sample by sample
                       selected = "Sample-wise",
                       inline = TRUE
                   ),
                   
                   p(),
                   h4("Graphical representation of the stimulation parameters:"),
                   img(src = "NameConventionWBG.png", width = "100%")
               )       
        ),
        
        # MainPanel
        column(8,
               fluidRow(
                   h4("Calculation results:"),
                   column(3,
                          p("Delay between pulses [s]:"),
                          verbatimTextOutput("delay_out"),
                          p()
                        ),
                   column(3,
                          p("I_rms [mA]:"),
                          verbatimTextOutput("I_rms_out"),
                          p()
                        ),
                   column(3,
                          p("PWM current per DutyCycle [mA]:"),
                          verbatimTextOutput("PWM_dutyCycleAverageCurrent_out"),
                          p()
                        ),
                   column(3,
                          p("I_rms per electrode area [mA/cm2]:"),
                          verbatimTextOutput("I_rms_per_area_out"),
                          p()
                        )
               ),

               fluidRow(
                   column(4,
                          h4("Biphasic pulse:"),
                          plotlyOutput("NMESplot_zoomin")
                   ),
                   column(5,
                          h4("Biphasic pulse and off period:"),
                          plotlyOutput("NMESplot")
                          )
               ),
               
               
               fluidRow(
                   h4("Train of pulses:"),
                   plotlyOutput("NMESplotTrain") # plotlyOutput vs plotOutput
               ),
               
        )
    
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    
    precalculation <- reactive({
        if (input$duration_freq_cycle_rb == "Cycle_duration") {
            cycleDuration <- input$Cycle
            cycleFrequency <- NA
        } else {
            cycleDuration <- NA
            cycleFrequency <- input$Cycle
        }
        wave_parameters <- calculateParameters(input$i_amp,input$pulseWidth_PW,cycleDuration,input$electrodeArea,input$samplingRate,input$pulseTrainDuration_PT,cycleFrequency)
        return(wave_parameters)
    })
    
    # Results
    output$delay_out <- renderText({
        wave_parameters <- precalculation()
        wave_parameters$delayBetweenPulses_PD
    })
    
    output$I_rms_out <- renderPrint({
        wave_parameters <- precalculation()
        waves <- constructNMESwave(wave_parameters)
        currentWave_df <- waves[[1]]
        oneCycleCurrent <- waves[[2]]
        power_surface <- NMES_power(input$methodRMS_rb,wave_parameters$i_amp,wave_parameters$pulseWidth_PW,wave_parameters$cycleDuration,wave_parameters$electrodeArea,wave_parameters$samplingRate,wave_parameters$pulseTrainDuration_PT,oneCycleCurrent)
        power_surface$I_rms
    })
    
    output$PWM_dutyCycleAverageCurrent_out <- renderPrint({
        wave_parameters <- precalculation()
        waves <- constructNMESwave(wave_parameters)
        currentWave_df <- waves[[1]]
        oneCycleCurrent <- waves[[2]]
        power_surface <- NMES_power(input$methodRMS_rb,wave_parameters$i_amp,wave_parameters$pulseWidth_PW,wave_parameters$cycleDuration,wave_parameters$electrodeArea,wave_parameters$samplingRate,wave_parameters$pulseTrainDuration_PT,oneCycleCurrent)
        power_surface$PWM_dutyCycleAverageCurrent
    })
    
    output$I_rms_per_area_out <- renderPrint({
        wave_parameters <- precalculation()
        waves <- constructNMESwave(wave_parameters)
        currentWave_df <- waves[[1]]
        oneCycleCurrent <- waves[[2]]
        power_surface <- NMES_power(input$methodRMS_rb,wave_parameters$i_amp,wave_parameters$pulseWidth_PW,wave_parameters$cycleDuration,wave_parameters$electrodeArea,wave_parameters$samplingRate,wave_parameters$pulseTrainDuration_PT,oneCycleCurrent)
        power_surface$I_rms_per_area
    })
    
    output$NMESplotTrain <- renderPlotly({ # renderPlotly vs renderPlot
        wave_parameters <- precalculation()
        waves <- constructNMESwave(wave_parameters)
        
        currentWave_df <- waves[[1]]
        oneCycleCurrent <- waves[[2]]
        currentWave_df$time_ms <- (currentWave_df$sampleNumber / wave_parameters$samplingRate) * 1e3
        
        plot <- ggplot(data=currentWave_df, aes(x=time_ms, y=currentWave)) +
          geom_step(color="blue")
        ggplotly(plot) # Turn to an interactive plot
    })

    output$NMESplot <- renderPlotly({
        wave_parameters <- precalculation()
        waves <- constructNMESwave(wave_parameters)
        
        currentWave_df <- waves[[1]]
        oneCycleCurrent <- waves[[2]]
        oneCycleCurrent$time_ms <- (oneCycleCurrent$sampleNumber / wave_parameters$samplingRate) * 1e3
        
        plot <- ggplot(data=oneCycleCurrent, aes(x=time_ms, y=currentWave)) +
            geom_step(color="red")
        ggplotly(plot) 
    })
    
    output$NMESplot_zoomin <- renderPlotly({
        wave_parameters <- precalculation()
        waves <- constructNMESwave(wave_parameters)
        
        currentWave_df <- waves[[1]]
        oneCycleCurrent <- waves[[2]]
        index <- oneCycleCurrent$currentWave != 0
        oneCycleCurrent$time_ms <- (oneCycleCurrent$sampleNumber / wave_parameters$samplingRate) * 1e3
        
        plot <- ggplot(data=oneCycleCurrent[index,], aes(x=time_ms, y=currentWave)) +
            geom_step(color="red")
        ggplotly(plot) 
    })
}

# Run the application 
shinyApp(ui = ui, server = server)

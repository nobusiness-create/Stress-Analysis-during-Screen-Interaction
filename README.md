# Stress-Analysis-during-Screen-Interaction
A biomedical signal processing project that analyzes physiological stress  using PPG signals during screen interaction. Measures Heart Rate Variability (HRV)  analysis during prolonged digital device exposure.

## Contents
- [About](#About)
- [Functioning](#Functioning)
- [Hardware](#Hardware)
- [Software](#Software)
- [Signal_Processing](#Signal_Processing)
- [DAshboard](#DAshboard)
- [Referances](#Referances)

## About 
Screen time has surged exponentially in the last decade.This has led to heightened stress, mental exhaustion and disruptions in nervous system functions.
While current assessment methods often rely on self-reported data, which can be subjective.Physiological signals offer a more objective and reliable means of measurement.

We have used PPG signals by a MAX30102 sensor to measure Heart Rate Variability (HRV)  across different screen exposure conditions.They following questions have been tried to answer through this project.
- Does **screen content type** affect HRV differently? 
- Does HRV decrease with longer screen exposure duration?
- Does screen brightness affect the stress response?

## Hardware
- ESP32
- PPG Sensor: MAX30102

  ### Wiring
 
VIN     →  3.3V

GND     →  GND

SDA     →  GPIO 21

SCL     →  GPIO 22

## Software
| Tool | Purpose |
|------|---------|
| Matlab | Signal processing, filtering, HRV extraction, comparison plots |
| Python | Dashboard backend |
| Streamlit  | Dashboard frontend |
| Arduino IDE | Firmware for ESP32  |

## Experimental Design
Subject undergoes 4 screen content conditions, each lasting 15–20 minutes, with a 5-minute rest between sessions.

## Signal Processing

Raw PPG Signal (150 Hz)
        
   1. Butterworth Bandpass Filter 
        
   2. Peak Detection 
    findpeaks() in MATLAB  
        
        
  3. RR Interval Calculation 
    Time difference between consecutive heartbeat peaks (ms)
        
        
   4. HRV Feature Extraction 
    
      Mean RR  →  Average beat interval      
      SDNN     →  Overall HRV variability    
      RMSSD    →  Parasympathetic activity   
    
        
  5. Multi-Condition Comparison 
    Baseline vs. Reading vs. Studying vs. Social Media vs. Gaming
<img width="881" height="147" alt="Image" src="https://github.com/user-attachments/assets/d6bf0232-dac3-449c-87ed-a19df0ad8d17" />

## Dashboard
(in progress)

## Future Work
-  Test additional content types (video calls, YouTube, news)
-  Real-time stress alert — notify user to take a break when HRV drops below personal threshold
-  Mobile app version with Bluetooth PPG sensor integration

##  Referances
1. IEEE Xplore [6908199] — PPG-based heart rate monitoring
2. IEEE Xplore [10605974] — HRV analysis in stress detection
3. IEEE Xplore [4353036] — Digital filtering of biomedical signals
4. IEEE Xplore [7032208] — Wearable sensors for physiological monitoring
5. IEEE Xplore [9844174] — Screen exposure and autonomic response
6. IEEE Xplore [4671121] — Photoplethysmography signal processing

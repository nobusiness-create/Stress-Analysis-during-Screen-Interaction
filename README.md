# PPG-Based Physiological Stress Analysis

A biomedical signal processing project that investigates how different types of screen content affect physiological stress levels using Photoplethysmography (PPG)-derived Heart Rate Variability (HRV) metrics.

The system combines a MAX30102 PPG sensor, ESP32 microcontroller, MATLAB-based signal processing, and ThingSpeak cloud monitoring to quantify stress responses during various screen interaction scenarios.

---

## Contents

* Problem Statement
* Experimental Design
* System Architecture
* Hardware
* Software
* Signal Processing Pipeline
* HRV Metrics
* Cloud Monitoring
* Results
* Key Findings
* Limitations
* Future Work

---


## Problem Statement

### Research Questions

The rapid increase in digital device usage has led to growing concerns regarding its impact on mental well-being and physiological stress. While numerous studies have investigated stress using Heart Rate Variability (HRV), most treat screen time as a single factor and do not differentiate between the types of content being consumed.

Different forms of screen interaction, such as social media browsing, gaming, studying, and leisure reading, impose varying cognitive and emotional demands on users. Consequently, they may elicit distinct physiological responses that cannot be accurately captured by measuring screen exposure duration alone.

This project aims to develop a real-time physiological stress monitoring system using Photoplethysmography (PPG) signals acquired from a MAX30102 sensor. By extracting HRV features such as SDNN, RMSSD, pNN50, and LF/HF ratio, the system evaluates and compares stress responses under different screen-content conditions.

The study seeks to answer the following questions:

Does the type of screen content influence physiological stress levels?
How do HRV metrics vary across different screen interaction scenarios?
Can low-cost PPG sensors provide an effective method for continuous stress monitoring?
Is it possible to quantify stress using HRV-based indicators and visualize it in real time through cloud monitoring platforms?

The outcome of this work contributes toward understanding the relationship between screen content and physiological stress, while providing a foundation for future personalized digital wellness and stress-management systems.
---

## Experimental Design

Four screen-content conditions were evaluated:

* 📱 Social Media
* 🎮 Gaming
* 📚 Studying
* 📖 Leisure Reading

### Additional Variables

* Screen Brightness
* Exposure Duration

### Session Structure

* 15–20 minutes per condition
* 5-minute rest interval between sessions
* Continuous PPG acquisition during exposure

### Measured Parameters

* Heart Rate (BPM)
* SDNN
* RMSSD
* pNN50
* LF/HF Ratio
* Stress Score (0–100)

---

## System Architecture

MAX30102 Sensor
↓
ESP32 Microcontroller
↓
MATLAB Signal Processing
↓
HRV Feature Extraction
↓
ThingSpeak Cloud Dashboard
↓
Data Logging & Analysis

### Sensor Configuration

| Parameter      | Value  |
| -------------- | ------ |
| Sampling Rate  | 100 Hz |
| LED Brightness | 20     |
| Pulse Width    | 411 μs |
| ADC Range      | 4096   |

Each 30-second window is processed independently and logged with:

* Timestamp
* Screen condition
* Heart rate
* HRV metrics
* Stress score

---

## Hardware

### Components

* ESP32 Development Board
* MAX30102 PPG Sensor

### Wiring

| MAX30102 | ESP32   |
| -------- | ------- |
| VIN      | 3.3V    |
| GND      | GND     |
| SDA      | GPIO 21 |
| SCL      | GPIO 22 |

---

## Software

| Tool        | Purpose                              |
| ----------- | ------------------------------------ |
| MATLAB      | Signal processing and HRV extraction |
| Arduino IDE | ESP32 firmware                       |
| ThingSpeak  | Cloud data storage and visualization |
| Python      | Dashboard backend                    |
| Streamlit   | Dashboard frontend                   |

---

## Signal Processing Pipeline

### 1. Bandpass Filtering

* 4th-order Butterworth filter
* Frequency range: 0.5–4.0 Hz
* Zero-phase filtering using `filtfilt()`

### 2. Peak Detection

PPG peaks are detected using MATLAB's `findpeaks()`.

Parameters:

* Minimum Peak Distance = 0.4 s
* Minimum Prominence = 0.8 × σ

### 3. RR Interval Calculation

RR intervals are obtained from the time difference between consecutive heartbeat peaks.

Valid physiological range:

* 0.4 s to 1.3 s
* Equivalent to 30–150 BPM

### 4. HRV Feature Extraction

#### Time-Domain Features

* Mean RR
* SDNN
* RMSSD
* pNN50

#### Frequency-Domain Features

* Spline interpolation at 4 Hz
* FFT-based spectral analysis
* LF/HF ratio calculation

### 5. Stress Score Estimation

A heuristic stress score is computed as:

Stress Score = clamp(0,100) [ (LF/HF × 15) + (50 − RMSSD) ]

Higher scores indicate greater physiological stress.

---

## HRV Metrics

### SDNN (ms)

Standard deviation of RR intervals.

* Represents overall HRV
* Lower values generally indicate higher stress

### RMSSD (ms)

Root mean square of successive RR differences.

* Reflects parasympathetic activity
* Decreases under stress

### pNN50 (%)

Percentage of RR interval pairs differing by more than 50 ms.

* Indicates vagal activity
* Lower values suggest elevated stress

### LF/HF Ratio

Ratio of low-frequency to high-frequency spectral power.

* Indicates sympathetic dominance
* Higher values correspond to increased stress

---

## Cloud Monitoring

All computed metrics are uploaded to ThingSpeak in real time.

### ThingSpeak Fields

| Field   | Data             |
| ------- | ---------------- |
| Field 1 | Heart Rate       |
| Field 2 | SDNN             |
| Field 3 | RMSSD            |
| Field 4 | pNN50            |
| Field 5 | LF/HF Ratio      |
| Field 6 | Stress Score     |
| Field 7 | Screen Condition |

### Live Dashboard Features

* Real-time heart-rate monitoring
* HRV trend visualization
* LF/HF ratio tracking
* Stress-score gauge
* Condition labeling
* CSV export of session data

---

## Sample Results

### Social Media Session

| Metric      | Value    |
| ----------- | -------- |
| Heart Rate  | 82.4 BPM |
| SDNN        | 38.2 ms  |
| RMSSD       | 29.7 ms  |
| pNN50       | 18.4 %   |
| LF/HF Ratio | 2.41     |

---

## Key Findings

### Preliminary Stress Ranking

| Condition       | Stress Score |
| --------------- | ------------ |
| Social Media    | 68           |
| Gaming          | 62           |
| Studying        | 55           |
| Leisure Reading | 34           |

### Observations

* Social media generated the highest stress response.
* Gaming produced elevated heart rate and sympathetic activity.
* Studying showed moderate physiological stress.
* Leisure reading exhibited the lowest stress levels and greater parasympathetic recovery.

These results suggest that screen content type is an important factor influencing physiological stress and should not be ignored when studying screen exposure.

---

## Limitations

* Single-subject pilot study
* Small sample size
* Motion artifacts in finger-based PPG
* Stress score requires clinical validation
* Controlled laboratory environment

---

## Future Work

* Multi-subject validation study
* Additional screen-content categories

  * Video calls
  * YouTube
  * News consumption
* Machine-learning-based content classification
* Wrist-worn PPG implementation
* EDA/GSR sensor fusion
* Mobile application development
* Real-time stress alerts

---

## Conclusion

This project demonstrates a complete end-to-end physiological stress monitoring system using low-cost hardware and PPG-based HRV analysis.

The developed pipeline successfully extracts HRV metrics in real time, uploads them to the cloud, and enables comparison of physiological stress responses across different screen-content conditions.

Results indicate that social media and gaming induce higher stress responses than leisure reading, highlighting the importance of considering content type rather than screen time alone when evaluating digital well-being.

## References

1. IEEE Xplore Document 6908199 — PPG-Based Heart Rate Monitoring Using Wearable Sensors.

2. IEEE Xplore Document 10605974 — Heart Rate Variability Analysis for Stress Detection and Assessment.

3. IEEE Xplore Document 4353036 — Digital Filtering Techniques for Biomedical Signal Processing.

4. IEEE Xplore Document 7032208 — Wearable Physiological Sensors for Continuous Health Monitoring.

5. IEEE Xplore Document 9844174 — Effects of Screen Exposure on Autonomic Nervous System Activity.

6. IEEE Xplore Document 4671121 — Photoplethysmography Signal Acquisition and Processing Methods.

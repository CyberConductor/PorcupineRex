# PorcupineRex

<p align="center">
  <img src="assets/logo.png" width="250">
</p>

<p align="center">
  <b>Advanced Honeypot System for Real-Time Threat Detection</b>
</p>

---

## 📌 Overview

PorcupineRex is a high-level honeypot system designed to detect, analyse, and respond to malicious activity in real time.

The system simulates vulnerable environments, captures attacker behaviour, and provides insights that help improve defensive cybersecurity strategies.

A core design concept of the system is deception-based security: attackers are lured into a controlled environment while their actions are monitored and analysed.

---

## 🚀 Features

- ⚡ **Real-time command monitoring**  
  Track and analyse attacker commands as they happen  

- 🔒 **Isolated execution environment**  
  Safely run attacker interactions inside controlled virtual environments  

- 📊 **Comprehensive logging & alerts**  
  Detect suspicious activity and generate detailed logs  

- 🐳 **Docker-based deployment**  
  Quick and consistent setup using containers  

- 🔔 **Live alert system**  
  Get notified instantly when threats are detected  

- 🌐 **Web interface & monitoring system**  
  Interact with and monitor activity through a web-based dashboard  

---

## 🛠️ Installation

```bash
# clone repository
git clone https://github.com/CyberConductor/PorcupineRex.git

# enter directory
cd PorcupineRex

# make installer executable
chmod +x install.sh

# run installer (requires sudo/root)
sudo ./install.sh

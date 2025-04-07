# ESP8266 Temperature & Humidity Monitor 🌡️💧

An easy-to-deploy Dockerized IoT monitoring stack using **ESP8266**, **ESPHome**, **Mosquitto MQTT**, **Telegraf**, **InfluxDB**, and **Grafana**.

Monitor temperature, humidity, and other environmental metrics effortlessly.

---

## 🚀 Features:

- **Plug-and-play Docker Compose setup**
- **Interactive setup script** (`setup.sh`) for automatic configuration
- **Real-time environmental monitoring**
- **MQTT integration for easy IoT scalability**
- **Persistent data storage with optional USB/External drive mounting**

---

## 📸 Screenshots:

*(Coming Soon! Add screenshots of Grafana dashboards here.)*

---

## 🛠 Tech Stack:

- **ESP8266 (ESPHome)** – Data collection
- **Mosquitto (MQTT)** – Lightweight messaging
- **Telegraf** – Data ingestion
- **InfluxDB** – Time-series data storage
- **Grafana** – Beautiful visualizations

---

## 📁 Directory Structure:

```
esp8266-temp-humidity-monitor/
├── docker-compose.yml
├── setup.sh
│
├── esphome/
│   └── example-config.yaml
│
├── mosquitto/
│   ├── config/
│   │   └── mosquitto.conf
│   ├── data/
│   └── log/
│
├── influxdb/
│   ├── config/
│   └── data/
│
├── telegraf/
│   └── telegraf.conf
│
├── grafana/
│
└── docs/
    └── screenshots/
```

---

## 📦 Installation & Deployment:

### 1\. Clone this repository:

```bash
git clone https://github.com/PKHarsimran/esp8266-temp-humidity-monitor.git
cd esp8266-temp-humidity-monitor
```

### 2\. Make `setup.sh` executable and run it:

```bash
chmod +x setup.sh
./setup.sh
```

Follow the interactive prompts to configure your storage options.

### 3\. Access your applications:

- **ESPHome** → `http://localhost:6052`
- **Grafana** → `http://localhost:3000` (default: `admin/admin`)

---

## 🤝 Contributions:

Contributions, improvements, and suggestions are warmly welcomed! Open an issue or PR anytime.

---

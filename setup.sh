#!/bin/bash

# Function to display storage selection menu
choose_storage() {
  echo "Select InfluxDB data storage location:"
  echo "1) Use default (local ./influxdb/data)"
  echo "2) Use external USB/drive (mounted to ./influxdb/data)"

  read -rp "Enter choice [1 or 2]: " storage_choice

  influxdb_volume="$(pwd)/influxdb/data"
  mkdir -p "$influxdb_volume"

  if [ "$storage_choice" == "2" ]; then
    read -rp "Enter the device path (e.g., /dev/sda1): " device_path

    echo "Mounting $device_path to $influxdb_volume"
    sudo mount "$device_path" "$influxdb_volume"

    read -rp "Add to fstab for automatic mounting on boot? (y/n): " add_fstab
    if [ "$add_fstab" == "y" ] || [ "$add_fstab" == "Y" ]; then
      UUID=$(sudo blkid -s UUID -o value "$device_path")
      fstab_entry="UUID=$UUID $influxdb_volume ext4 defaults,nofail 0 2"
      if ! grep -Fxq "$fstab_entry" /etc/fstab; then
        echo "$fstab_entry" | sudo tee -a /etc/fstab
        echo "Entry added to /etc/fstab."
      else
        echo "Entry already exists in /etc/fstab."
      fi
    fi

    export DEVICE_PATH="$device_path"
    export USED_USB=true
  else
    export USED_USB=false
  fi
}

# Function to detect ESP USB device
detect_esp_device() {
  echo "\nScanning for connected USB devices (ESP)..."
  ESP_PATH=""
  if ls /dev/serial/by-id/* 1>/dev/null 2>&1; then
    echo "Available devices in /dev/serial/by-id/:"
    select dev in /dev/serial/by-id/* "Skip (run without USB access)"; do
      if [[ "$dev" == "Skip (run without USB access)" ]]; then
        ESP_PATH=""
        break
      elif [[ -n "$dev" ]]; then
        ESP_PATH="$dev"
        break
      fi
    done
  else
    echo "No devices found in /dev/serial/by-id/. Checking /dev/ttyUSB*..."
    USB_DEVS=(/dev/ttyUSB* /dev/ttyACM*)
    select dev in "${USB_DEVS[@]}" "Skip (run without USB access)"; do
      if [[ "$dev" == "Skip (run without USB access)" ]]; then
        ESP_PATH=""
        break
      elif [[ -e "$dev" ]]; then
        ESP_PATH="$dev"
        break
      fi
    done
  fi

  if [ -n "$ESP_PATH" ]; then
    echo "Detected ESP device at: $ESP_PATH"
  else
    echo "No ESP device selected. Proceeding without USB passthrough."
  fi
}

# Generate random secure InfluxDB token
TOKEN=$(openssl rand -base64 32)
echo "Generated InfluxDB Admin Token: $TOKEN"

# Run storage selection menu
choose_storage

# Detect ESP USB device
detect_esp_device

# Export necessary environment variable
export DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=$TOKEN

# Generate docker-compose.yml based on whether ESP was found
cat > docker-compose.yml <<EOF
version: '2.2'
services:
  esphome:
    container_name: esphome
    image: esphome/esphome-armv7
    volumes:
      - ./esphome:/config
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "6052:6052"
EOF

if [ -n "$ESP_PATH" ]; then
  echo "    devices:" >> docker-compose.yml
  echo "      - \"$ESP_PATH:/dev/ttyUSB0\"" >> docker-compose.yml
  echo "    privileged: true" >> docker-compose.yml
fi

cat >> docker-compose.yml <<EOF
    restart: unless-stopped

  mosquitto:
    container_name: mosquitto
    image: eclipse-mosquitto:2.0
    volumes:
      - ./mosquitto/config/mosquitto.conf:/mosquitto/config/mosquitto.conf
      - ./mosquitto/data:/mosquitto/data
      - ./mosquitto/log:/mosquitto/log
    ports:
      - "1883:1883"
      - "8083:8083"
    restart: unless-stopped

  influxdb:
    container_name: influxdb
    image: arm32v7/influxdb:1.8
    ports:
      - "8086:8086"
    volumes:
      - ./influxdb/data:/var/lib/influxdb
    environment:
      - INFLUXDB_DB=esphome_db
      - INFLUXDB_ADMIN_USER=admin
      - INFLUXDB_ADMIN_PASSWORD=your_secure_password
    restart: unless-stopped
EOF

# Launch Docker Compose
if docker-compose up -d; then
  echo "\n🎉 Setup Complete!"
  echo "\nYour Docker containers are up and running."
  echo "InfluxDB Admin Token: $TOKEN"
  echo "InfluxDB Data Location: $influxdb_volume"
else
  echo "\n❌ Docker Compose failed to start."
  if [ "$USED_USB" == true ]; then
    echo "Unmounting USB from $influxdb_volume..."
    sudo umount "$influxdb_volume"
    echo "✅ USB unmounted."
  fi
  exit 1
fi

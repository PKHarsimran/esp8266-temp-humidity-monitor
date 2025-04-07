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
      echo "UUID=$UUID $influxdb_volume ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
      echo "Entry added to /etc/fstab."
    fi
  fi
}

# Generate random secure InfluxDB token
TOKEN=$(openssl rand -base64 32)
echo "Generated InfluxDB Admin Token: $TOKEN"

# Run storage selection menu
choose_storage

# Export necessary environment variable
export DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=$TOKEN

# Launch Docker Compose
docker-compose up -d

# Final instructions
cat << EOF

🎉 Setup Complete!

Your Docker containers are up and running.

InfluxDB Admin Token: $TOKEN
InfluxDB Data Location: $influxdb_volume

EOF

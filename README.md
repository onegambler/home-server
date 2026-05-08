# home-server

A personal home automation and network infrastructure project featuring Home Assistant integration, DNS management, and automated downloads across multiple devices.

## Overview

This project manages a distributed home server setup with services running on Raspberry Pi and NUC (Next Unit of Computing) devices, including:
- Home automation via Home Assistant
- Custom DNS resolution and ad-blocking
- Automated content downloading

## Project Structure

```
home-server/
├── hass-nuc/              # Home Assistant setup and configuration (NUC)
├── dns-rpi/               # DNS server setup (Raspberry Pi)
└── downloader-nuc/        # Automated downloader service (NUC)
```

## Components

### Home Assistant (hass-nuc)
Home automation hub running on NUC device for controlling and monitoring smart home devices.

### DNS Server (dns-rpi)
DNS and ad-blocking service running on Raspberry Pi to provide network-wide DNS resolution and filtering.

### Downloader (downloader-nuc)
Automated download management service running on NUC for managing media downloads.

## Getting Started

Each component has its own configuration and setup. Navigate to the respective directories for detailed instructions:

- [`hass-nuc/`](./hass-nuc) - Home Assistant setup guide
- [`dns-rpi/`](./dns-rpi) - DNS server configuration
- [`downloader-nuc/`](./downloader-nuc) - Downloader service setup

## License

This project is provided as-is for personal use.

## Notes

- Created: October 2018
- Language: Shell scripts
- All services run on local network infrastructure

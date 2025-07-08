# 📡 rrd-multi-monitor

**Simple Bash script to monitor multiple targets (e.g. hosts or services) and write response data to an RRDtool time-series database.**

![rrdtool](https://img.shields.io/badge/rrdtool-supported-blue) ![bash](https://img.shields.io/badge/bash-✓-green)

---

## ✨ Features

- Monitor multiple hosts using `ping`
- Store response times in an efficient round-robin database (RRDtool)
- Generate graphs for:
  - Last 24 hours
  - Last 7 days
- Cron-compatible update loop
- Graph display via GUI viewer (`feh`, optional)
- Easily extendable for HTTP and other service checks

---

## 🛠️ Requirements

- `bash`
- `rrdtool`
- `cron` (for automated updates)
- Optional: `feh` (for viewing graphs)

Install dependencies (Debian/Ubuntu example):

```bash
sudo apt install rrdtool feh

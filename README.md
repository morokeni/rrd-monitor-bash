# 📡 rrd-monitor-bash

**Simple Bash script to monitor multiple targets (e.g. hosts or services) and write response data to an RRDtool time-series database.**

&#x20;

---

## ✨ Features

- Monitor multiple hosts using `ping`
- Store response times in a compact RRDtool database
- Generate graphs for:
  - Last 24 hours
  - Last 7 days
- Cron-compatible background updates
- Graph display via GUI viewer (`feh`, optional)
- Easy to extend for HTTP or other checks

---

## 👨‍🔬 Acknowledgment

This project uses [**RRDtool**](https://oss.oetiker.ch/rrdtool/) developed by **Tobias Oetiker**\
🔗 Official website: [https://oss.oetiker.ch/](https://oss.oetiker.ch/)

RRDtool is licensed under the **GNU General Public License v2.0 (GPL-2.0)**.

---

## 🛠️ Requirements

- `bash`
- `rrdtool`
- `cron` (for automatic background updates)
- Optional: `feh` for viewing the generated graphs

Install on Debian/Ubuntu:

```bash
sudo apt install rrdtool feh
```

---

## 📦 Getting Started

### 📁 Clone the repository

```bash
git clone https://github.com/morokeni/rrd-monitor-bash.git
cd rrd-monitor-bash
chmod +x ping_rrd_script_7days-TEMPLATE.sh
```

### ⚙️ Configure hosts

Open the script `ping_rrd_script_7days-TEMPLATE.sh` and edit the `HOSTS` array:

```bash
HOSTS=("google.com" "chatgpt.com" "20min.ch" "swisscom.ch")
```

Up to 8 hosts are supported. Each host will be assigned a different color in the graphs.

### 📂 Create RRD database

```bash
./ping_rrd_script_7days-TEMPLATE.sh --create-rrd-database
```

Initializes the `.rrd` file for storing time-series data.

### ↻ Update once (e.g. test)

```bash
./ping_rrd_script_7days-TEMPLATE.sh --update-rrd-cron
```

Performs a one-time ping to all configured targets and logs the results.

### 🕒 Setup background updates via cron

```bash
./ping_rrd_script_7days-TEMPLATE.sh --update-rrd-cron-setup
```

Installs a cronjob to update the RRD database every 30 seconds.

Check your cron jobs using:

```bash
crontab -l
```

---

## 📊 Generate graphs

```bash
./ping_rrd_script_7days-TEMPLATE.sh --create-graph
```

Creates two `.png` files showing response times:

- `*_ping_24h.png` – Last 24 hours
- `*_ping_7d.png` – Last 7 days

---

## 🖼️ Show graphs immediately (requires `feh`)

```bash
./ping_rrd_script_7days-TEMPLATE.sh --show-graph
```

Opens both graphs in a graphical image viewer (`feh` must be installed).

---

## 🧪 Example Output

TODO - Add a screenshot after generating your first graph:

```text
📷 [example_ping_24h.png]
```

---

## 🔮 Planned Features

- HTTP(S) response time monitoring
- Config file support (`targets.conf`)
- Plugin-style extensions for protocols (DNS, TCP, etc.)

---

Happy monitoring! 🌟

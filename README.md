# 🔍 Port Monitor

> 🚀 **Shell script for monitoring TCP/UDP ports and executing actions based on status**

## 📖 Description

This powerful script monitors specific ports defined in a configuration file and executes custom actions when a port becomes inactive (down) or active (up). Perfect for **service monitoring** and **recovery action automation** in production environments.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔌 **Multi-Port Support** | Monitor multiple TCP/UDP ports simultaneously |
| ⚡ **Custom Actions** | Execute specific actions per port status change |
| 📝 **Detailed Logging** | Comprehensive operation logging for troubleshooting |
| ⏱️ **Action Timeout** | Built-in timeout support for actions |
| 🐛 **Verbose Mode** | Debug mode for detailed monitoring |
| 🔧 **Tool Compatibility** | Works with different network utilities (ss, netstat) |
| 🎨 **Colored Output** | Beautiful colored terminal output |

---

## 📋 Requirements

Before using Port Monitor, ensure you have:

- 🐚 **Bash shell**
- 🌐 **Network utilities** (`ss` or `netstat`)
- ⏰ **Timeout command**

---

## 🚀 Installation

### Quick Setup

1. **Clone or download** the repository files
2. **Set execution permissions**:
   ```bash
   chmod +x port-monitor.sh
   ```

---

## ⚙️ Configuration Example

Create your configuration file with the following format:

```ini
# PORT:application:Action if Down:Action if Up
# ------------------------------------------------
80:apache:systemctl restart apache2:echo "apache is running"
443:nginx:systemctl restart nginx:echo "nginx is up and running"
3306:mysql:systemctl restart mysql:echo "mysql database is active"
```

### 📝 Configuration Format

```
PORT:application:Action_if_Down:Action_if_Up
```

**Where:**
- `PORT` - The port number to monitor
- `application` - Friendly name for the service
- `Action_if_Down` - Command to execute when port is inactive
- `Action_if_Up` - Command to execute when port becomes active

---

## 🎯 Usage Examples

```bash
# Basic monitoring
./port-monitor.sh

# Verbose mode for debugging
./port-monitor.sh -v

# Monitor with custom config file
./port-monitor.sh -c /path/to/custom/config
```

---

## 📊 Sample Output

```
🔍 Port Monitor Starting...
✅ Port 80 (apache) - ACTIVE
❌ Port 443 (nginx) - DOWN - Executing recovery action...
🔄 Restarting nginx service...
✅ Port 443 (nginx) - RECOVERED
```

---

## ⚠️ Important Notice

> **📢 Contribution Policy**
> 
> We don't accept contributions from anyone. If you need this tool, you can use it and be happy! You're free to modify and use it as you like, but **please don't send pull requests** to this repository.
> 
> Thank you for understanding! 🙏

---

## 📜 License

This project is provided as-is for personal and commercial use. Modify freely but respect our no-contribution policy.

---

<div align="center">

**Made with ❤️ for system administrators and DevOps engineers**

*Keep your services running smoothly! 🚀*

</div>
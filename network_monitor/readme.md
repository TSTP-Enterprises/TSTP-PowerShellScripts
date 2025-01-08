# Network Monitor Tool 🌐

A powerful, real-time network monitoring tool built with PowerShell that provides comprehensive network statistics, performance metrics, and diagnostic information through an intuitive GUI interface.

## 🚀 Features

- **Real-Time Network Statistics**
  - Current network speed monitoring with MB/s tracking
  - Total bandwidth usage measurement
  - Active connection monitoring with process details
  - Network spike detection with configurable thresholds
  - Automatic spike duration tracking

- **Latency Monitoring**
  - Real-time ping statistics to Google DNS (8.8.8.8)
  - Packet loss tracking with percentage calculation
  - Latency spike detection (>100ms threshold)
  - Min/Avg/Max ping measurements with continuous updates

- **Network Configuration**
  - Local IP address monitoring with change detection
  - Gateway information and status
  - DNS server details and monitoring
  - WAN IP tracking through external service
  - Interface status monitoring with real-time updates

- **Process Monitoring**
  - Track network usage by process with PID tracking
  - Monitor established TCP connections
  - Process history logging with timestamps
  - Remote address and port tracking

- **Detailed Reporting**
  - Comprehensive session reports in text format
  - Network event logging with timestamps
  - CSV export for network spikes
  - JSON export for process history
  - Automatic report generation on monitoring stop

## 📋 Requirements

- Windows 10 or later
- PowerShell 5.1 or later
- Administrator privileges
- .NET Framework 4.7.2 or later

## 🔧 Installation

1. Clone the repository:
   ```powershell
   git clone https://github.com/TSTP-Enterprises/network-monitor.git
   cd network-monitor
   ```

2. Run the script with administrator privileges:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\network_monitor.ps1
   ```

## 💡 Usage

1. Launch the Network Monitor tool with administrator privileges
2. Click "Start Monitoring" to begin tracking
3. Monitor real-time statistics in the GUI:
   - Watch network speed and bandwidth usage
   - Track active connections and processes
   - Monitor ping statistics and packet loss
   - Observe network spikes and changes
4. Click "Stop Monitoring" to:
   - End the monitoring session
   - Generate comprehensive reports
   - Export all collected data
5. Review exported data in your user profile directory:
   - `NetworkMonitor_[timestamp]_report.txt`
   - `NetworkMonitor_[timestamp]_spikes.csv`
   - `NetworkMonitor_[timestamp]_ping.txt`
   - `NetworkMonitor_[timestamp]_processes.json`
   - `NetworkMonitor_[timestamp]_events.txt`

## 🛠️ Customization

Key configurable parameters in the script:
- Network spike threshold: 10 MB/s default
- Ping threshold: 100ms default
- Ping target: 8.8.8.8 (Google DNS) default
- Update interval: 1 second default

## 🤝 Contributing

Contributions are welcome! Please follow these steps:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 💖 Support the Project

This tool is provided free of charge as part of our commitment to creating accessible solutions for everyone. If you find it valuable, consider supporting its development:

### One-Time Donations
- [PayPal](https://www.paypal.com/donate/?hosted_button_id=RAAYNUTMHPQQN)
- [Buy Me a Coffee](https://buymeacoffee.com/thesolutionstoproblems)
- [Ko-fi](https://ko-fi.com/thesolutionstoproblems)

### Monthly Sponsorship
- [GitHub Sponsors](https://github.com/sponsors/TSTP-Enterprises)
- [Patreon](http://patreon.com/theSolutionsToProblems)

## 🌐 Connect With Us

- [Website](https://www.tstp.xyz)
- [YouTube](https://www.youtube.com/@yourpststudios/)
- [GitHub](https://github.com/TSTP-Enterprises)
- [LinkedIn](https://www.linkedin.com/company/thesolutions-toproblems)
- Email: David@TSTP.xyz

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔒 Privacy Notice

This tool:
- Does not collect or transmit any personal data
- Only monitors local network statistics
- Stores all data locally in your user profile
- Uses external services only for WAN IP detection

---

Made with ❤️ by [TSTP Enterprises](https://www.tstp.xyz)
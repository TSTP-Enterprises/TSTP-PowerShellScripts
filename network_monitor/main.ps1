Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

function Get-NetworkInfo {
    try {
        # Get network adapter info
        $NetworkInfo = Get-NetIPConfiguration | Where-Object {$null -ne $_.IPv4DefaultGateway}
        
        # Get WAN IP with timeout and error handling
        $WanIP = "Unknown"
        try {
            $WanRequest = Invoke-WebRequest -Uri "http://ifconfig.me/ip" -UseBasicParsing -TimeoutSec 5
            if ($WanRequest.StatusCode -eq 200) {
                $WanIP = $WanRequest.Content.Trim()
            }
        }
        catch {
            Write-Warning "Could not retrieve WAN IP: $_"
        }

        # Build network info with null checks
        $NetworkData = @{
            LocalIP = if ($null -ne $NetworkInfo.IPv4Address) { $NetworkInfo.IPv4Address.IPAddress } else { "Not found" }
            Gateway = if ($null -ne $NetworkInfo.IPv4DefaultGateway) { $NetworkInfo.IPv4DefaultGateway.NextHop } else { "Not found" }
            DNS = if ($null -ne $NetworkInfo.DNSServer) { 
                ($NetworkInfo.DNSServer | Where-Object {$_.AddressFamily -eq 2}).ServerAddresses -join ", " 
            } else { "Not found" }
            Subnet = if ($null -ne $NetworkInfo.IPv4Address) { $NetworkInfo.IPv4Address.PrefixLength } else { "Not found" }
            WanIP = $WanIP
            Interfaces = @(Get-NetAdapter | Select-Object Name, InterfaceDescription, Status)
        }

        return $NetworkData
    }
    catch {
        Write-Error "Failed to get network information: $_"
        return $null
    }
}

function Get-NetworkProcessInfo {
    Get-NetTCPConnection -State Established | 
    ForEach-Object {
        $Process = Get-Process -Id $_.OwningProcess
        [PSCustomObject]@{
            ProcessName = $Process.Name
            ProcessId = $Process.Id
            LocalAddress = $_.LocalAddress 
            LocalPort = $_.LocalPort
            RemoteAddress = $_.RemoteAddress
            RemotePort = $_.RemotePort
            State = $_.State
        }
    }
}

function Show-NetworkMonitor {
    # Create window
    $Window = New-Object System.Windows.Window
    $Window.Title = "Network Monitor"
    $Window.Width = 1000 
    $Window.Height = 800
    $Window.WindowStartupLocation = 'CenterScreen'
    $Window.SizeToContent = 'Manual'

    # Create a Grid
    $Grid = New-Object System.Windows.Controls.Grid
    $Window.Content = $Grid
    
    # Define grid rows
    0..4 | ForEach-Object {
        $Grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
    }
    $Grid.RowDefinitions[0].Height = 'Auto' # Buttons
    $Grid.RowDefinitions[1].Height = 'Auto' # Network Info
    $Grid.RowDefinitions[2].Height = 'Auto' # Network Stats
    $Grid.RowDefinitions[3].Height = 'Auto' # Ping Stats  
    $Grid.RowDefinitions[4].Height = '*'    # Events List
    
    $Grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))
    $Grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))

    # Controls in Row 0: Start/Stop Buttons
    $StartButton = New-Object System.Windows.Controls.Button
    $StartButton.Content = "Start Monitoring"
    $StartButton.Margin = "10"
    [System.Windows.Controls.Grid]::SetRow($StartButton, 0)
    [System.Windows.Controls.Grid]::SetColumn($StartButton, 0)
    $Grid.Children.Add($StartButton)

    $StopButton = New-Object System.Windows.Controls.Button
    $StopButton.Content = "Stop Monitoring"
    $StopButton.Margin = "10"
    $StopButton.IsEnabled = $false
    [System.Windows.Controls.Grid]::SetRow($StopButton, 0)
    [System.Windows.Controls.Grid]::SetColumn($StopButton, 1)
    $Grid.Children.Add($StopButton)

    # Threshold settings
    $ThresholdMB = 10
    $PingThresholdMs = 100
    $PingTarget = "8.8.8.8" # Google DNS

    # Controls in Row 1: Network Info
    $NetworkInfoPanel = New-Object System.Windows.Controls.StackPanel
    $NetworkInfoPanel.Orientation = "Vertical"
    $NetworkInfoPanel.Margin = "10"
    [System.Windows.Controls.Grid]::SetRow($NetworkInfoPanel, 1)
    [System.Windows.Controls.Grid]::SetColumnSpan($NetworkInfoPanel, 2)
    $Grid.Children.Add($NetworkInfoPanel)

    $LabelNetworkInfo = New-Object System.Windows.Controls.Label
    $LabelNetworkInfo.Content = "Network Information Loading..."
    $NetworkInfoPanel.Children.Add($LabelNetworkInfo)

    # Controls in Row 2: Network Stats
    $NetworkStatsPanel = New-Object System.Windows.Controls.StackPanel
    $NetworkStatsPanel.Orientation = "Vertical"
    $NetworkStatsPanel.Margin = "10"
    [System.Windows.Controls.Grid]::SetRow($NetworkStatsPanel, 2)
    [System.Windows.Controls.Grid]::SetColumnSpan($NetworkStatsPanel, 2)
    $Grid.Children.Add($NetworkStatsPanel)

    $LabelCurrentSpeed = New-Object System.Windows.Controls.Label
    $LabelCurrentSpeed.Content = "Current Speed: 0 MB/s"
    $NetworkStatsPanel.Children.Add($LabelCurrentSpeed)

    $LabelSpikeCount = New-Object System.Windows.Controls.Label
    $LabelSpikeCount.Content = "Network Spikes: 0"
    $NetworkStatsPanel.Children.Add($LabelSpikeCount)

    $LabelActiveConnections = New-Object System.Windows.Controls.Label
    $LabelActiveConnections.Content = "Active Connections: 0"
    $NetworkStatsPanel.Children.Add($LabelActiveConnections)

    $LabelBandwidthUsage = New-Object System.Windows.Controls.Label
    $LabelBandwidthUsage.Content = "Total Bandwidth Usage: 0 MB"
    $NetworkStatsPanel.Children.Add($LabelBandwidthUsage)

    # Controls in Row 3: Ping Stats
    $PingStatsPanel = New-Object System.Windows.Controls.StackPanel
    $PingStatsPanel.Orientation = "Vertical"
    $PingStatsPanel.Margin = "10"
    [System.Windows.Controls.Grid]::SetRow($PingStatsPanel, 3)
    [System.Windows.Controls.Grid]::SetColumnSpan($PingStatsPanel, 2)
    $Grid.Children.Add($PingStatsPanel)

    $LabelCurrentPing = New-Object System.Windows.Controls.Label
    $LabelCurrentPing.Content = "Current Ping: -- ms"
    $PingStatsPanel.Children.Add($LabelCurrentPing)

    $LabelPingStats = New-Object System.Windows.Controls.Label
    $LabelPingStats.Content = "Ping Stats (Min/Avg/Max): --/--/-- ms"
    $PingStatsPanel.Children.Add($LabelPingStats)

    $LabelPingSpikes = New-Object System.Windows.Controls.Label
    $LabelPingSpikes.Content = "Ping Spikes: 0"
    $PingStatsPanel.Children.Add($LabelPingSpikes)

    $LabelPacketLoss = New-Object System.Windows.Controls.Label
    $LabelPacketLoss.Content = "Packet Loss: 0%"
    $PingStatsPanel.Children.Add($LabelPacketLoss)

    # Controls in Row 4: List of Events
    $ListBoxEvents = New-Object System.Windows.Controls.ListBox
    $ListBoxEvents.Margin = "10"
    [System.Windows.Controls.Grid]::SetRow($ListBoxEvents, 4)
    [System.Windows.Controls.Grid]::SetColumnSpan($ListBoxEvents, 2)
    $Grid.Children.Add($ListBoxEvents)

    # Monitoring variables
    $script:MonitoringData = @{
        IsMonitoring = $false
        StartTime = $null
        SpikeCount = 0
        PingSpikeCount = 0
        InSpike = $false
        SpikeStartTime = $null
        Spikes = New-Object System.Collections.Generic.List[PSObject]
        PingHistory = New-Object System.Collections.Generic.List[double]
        PacketsSent = 0
        PacketsLost = 0
        TotalBandwidth = 0
        ProcessHistory = @{}
        NetworkChanges = New-Object System.Collections.Generic.List[PSObject]
        InitialNetworkState = $null
        LastNetworkChangeMessages = @{}
    }

    # DispatcherTimer for real-time updates
    $Timer = New-Object System.Windows.Threading.DispatcherTimer
    $Timer.Interval = [TimeSpan]::FromSeconds(1)
    $Timer.Add_Tick({
        try {
            # Network Speed Monitoring
            $Stats = Get-Counter "\Network Interface(*)\Bytes Total/sec" -ErrorAction Stop
            $CurrentSpeedMB = ($Stats.CounterSamples | Measure-Object CookedValue -Sum).Sum / 1MB
            $script:MonitoringData.TotalBandwidth += $CurrentSpeedMB
            
            $LabelCurrentSpeed.Content = "Current Speed: $([math]::Round($CurrentSpeedMB,2)) MB/s"
            $LabelBandwidthUsage.Content = "Total Bandwidth Usage: $([math]::Round($script:MonitoringData.TotalBandwidth,2)) MB"

            # Process Network Usage
            $ProcessInfo = Get-NetworkProcessInfo
            foreach($proc in $ProcessInfo) {
                if(!$script:MonitoringData.ProcessHistory.ContainsKey($proc.ProcessId)) {
                    $script:MonitoringData.ProcessHistory[$proc.ProcessId] = @{
                        FirstSeen = Get-Date
                        Name = $proc.ProcessName
                        Connections = New-Object System.Collections.Generic.List[PSObject]
                    }
                }
                $script:MonitoringData.ProcessHistory[$proc.ProcessId].Connections.Add(@{
                    Time = Get-Date
                    RemoteAddress = $proc.RemoteAddress
                    RemotePort = $proc.RemotePort
                })
            }

            # Active Connections
            $ActiveConns = $ProcessInfo.Count
            $LabelActiveConnections.Content = "Active Connections: $ActiveConns"

            # Ping Test
            $Ping = Test-Connection $PingTarget -Count 1 -ErrorAction SilentlyContinue
            if ($Ping) {
                $CurrentPing = $Ping.ResponseTime
                $script:MonitoringData.PacketsSent++
                $script:MonitoringData.PingHistory.Add($CurrentPing)
                
                # Update ping statistics
                $PingStats = $script:MonitoringData.PingHistory | Measure-Object -Minimum -Maximum -Average
                $LabelCurrentPing.Content = "Current Ping: ${CurrentPing}ms"
                $LabelPingStats.Content = "Ping Stats (Min/Avg/Max): $($PingStats.Minimum)/$([math]::Round($PingStats.Average,2))/$($PingStats.Maximum) ms"
                
                if ($CurrentPing -gt $PingThresholdMs) {
                    $script:MonitoringData.PingSpikeCount++
                    $LabelPingSpikes.Content = "Ping Spikes: $($script:MonitoringData.PingSpikeCount)"
                    $ListBoxEvents.Items.Add("$(Get-Date -Format 'G'): High latency detected - ${CurrentPing}ms")
                }
            }
            else {
                $script:MonitoringData.PacketsSent++
                $script:MonitoringData.PacketsLost++
                $LabelCurrentPing.Content = "Current Ping: Timeout"
                $ListBoxEvents.Items.Add("$(Get-Date -Format 'G'): Ping timeout")
            }

            # Update packet loss
            if ($script:MonitoringData.PacketsSent -gt 0) {
                $PacketLossPercent = ($script:MonitoringData.PacketsLost / $script:MonitoringData.PacketsSent) * 100
                $LabelPacketLoss.Content = "Packet Loss: $([math]::Round($PacketLossPercent,2))%"
            }

            # Network Spike Detection
            if ($CurrentSpeedMB -gt $ThresholdMB) {
                if (-not $script:MonitoringData.InSpike) {
                    $script:MonitoringData.InSpike = $true
                    $script:MonitoringData.SpikeStartTime = Get-Date
                    $ListBoxEvents.Items.Add("$(Get-Date -Format 'G'): Network spike started - $([math]::Round($CurrentSpeedMB,2))MB/s")
                }
            }
            elseif ($script:MonitoringData.InSpike) {
                $script:MonitoringData.InSpike = $false
                $script:MonitoringData.SpikeCount++
                $SpikeEndTime = Get-Date
                $SpikeDuration = $SpikeEndTime - $script:MonitoringData.SpikeStartTime

                $SpikeObj = [PSCustomObject]@{
                    StartTime = $script:MonitoringData.SpikeStartTime
                    EndTime = $SpikeEndTime
                    Duration = $SpikeDuration
                    MaxSpeed = $CurrentSpeedMB
                }
                $script:MonitoringData.Spikes.Add($SpikeObj)

                $LabelSpikeCount.Content = "Network Spikes: $($script:MonitoringData.SpikeCount)"
                $ListBoxEvents.Items.Add("$(Get-Date -Format 'G'): Network spike ended - Duration: $($SpikeDuration.ToString('hh\:mm\:ss'))")
            }

            # Check for network changes
            $CurrentNetworkState = Get-NetworkInfo
            if ($null -eq $script:MonitoringData.InitialNetworkState) {
                $script:MonitoringData.InitialNetworkState = $CurrentNetworkState
                $LabelNetworkInfo.Content = "Local IP: $($CurrentNetworkState.LocalIP) | Gateway: $($CurrentNetworkState.Gateway) | WAN IP: $($CurrentNetworkState.WanIP)"
            }
            else {
                foreach ($key in $CurrentNetworkState.Keys) {
                    $currentValue = $CurrentNetworkState[$key]
                    $initialValue = $script:MonitoringData.InitialNetworkState[$key]
                    
                    if ($currentValue -ne $initialValue) {
                        $changeMessage = "Network change detected - $key changed to $currentValue"
                        
                        # Only add the message if it's different from the last one for this key
                        if (-not $script:MonitoringData.LastNetworkChangeMessages.ContainsKey($key) -or 
                            $script:MonitoringData.LastNetworkChangeMessages[$key] -ne $changeMessage) {
                            
                            $script:MonitoringData.NetworkChanges.Add([PSCustomObject]@{
                                Time = Get-Date
                                Property = $key
                                OldValue = $initialValue
                                NewValue = $currentValue
                            })
                            
                            $script:MonitoringData.LastNetworkChangeMessages[$key] = $changeMessage
                            $ListBoxEvents.Items.Add("$(Get-Date -Format 'G'): $changeMessage")
                        }
                        
                        $script:MonitoringData.InitialNetworkState[$key] = $currentValue
                    }
                }
            }

            # Auto-scroll events list
            $ListBoxEvents.ScrollIntoView($ListBoxEvents.Items[$ListBoxEvents.Items.Count-1])
        }
        catch {
            Write-Warning "Error during monitoring: $_"
            $Timer.Stop()
            $StartButton.IsEnabled = $true
            $StopButton.IsEnabled = $false
            $ListBoxEvents.Items.Add("$(Get-Date -Format 'G'): Error - $_")
        }
    })

    # Start Monitoring
    $StartButton.Add_Click({
        $script:MonitoringData.IsMonitoring = $true
        $script:MonitoringData.StartTime = Get-Date
        $StartButton.IsEnabled = $false
        $StopButton.IsEnabled = $true

        # Reset monitoring data
        $script:MonitoringData.SpikeCount = 0
        $script:MonitoringData.PingSpikeCount = 0
        $script:MonitoringData.InSpike = $false
        $script:MonitoringData.PacketsSent = 0
        $script:MonitoringData.PacketsLost = 0
        $script:MonitoringData.TotalBandwidth = 0
        $script:MonitoringData.Spikes.Clear()
        $script:MonitoringData.PingHistory.Clear()
        $script:MonitoringData.ProcessHistory.Clear()
        $script:MonitoringData.NetworkChanges.Clear()
        $script:MonitoringData.InitialNetworkState = $null
        $script:MonitoringData.LastNetworkChangeMessages.Clear()
        $ListBoxEvents.Items.Clear()

        # Reset labels
        $LabelSpikeCount.Content = "Network Spikes: 0"
        $LabelCurrentSpeed.Content = "Current Speed: 0 MB/s"
        $LabelCurrentPing.Content = "Current Ping: -- ms"
        $LabelPingSpikes.Content = "Ping Spikes: 0"
        $LabelPacketLoss.Content = "Packet Loss: 0%"
        $LabelActiveConnections.Content = "Active Connections: 0"
        $LabelBandwidthUsage.Content = "Total Bandwidth Usage: 0 MB"
        $LabelPingStats.Content = "Ping Stats (Min/Avg/Max): --/--/-- ms"

        $Timer.Start()
        $ListBoxEvents.Items.Add("$(Get-Date -Format 'G'): Monitoring started")
    })

    # Stop Monitoring
    $StopButton.Add_Click({
        $script:MonitoringData.IsMonitoring = $false
        $EndTime = Get-Date
        $StartButton.IsEnabled = $true
        $StopButton.IsEnabled = $false
        
        $Timer.Stop()

        # Handle in-progress spike
        if ($script:MonitoringData.InSpike) {
            $script:MonitoringData.SpikeCount++
            $SpikeEndTime = Get-Date
            $SpikeDuration = $SpikeEndTime - $script:MonitoringData.SpikeStartTime
            
            $SpikeObj = [PSCustomObject]@{
                StartTime = $script:MonitoringData.SpikeStartTime
                EndTime = $SpikeEndTime
                Duration = $SpikeDuration
            }
            $script:MonitoringData.Spikes.Add($SpikeObj)
            
            $ListBoxEvents.Items.Add("$(Get-Date -Format 'G'): Network spike ended on stop")
            $LabelSpikeCount.Content = "Network Spikes: $($script:MonitoringData.SpikeCount)"
            $script:MonitoringData.InSpike = $false
        }

        # Generate report
        $ReportBuilder = New-Object System.Text.StringBuilder
        $ReportBuilder.AppendLine("Network Monitoring Report") | Out-Null
        $ReportBuilder.AppendLine("======================") | Out-Null
        $ReportBuilder.AppendLine("") | Out-Null
        $ReportBuilder.AppendLine("Monitoring Period") | Out-Null
        $ReportBuilder.AppendLine("----------------") | Out-Null
        $ReportBuilder.AppendLine("Start Time: $($script:MonitoringData.StartTime)") | Out-Null
        $ReportBuilder.AppendLine("End Time: $EndTime") | Out-Null
        $ReportBuilder.AppendLine("Duration: $(($EndTime - $script:MonitoringData.StartTime).ToString())") | Out-Null
        $ReportBuilder.AppendLine("") | Out-Null

        $ReportBuilder.AppendLine("Network Configuration") | Out-Null
        $ReportBuilder.AppendLine("--------------------") | Out-Null
        $NetworkInfo = $script:MonitoringData.InitialNetworkState
        $ReportBuilder.AppendLine("Local IP: $($NetworkInfo.LocalIP)") | Out-Null
        $ReportBuilder.AppendLine("Gateway: $($NetworkInfo.Gateway)") | Out-Null
        $ReportBuilder.AppendLine("DNS Servers: $($NetworkInfo.DNS)") | Out-Null
        $ReportBuilder.AppendLine("Subnet Mask: /$($NetworkInfo.Subnet)") | Out-Null
        $ReportBuilder.AppendLine("WAN IP: $($NetworkInfo.WanIP)") | Out-Null
        $ReportBuilder.AppendLine("") | Out-Null

        $ReportBuilder.AppendLine("Network Interfaces") | Out-Null
        $ReportBuilder.AppendLine("-----------------") | Out-Null
        foreach ($interface in $NetworkInfo.Interfaces) {
            $ReportBuilder.AppendLine("$($interface.Name): $($interface.InterfaceDescription) - $($interface.Status)") | Out-Null
        }
        $ReportBuilder.AppendLine("") | Out-Null

        $ReportBuilder.AppendLine("Performance Statistics") | Out-Null
        $ReportBuilder.AppendLine("----------------------") | Out-Null
        if ($script:MonitoringData.PingHistory.Count -gt 0) {
            $PingStats = $script:MonitoringData.PingHistory | Measure-Object -Minimum -Maximum -Average
            $ReportBuilder.AppendLine("Ping Statistics:") | Out-Null
            $ReportBuilder.AppendLine("  Minimum: $($PingStats.Minimum) ms") | Out-Null
            $ReportBuilder.AppendLine("  Average: $([math]::Round($PingStats.Average,2)) ms") | Out-Null
            $ReportBuilder.AppendLine("  Maximum: $($PingStats.Maximum) ms") | Out-Null
        }
        $PacketLossPercent = if ($script:MonitoringData.PacketsSent -gt 0) {
            [math]::Round(($script:MonitoringData.PacketsLost / $script:MonitoringData.PacketsSent) * 100, 2)
        } else { 0 }
        $ReportBuilder.AppendLine("Packets Sent: $($script:MonitoringData.PacketsSent)") | Out-Null
        $ReportBuilder.AppendLine("Packets Lost: $($script:MonitoringData.PacketsLost) ($PacketLossPercent%)") | Out-Null
        $ReportBuilder.AppendLine("Total Bandwidth Usage: $([math]::Round($script:MonitoringData.TotalBandwidth,2)) MB") | Out-Null
        $ReportBuilder.AppendLine("") | Out-Null

        $ReportBuilder.AppendLine("Network Events") | Out-Null
        $ReportBuilder.AppendLine("--------------") | Out-Null
        $ReportBuilder.AppendLine("Network Spikes: $($script:MonitoringData.SpikeCount)") | Out-Null
        $ReportBuilder.AppendLine("Ping Spikes: $($script:MonitoringData.PingSpikeCount)") | Out-Null
        if ($script:MonitoringData.Spikes.Count -gt 0) {
            $ReportBuilder.AppendLine("") | Out-Null
            $ReportBuilder.AppendLine("Spike Details:") | Out-Null
            foreach ($spike in $script:MonitoringData.Spikes) {
                $ReportBuilder.AppendLine("  Start: $($spike.StartTime)") | Out-Null
                $ReportBuilder.AppendLine("  End: $($spike.EndTime)") | Out-Null
                $ReportBuilder.AppendLine("  Duration: $($spike.Duration.ToString())") | Out-Null
                $ReportBuilder.AppendLine("  Max Speed: $([math]::Round($spike.MaxSpeed,2)) MB/s") | Out-Null
                $ReportBuilder.AppendLine("") | Out-Null
            }
        }

        $ReportBuilder.AppendLine("Network Changes") | Out-Null
        $ReportBuilder.AppendLine("---------------") | Out-Null
        foreach ($change in $script:MonitoringData.NetworkChanges) {
            $ReportBuilder.AppendLine("$($change.Time): $($change.Property) changed from '$($change.OldValue)' to '$($change.NewValue)'") | Out-Null
        }
        $ReportBuilder.AppendLine("") | Out-Null

        $ReportBuilder.AppendLine("Process Network Activity") | Out-Null
        $ReportBuilder.AppendLine("-----------------------") | Out-Null
        
        # Convert ProcessHistory to a format that can be serialized
        $ProcessHistoryExport = @{}
        foreach ($proc in $script:MonitoringData.ProcessHistory.GetEnumerator()) {
            $ProcessHistoryExport[$proc.Key.ToString()] = @{
                FirstSeen = $proc.Value.FirstSeen
                Name = $proc.Value.Name
                Connections = $proc.Value.Connections | ForEach-Object { 
                    @{
                        Time = $_.Time
                        RemoteAddress = $_.RemoteAddress
                        RemotePort = $_.RemotePort
                    }
                }
            }
            
            $ReportBuilder.AppendLine("Process: $($proc.Value.Name) (PID: $($proc.Key))") | Out-Null
            $ReportBuilder.AppendLine("  First Seen: $($proc.Value.FirstSeen)") | Out-Null
            $ReportBuilder.AppendLine("  Total Connections: $($proc.Value.Connections.Count)") | Out-Null
            $ReportBuilder.AppendLine("") | Out-Null
        }

        # Export data
        try {
            $ExportPath = Join-Path $env:USERPROFILE "NetworkMonitor_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            
            # Export report
            $ReportBuilder.ToString() | Out-File "$ExportPath`_report.txt"
            
            # Export raw data
            $script:MonitoringData.Spikes | Export-Csv -Path "$ExportPath`_spikes.csv" -NoTypeInformation
            $script:MonitoringData.PingHistory | Out-File "$ExportPath`_ping.txt"
            $ProcessHistoryExport | ConvertTo-Json -Depth 10 | Out-File "$ExportPath`_processes.json"
            $ListBoxEvents.Items | Out-File "$ExportPath`_events.txt"
            
            [System.Windows.MessageBox]::Show("Monitoring data and report exported to: $ExportPath", "Export Complete")
        }
        catch {
            [System.Windows.MessageBox]::Show("Failed to export data: $_", "Export Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    })

    # Handle window closing
    $Window.Add_Closing({
        if ($Timer.IsEnabled) {
            $Timer.Stop()
        }
    })

    # Show the window
    $Window.ShowDialog() | Out-Null
}

# Run the Network Monitor UI
Show-NetworkMonitor

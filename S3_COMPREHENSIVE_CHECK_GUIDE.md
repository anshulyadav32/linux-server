# S3.sh - System Comprehensive Check Script

## Overview
The `s3.sh` (System Comprehensive Check) script is a master health monitoring tool that orchestrates all individual module health checks in the Linux Setup system. It provides a unified interface to monitor the entire server infrastructure from a single command.

## Purpose
- **Centralized Monitoring**: Single entry point for all system health checks
- **Comprehensive Coverage**: Checks all modules (database, DNS, webserver, firewall, SSL, extra services, backup)
- **Flexible Operation**: Multiple modes for different use cases (verbose, quiet, fast, summary)
- **Automated Reporting**: Detailed logging and status reporting
- **Operational Intelligence**: System overview and performance metrics

## Key Features

### 🔍 **Comprehensive Module Checking**
- Automatically discovers and runs all module check scripts
- Dependency-aware module ordering
- Individual module status tracking
- Failed/warning/passed categorization

### 🎛️ **Multiple Operation Modes**
- **Normal Mode**: Standard output with full details
- **Verbose Mode**: Enhanced output with detailed diagnostics
- **Quiet Mode**: Minimal output, errors only
- **Fast Mode**: Quick checks, skip detailed analysis  
- **Summary Mode**: Results summary only, no live output

### 📊 **System Intelligence**
- System information display (OS, kernel, uptime, load, memory, disk)
- Module availability verification
- Performance timing for each module check
- Resource usage monitoring

### 📝 **Advanced Logging**
- Automatic log file generation (`/tmp/s3_check_YYYYMMDD.log`)
- Colored output with status indicators
- Custom log file support
- Comprehensive execution tracking

### ⚙️ **Flexible Configuration**
- Module selection (check specific modules only)
- Custom log file locations
- Color output control
- Interrupt handling with cleanup

## Usage Examples

### Basic Operations
```bash
# Check all modules with standard output
sudo ./s3.sh

# Check all modules with verbose details
sudo ./s3.sh --verbose

# Quick check with summary only
sudo ./s3.sh --fast --summary

# Quiet mode for automation
sudo ./s3.sh --quiet
```

### Module-Specific Checks
```bash
# Check only database and webserver
sudo ./s3.sh database webserver

# Check SSL certificates specifically
sudo ./s3.sh ssl --verbose

# Quick firewall and DNS check
sudo ./s3.sh firewall dns --fast
```

### Automation & Logging
```bash
# Custom log file
sudo ./s3.sh --log-file /var/log/system_health.log

# Scheduled automated check
sudo ./s3.sh --quiet >> /var/log/daily_health.log 2>&1

# No color output for scripts
sudo ./s3.sh --no-color --summary
```

## Output Format

### System Information Section
```
================================
 System Information
================================

[INFO] Operating System: Ubuntu 22.04.3 LTS
[INFO] Kernel Version: 5.15.0-88-generic
[INFO] System Uptime: up 2 days, 14 hours, 32 minutes
[INFO] Load Average: 0.25, 0.15, 0.10
[INFO] Memory Usage: Used: 2.1G/8.0G (26%)
[INFO] Root Disk Usage: Used: 45G/100G (47%)
```

### Module Check Results
```
================================
 Checking database Module
================================

[SUCCESS] Database module check: PASSED (12s)

================================
 Checking webserver Module  
================================

[SUCCESS] Webserver module check: PASSED (8s)
```

### Summary Report
```
================================
 System Health Check Summary
================================

[INFO] Check started: 2025-09-11 14:30:15
[INFO] Check completed: 2025-09-11 14:32:47
[INFO] Total duration: 152s

[INFO] Modules checked: 7
[SUCCESS] Modules passed: 6
[WARNING] Modules with warnings: 1
  - ssl

[SUCCESS] OVERALL STATUS: PASSED WITH WARNINGS
```

## Integration with Module Scripts

### Script Discovery
The s3.sh script automatically discovers module check scripts using this pattern:
```bash
modules/$module/check_$module.sh
```

### Execution Flow
1. **Pre-check**: Verify script exists and is executable
2. **Execution**: Run module check script with appropriate arguments
3. **Result Processing**: Capture exit code and timing
4. **Status Tracking**: Categorize results (passed/failed/warning)
5. **Reporting**: Log results and update counters

### Exit Code Handling
- **0**: Module check passed successfully
- **1**: Module check failed critically  
- **Other**: Module check completed with warnings

## Automation & Scheduling

### Cron Job Examples
```bash
# Daily health check at 6:00 AM
0 6 * * * /path/to/linux-setup/s3.sh --quiet >> /var/log/server_health.log 2>&1

# Weekly detailed check on Sunday at 2:00 AM  
0 2 * * 0 /path/to/linux-setup/s3.sh --verbose >> /var/log/weekly_health.log 2>&1

# Hourly quick check during business hours
0 9-17 * * 1-5 /path/to/linux-setup/s3.sh --fast --summary >> /var/log/business_health.log 2>&1
```

### Monitoring Integration
```bash
# Nagios/Icinga integration
define command{
    command_name    check_linux_setup
    command_line    /path/to/linux-setup/s3.sh --quiet
}

# Prometheus monitoring
*/5 * * * * /path/to/linux-setup/s3.sh --summary --no-color | grep "OVERALL STATUS" > /var/lib/prometheus/linux_setup_status.prom
```

## Error Handling & Recovery

### Robust Error Management
- **Script Missing**: Graceful handling of missing module scripts
- **Permission Issues**: Clear error messages for privilege problems
- **Execution Failures**: Proper exit code propagation
- **Interrupt Handling**: Clean shutdown on SIGINT/SIGTERM

### Recovery Recommendations
- **Failed Modules**: Automatic generation of remediation suggestions
- **Warning Conditions**: Proactive maintenance recommendations
- **Performance Issues**: Resource optimization guidance

## Best Practices

### Regular Monitoring
1. **Daily Automated Checks**: Schedule quiet mode checks daily
2. **Weekly Detailed Reviews**: Run verbose checks weekly
3. **Alert Integration**: Configure alerting for failures
4. **Log Rotation**: Implement log management for long-term storage

### Troubleshooting
1. **Module-Specific Issues**: Use individual check scripts for detailed diagnosis
2. **Performance Problems**: Use timing information to identify bottlenecks
3. **Configuration Validation**: Review module configurations when checks fail
4. **Resource Monitoring**: Monitor system resources during checks

### Security Considerations
1. **Root Privileges**: Most checks require root access for full functionality
2. **Log Security**: Secure log files with appropriate permissions
3. **Script Integrity**: Verify script checksums in production environments
4. **Access Control**: Limit access to health check scripts

## Technical Architecture

### Module Dependencies
The script checks modules in dependency order:
1. **database** - Foundation services
2. **dns** - Network infrastructure  
3. **firewall** - Security layer
4. **ssl** - Certificate services
5. **webserver** - Application services
6. **extra** - Additional services
7. **backup** - Data protection

### Performance Optimization
- **Parallel Execution**: Future enhancement for concurrent module checks
- **Caching**: Module script validation caching
- **Resource Monitoring**: Built-in performance tracking
- **Early Termination**: Fast-fail options for critical issues

## Future Enhancements

### Planned Features
1. **JSON Output**: Machine-readable output format
2. **API Integration**: REST API for remote monitoring
3. **Dashboard**: Web-based status dashboard
4. **Notifications**: Email/SMS alert integration
5. **Metrics Export**: Prometheus/Grafana integration
6. **Parallel Execution**: Concurrent module checking
7. **Configuration Management**: Central configuration file
8. **Plugin System**: Custom module support

### Integration Opportunities
1. **CI/CD Pipelines**: Pre-deployment health validation
2. **Infrastructure as Code**: Terraform/Ansible integration
3. **Container Orchestration**: Kubernetes health checks
4. **Cloud Monitoring**: AWS/Azure/GCP integration

This comprehensive health checking system provides enterprise-grade monitoring capabilities for the Linux Setup infrastructure, ensuring reliable operations and proactive issue detection.

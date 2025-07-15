# Scripts

Utility scripts for the realtime-log-pipeline project.

## Quick Usage

```bash
# Generate test logs
./test-log-format.sh

# Start log generation (5 minutes)
./generate-logs-advanced.sh --clear -d 300

# Monitor logs
tail -f ../data/access.log

# Clean up
./clean-logs.sh --backup
```

## Available Scripts

- `generate-logs.sh` - Basic log generator
- `generate-logs-advanced.sh` - Advanced log generator with options
- `test-log-format.sh` - Generate sample logs for testing
- `clean-logs.sh` - Clean up log files
- `deploy-flink-job.sh` - Deploy Flink jobs (TBD)
- `health-check.sh` - Health check all services (TBD)

## Documentation

See detailed documentation: [`docs/scripts-guide.md`](../docs/scripts-guide.md)

## Prerequisites

Make scripts executable:
```bash
chmod +x *.sh
```

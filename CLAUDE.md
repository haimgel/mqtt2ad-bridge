# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an MQTT to Active Directory bridge that creates MQTT switches to control AD group membership. It's a containerized wrapper around the mqtt2cmd gateway that manages group membership for network access control.

## Architecture

- **Core Component**: Docker container based on Alpine Linux with Samba tools
- **Dependencies**: Uses mqtt2cmd (v0.1.5) for MQTT switch functionality
- **Main Script**: `ad-command.sh` - handles AD group operations (add/remove/check members)
- **Configuration**: `mqtt2cmd.yaml` - defines MQTT switches and their commands
- **Deployment**: Designed for Kubernetes with ConfigMap and Secret management

## Development Commands

### Building
```bash
docker build -t mqtt2ad-bridge .
```

### Testing Locally
The container expects these environment variables:
- `AD_DOMAIN` - Active Directory domain
- `AD_USERNAME` - AD service account username
- `PASSWD_FILE` - Path to password file

### GitHub Actions
Automated building and publishing to GitHub Container Registry via `.github/workflows/package.yaml` on pushes to main or tags.

## Key Files

- `Dockerfile` - Multi-stage build using mqtt2cmd base image
- `ad-command.sh` - Bash script for samba-tool group operations
- `mqtt2cmd.yaml.sample` - Example configuration for MQTT switches
- `README.md` - Complete deployment documentation with Kubernetes examples

## Configuration Notes

Each MQTT switch configuration requires:
- `turn_on`: Command to add user/group to AD group
- `turn_off`: Command to remove user/group from AD group
- `get_state`: Command to check current membership status
- `refresh`: Interval for state checking

The ad-command.sh script uses samba-tool with LDAP URL and expects password via file reference.
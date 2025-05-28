#!/bin/bash

CRON_FILE="/opt/cron.jobs"

if [ -f "$CRON_FILE" ]; then
    crontab "$CRON_FILE"
fi

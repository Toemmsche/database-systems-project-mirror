#!/bin/bash

python init_only.py

# Set amount of workers to roughly 2 * core count for optimal performacne
gunicorn -b 0.0.0.0:5000 --workers=12 'server:app'
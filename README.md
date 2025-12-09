# Electrical Impedance Tomography for Granuloma Detection

This repository contains the MATLAB code used to generate the simulations and figures for ongoing EIT work.

## Contents
- `Electrical Impedance Tomography.pdf` - Report on general EIT concepts/hardware and ongoing work at Northwestern University
- `humanthorax.m` – Builds the pre-meshed human thorax model with lungs + solves inverse problem for conductivity-based 3D image reconstruction.
- `Sensitivity Measurements/granuloma.m` – Simulations with a high-conductivity granuloma region.
- `Sensitivity Measurements/justlungs.m` – Baseline lung-only model for comparison.
- `Sensitivity Measurements/voltagedifference.m` – Computes ΔV between baseline and granuloma cases and ranks the most sensitive measurements.
- `.gitignore` – Excludes OS and temporary files from version control.

## Reproducing the figures

1. Install [EIDORS](https://eidors3d.sourceforge.net/download.shtml) and add it to your MATLAB path.
2. Run `humanthorax.m` to generate the baseline thorax + lungs simulations.
3. Run `Sensitivity Measurements/granuloma.m` and `justlungs.m` to simulate the granuloma and baseline cases.
4. Run `Sensitivity Measurements/voltagedifference.m` to compute and plot ΔV and ranked measurements.

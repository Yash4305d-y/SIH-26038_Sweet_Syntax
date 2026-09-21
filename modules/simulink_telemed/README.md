# Role 3 Work Workspace Structure

This document is a complete snapshot of the current `Role 3 work` MATLAB/Simulink workspace after generated build artifacts and redundant files were removed.

## Snapshot Summary

| Item | Count / value |
| --- | ---: |
| Directories, excluding the workspace root | 5 |
| Files, including this document | 16 |
| Total file size | 204,053 bytes |
| Generated `slprj` directories | 0 |
| Compiled `.slxc` files | 0 |
| MATLAB source files (`.m`) | 7 |
| Simulink models (`.slx`) | 2 |
| MATLAB data files (`.mat`) | 3 |
| Markdown files (`.md`) | 3 |
| Ignore file (`.gitignore`) | 1 |

The file count includes `.gitignore` and this document. It excludes directories from the file count.

## Complete Current Tree

```text
Role 3 work/
├── .gitignore
├── WORKSPACE_STRUCTURE.md
├── documentation/
│   ├── Day1_Architecture.md
│   └── Day2_DigitalTwin_Report.md
├── model/
│   ├── DR_DigitalTwin.slx
│   └── DR_DigitalTwin_Day2.slx
├── parameters/
│   ├── queueWaitStats.m
│   └── simulation_parameters_day2.m
├── results/
│   ├── day2_experiment_results.mat
│   ├── results_30day.mat
│   └── results_365day.mat
└── scripts/
    ├── analyze_results.m
    ├── init_model.m
    ├── queueWaitStats.m
    ├── run_simulation.m
    └── run_test.m
```

There are no nested subfolders below `documentation/`, `model/`, `parameters/`, `results/`, or `scripts/` in the current workspace.

## File Inventory

The sizes and timestamps below are the values captured during this structure-documentation update.

| Path | Type | Size | Last modified | Role |
| --- | --- | ---: | --- | --- |
| `.gitignore` | Git ignore rules | 175 bytes | 2026-09-09 20:29:35 | Prevents generated MATLAB/Simulink files, backups, and OS metadata from being tracked. |
| `WORKSPACE_STRUCTURE.md` | Markdown | 10,216 bytes | Created during this update | Complete workspace structure and file reference. |
| `documentation/Day1_Architecture.md` | Markdown | 2,372 bytes | 2026-09-04 17:08:24 | Defines the Day 1 discrete-event screening topology, entity attributes, retry logic, AI routing, and human-review paths. |
| `documentation/Day2_DigitalTwin_Report.md` | Markdown | 1,925 bytes | 2026-09-09 20:21:00 | Records Day 2 parameter provenance and reported 330-day operational telemetry. |
| `model/DR_DigitalTwin.slx` | Simulink model | 57,205 bytes | 2026-09-04 17:10:02 | Base or Day 1 topology model used by the test workflow. |
| `model/DR_DigitalTwin_Day2.slx` | Simulink model | 65,628 bytes | 2026-09-09 20:08:08 | Active district-scale Day 2 model used by initialization and the main simulation runner. |
| `parameters/queueWaitStats.m` | MATLAB function | 1,528 bytes | 2026-09-09 19:52:03 | Accumulates queue wait time, maximum wait, and processed-entity count using persistent state. |
| `parameters/simulation_parameters_day2.m` | MATLAB configuration | 8,057 bytes | 2026-09-09 20:16:05 | Creates `simParams`, derived event-action variables, and the active Day 2 simulation settings. |
| `results/day2_experiment_results.mat` | MATLAB data | 12,697 bytes | 2026-09-09 20:17:31 | Saved manual-baseline experiment output according to `run_simulation.m`. |
| `results/results_30day.mat` | MATLAB data | 12,691 bytes | 2026-09-09 20:17:13 | Saved 30-day AI-assisted verification output. |
| `results/results_365day.mat` | MATLAB data | 12,688 bytes | 2026-09-09 20:17:21 | Saved long district-scale AI-assisted output; the runner labels this scenario as 330 days. |
| `scripts/analyze_results.m` | MATLAB script | 7,822 bytes | 2026-09-09 19:57:54 | Loads district results and calculates screening volume, IQA filtering, review demand, workload, and utilization. |
| `scripts/init_model.m` | MATLAB script | 1,764 bytes | 2026-09-09 19:50:18 | Adds project paths, loads Day 2 parameters, resets queue statistics, and loads the Day 2 model. |
| `scripts/queueWaitStats.m` | MATLAB function | 1,528 bytes | 2026-09-09 19:51:06 | Duplicate helper copy for queue wait statistics. |
| `scripts/run_simulation.m` | MATLAB script | 6,689 bytes | 2026-09-09 19:49:27 | Runs 30-day AI, 330-day AI, and 330-day manual scenarios and saves three result files. |
| `scripts/run_test.m` | MATLAB script | 1,068 bytes | 2026-09-04 16:01:07 | Intended Day 1 topology test for the base model. It still references the deleted legacy parameter script. |

## Folder Details

### `documentation/`

Human-authored project documentation.

- `Day1_Architecture.md` describes one screening entity as a fundus screening packet. It documents `retry_count`, IQA status, DR severity, confidence, routing values, retry behavior, AI processing, specialist review, and five tested Day 1 paths.
- `Day2_DigitalTwin_Report.md` documents measured and assumed values, including IQA failure rate, AI processing time, referable DR rate, low-confidence rate, review times, district scale, staffing, and reported 330-day telemetry.

### `model/`

Binary Simulink model sources.

- `DR_DigitalTwin.slx` is the base model referenced by `run_test.m`.
- `DR_DigitalTwin_Day2.slx` is the active Day 2 model named `DR_DigitalTwin_Day2` and referenced by `init_model.m` and `run_simulation.m`.
- No backup model or Day 1 duplicate model remains.

### `parameters/`

Active MATLAB configuration and reusable simulation helper functions.

- `simulation_parameters_day2.m` clears and constructs the nested `simParams` structure. Its settings include a 330-day run, 100,000 patients per year, 8 operational hours per day, IQA failure and retry limits, AI and review timing, two reviewers, network delay/dropout, AI or manual review mode, and derived SimEvents variables.
- `queueWaitStats.m` provides persistent running queue metrics: mean wait, maximum wait, and entity count. Calling it with a reset flag clears its state.
- The former `simulation_parameters.m` file was intentionally removed as a legacy/conflicting configuration file.

### `results/`

Authoritative saved MATLAB result files.

- `results_30day.mat` is the 30-day verification result.
- `results_365day.mat` is the long district-scale result file selected first by `analyze_results.m`.
- `day2_experiment_results.mat` is the manual comparison experiment result.
- The former misplaced `parameters/results_30day.mat` file was removed.

### `scripts/`

Execution, initialization, testing, and analysis entry points.

- `init_model.m` establishes MATLAB paths, loads Day 2 parameters, resets queue metrics, and preloads the Day 2 model.
- `run_simulation.m` runs and saves three scenarios: 30-day AI, 330-day AI district scale, and 330-day manual baseline.
- `analyze_results.m` reads the district result, falls back to the 30-day result if needed, and calculates operational telemetry.
- `run_test.m` opens the base model and is intended for Day 1 testing, but currently calls `../parameters/simulation_parameters.m`, which no longer exists. This is a known stale reference and is documented here rather than silently changing the script.
- `queueWaitStats.m` is a duplicate of the helper in `parameters/`.

## Configuration Values Documented in `simulation_parameters_day2.m`

| Configuration area | Current value or behavior |
| --- | --- |
| Simulation horizon | 330 days; stop time is calculated in seconds |
| District volume | 100,000 patients per year |
| Operating schedule | 8 hours per day |
| IQA failure rate | 0.136792 |
| Maximum additional IQA retries | 2 |
| AI processing time | 1.45 seconds |
| Referable DR rate | 0.435080 |
| Low-confidence rate | 0.047836 |
| Total human-review trigger rate | 0.482916 |
| AI-assisted review time | 30 seconds |
| Manual review time | 240 seconds |
| Parallel reviewers | 2 |
| Network | Enabled, 1.8-second delay, 0.05 dropout probability |
| Default review mode | `AI` |
| Dropout experiment flag | Enabled |

## Data Flow

```text
parameters/simulation_parameters_day2.m
                |
                v
scripts/init_model.m ------------------+
                |                       |
                v                       v
scripts/run_simulation.m ------> model/DR_DigitalTwin_Day2.slx
                |                       |
                +-----------------------+
                |
                v
results/*.mat
                |
                v
scripts/analyze_results.m
```

The base model `model/DR_DigitalTwin.slx` is a separate test target for `scripts/run_test.m`. Both queue-statistics copies provide the `queueWaitStats` function to MATLAB/SimEvents workflows.

## Generated Artifact Policy

The cleanup removed all generated build artifacts from the workspace:

- No directory named `slprj` remains.
- No `.slxc` compiled Simulink cache remains.
- No `.autosave` or `.asv` files are present in the current inventory.
- Backup model and `.original` files were removed.
- `.gitignore` blocks future `slprj/`, `.slxc`, `.autosave`, `.asv`, `.original`, and `.bak` files, plus `.DS_Store` and `Thumbs.db`.

Generated files should be regenerated by MATLAB/Simulink when needed and should not be treated as primary source files.

## Important Current-State Notes

1. The authoritative 30-day result is `results/results_30day.mat`; there is no duplicate under `parameters/`.
2. `simulation_parameters_day2.m` is the only parameter configuration file under `parameters/`.
3. The long-run result is named `results_365day.mat`, while `run_simulation.m` describes the corresponding scenario as 330 days. The filename and scenario label are therefore not identical.
4. `scripts/run_test.m` still expects the deleted legacy parameter file and will require a future update before its Day 1 test can run successfully.
5. The `.slx` files are binary model sources and should be inspected through MATLAB/Simulink rather than edited as text.
6. The `.mat` files are serialized MATLAB data. Use MATLAB `whos -file` or `load` to inspect their variables before interpreting their contents.

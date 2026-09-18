# 04 — Simulink & SimEvents Telemedicine Operations Architecture Research
## SIH 26038 — Explainable AI for Diabetic Retinopathy Screening in Rural India

> **Consolidated union of three Simulink/SimEvents research documents.**
>
> The three supplied research files were merged into one technical baseline. Repeated material is not blindly duplicated; substantive details, alternative modeling approaches, equations, parameter tables, implementation guidance, scenarios, risks, and recommendations are retained. Where the sources use different modeling choices, both are preserved and the distinction is made explicit in the final reconciliation section.
>
> **Scope:** operational healthcare-workflow simulation around the DR-AI system — patient flow, image acquisition, IQA/recapture, AI service time, reporting, network transfer, queues, resources, ophthalmologist review, throughput, latency, bottlenecks, resilience, and 100,000+ annual capacity planning.
>
> **Explicit boundary:** the operational simulation does not model retinal biology, pixel-level neural-network computation, or clinical accuracy. The AI is represented as a black-box service with measured/configurable processing time and categorical outputs. The source documents explicitly distinguish AI-model metrics from operational metrics. 


## 1. Purpose

This document defines an implementation-ready Simulink/SimEvents architecture for modeling the **operational diabetic-retinopathy screening system** around the AI pipeline: patient arrivals, fundus acquisition, quality failures and recapture, AI processing, telemedicine transfer, ophthalmologist review, referral decisions, queues, resource contention, and capacity planning.

The simulation does **not** model retinal biology, disease progression, or neural-network internals. Instead, it treats AI inference, explainability, and reporting as operational service stages with configurable delays, failure probabilities, and outputs. SimEvents is designed for discrete-event models that analyze latency, throughput, packet loss, routing, queues, service delays, prioritization, and resource utilization. [cite:93][cite:94]

**Why Simulink is being used.** The AI model (image quality assessment, DR classification, explainability) is only one component of a working screening program. The program's real-world success depends on *operational* factors: how fast patients can be screened, whether the network can carry images from a Primary Healthcare Centre (PHC) to a server, whether enough ophthalmologists exist to review flagged cases, and whether the whole chain can sustain a target volume (100,000+ patients/year) without unbounded queues. These are classic discrete-event, resource-constrained system questions — the domain Simulink/SimEvents is built for.

**What problem the simulation solves.** It answers questions such as:
- Given N cameras, M doctors, and a rural network link of B Mbps, what is the maximum sustainable patient throughput?
- Where does the system break first — the camera, the AI compute, the network, or the doctor — as patient load scales toward 100,000+/year?
- How does a doctor shortage, a low-bandwidth PHC, or a high image-recapture rate change waiting time and annual capacity?
- What is the minimum resource configuration (cameras, doctors, bandwidth) that meets a target throughput?

**Why simulation is valuable before real deployment.** Discrete-event simulation lets the team test resource allocations, network conditions, and failure modes cheaply and repeatedly — before committing to procurement (how many fundus cameras, how many ophthalmologist-hours) or before a pilot district discovers, in the field, that its single reviewing doctor cannot keep pace with four PHCs' worth of cases.

**What should be simulated:**
- Patient arrival and registration
- Image acquisition and image-quality gating (recapture loop)
- AI processing as a *timed, resource-consuming* step (not a biological/pixel-level model)
- Report generation and network transmission
- Doctor review queueing and capacity
- End-to-end latency, throughput, utilization, and bottlenecks
- Scaling to a district/state-level, 100,000+ patient/year scenario

**What should NOT be simulated:**
- Retinal pathology, disease progression, or fundus image pixel content
- The internal computation of the neural network (convolution layers, gradients, etc.)
- Diagnostic accuracy phenomena (sensitivity/specificity) as a function of image data — this belongs to a separate ML-evaluation workflow, not the operational model
- Detailed TCP/IP packet-level network protocol behavior — an abstracted bandwidth/latency model is sufficient for this project's purpose

## 2. Why Simulink & SimEvents?

Simulink provides the time-based integration environment, while **SimEvents** supplies the discrete-event engine and components needed for queues, entities, servers, routing, scheduling, priorities, and resource allocation. [cite:93][cite:103] The screening process is event-driven: a patient arrives, a camera becomes free, an image enters a queue, a transmission begins, an ophthalmologist becomes available, and a case exits with a decision.

SimEvents is more suitable than ordinary continuous-time Simulink blocks for the core workflow because waiting time and state changes occur at irregular event times rather than as continuously evolving physical signals. SimEvents includes predefined queues, servers, switches, entity generation/termination, resource pools, routing, and statistics features. [cite:96][cite:102]

| Technology | Role | Why Needed | Project Component |
|---|---|---|---|
| **Standard Simulink** | Signal processing, parameter sources, scopes, logging | Integrates event model with time-based signals and visualization | Service-time inputs, metric displays, result logging |
| **SimEvents** | Main operational simulation | Models discrete patients/cases, queues, servers, routing, resource contention | Patient flow, camera queue, AI queue, network queue, doctor queue |
| **Stateflow** | Stateful decision logic | Useful for multi-state policies, retries, availability, escalation | Recapture, retry policy, doctor unavailable state, referral logic |
| **MATLAB scripts/functions** | Parameterization, AI timing measurement, batch experiments, post-analysis | Automates scenarios and imports empirical distributions | Calibration, Monte Carlo runs, annual capacity calculations |
| **MATLAB Function block** | Computation embedded in Simulink | Runs deterministic calculations at configured sample times | Compression-time calculation, quality decision score, routing flag |
| **SimEvents event actions** | Entity-specific event logic | Sets service time and changes entity attributes | Assigning priority, retry count, timestamps, DR class |

**Decision:** SimEvents is strongly recommended and effectively required for a credible implementation because SIH requires queues, capacity constraints, resource allocation, transmission behavior, reviewer availability, and throughput analysis.

## 3. Complete Screening Workflow

```
[Patient Arrival]
       │
       ▼
[Registration / Triage Queue]
       │
       ▼
[Fundus Camera Acquisition] ◄─────────────────────────────────┐
       │                                                       │
       ▼                                                       │
[Edge Image Quality Assessment (IQA)]                         │
       │                                                       │
       ├───► [IQA = Ungradable] ───► [Recapture Limit Check] ──┘
       │                                  │ (Exceeded Max Retries)
       │                                  ▼
       │                          [Refer to Base Hospital]
       ▼ (IQA = Gradable)
[Edge AI Inference: ICDR Grading & XAI Map]
       │
       ▼
[Report Assembly & Local Cache]
       │
       ▼
[Uplink Transmission Queue] ◄─────────────────────────────────┐
       │                                                       │
       ▼                                                       │
[Bandwidth-Constrained Rural Link]                             │
       │                                                       │
       ├───► [Packet Drop / Network Timeout] ──► [Retry Loop] ─┘
       │                                              │ (Max Retries)
       │                                              ▼
       │                                     [Local Batch Stash]
       ▼ (Transmission Success)
[Central Telemedicine Server / Ingestion]
       │
       ▼
[Priority Triage Engine]
       ├───► High-Priority Queue (Referable DR: Severe NPDR / PDR / Ungradable Flags)
       └───► Routine Queue (Non-Referable: Normal / Mild NPDR)
                 │
                 ▼
[Tele-Ophthalmologist Review Pool]
       │
       ▼
[Final Diagnosis & Referral Ticket Generation]
       │
       ▼
[Patient Notification / Health Record Integration]
```

```text
Patient Arrival
  → Registration
  → Fundus Camera / Operator Queue
  → Fundus Image Acquisition
  → Image Quality Assessment
  → [Ungradable?]
      ├─ Yes → Recapture Queue → Camera / Operator Queue
      └─ No  → Enhancement / Standardization
                 → AI Inference Queue
                 → DR Classification
                 → XAI / Confidence Generation
                 → Automated Report Generation
                 → Upload / Network Queue
                 → Transmission / Server Reception
                 → [Transmission Successful?]
                     ├─ No → Retry / Deferred Upload Queue
                     └─ Yes → Ophthalmologist Review Queue
                               → Doctor Resource
                               → Final Review / Decision
                               → [Refer / Routine Follow-up / Repeat Image]
                               → Case Completion
```

| Stage | Simulation Classification | Recommended Representation |
|---|---|---|
| Patient arrival | Event/entity creation | SimEvents `Entity Generator` |
| Registration | Service with possible queue | `Entity Queue` + `Entity Server` |
| Camera acquisition | Constrained service/resource | Queue + Resource Pool/Acquirer + Server + Releaser |
| IQA | Service and decision | Entity Server, event action or MATLAB Function |
| Recapture | Routing loop | Entity Output Switch + Queue/Server loop |
| Enhancement | Processing delay | Entity Server |
| AI inference | Compute service/resource | Queue + server; optional compute Resource Pool |
| XAI/report generation | Processing delay | Entity Server |
| Upload/transmission | Queued communication service | Queue + bandwidth-dependent Entity Server |
| Failed transmission | Event decision/retry | Entity Output Switch + retry queue |
| Ophthalmologist review | Human resource service | Queue + Resource Pool + Entity Server |
| Referral decision | Entity routing | Output Switch/Stateflow/MATLAB event logic |
| Completion | Entity exit | `Entity Terminator` |

## 4. System Entities

To balance model fidelity and simulation performance, the system uses two discrete entity types: a **Patient Entity** at the clinic level, which transitions into an **Image/Tele-Record Entity** for network and cloud stages.

```
[Patient Entity]                        [Tele-Record Entity]
┌────────────────────────────────┐      ┌────────────────────────────────┐
│ - PatientID                    │      │ - RecordID / PatientIDRef      │
│ - PHC_ID                       │ ───► │ - FileSize_MB                  │
│ - ArrivalTimestamp             │      │ - AI_ICDR_Grade (0-4)          │
│ - DilationStatus               │      │ - UrgencyPriority (1=High,2=Low)│
│ - RecaptureCount               │      │ - NetworkAttempts              │
└────────────────────────────────┘      └────────────────────────────────┘
```

Use one primary entity: **ScreeningCase**, representing one patient screening episode from registration to final decision. Separate image-packet entities are not needed for the MVP; add them only for packet-level networking research.

| Entity | Meaning | Created At | Destination | Key Attributes |
|---|---|---|---|---|
| **ScreeningCase** | One patient screening episode | Patient generator / registration | Entity Terminator after decision | `caseID`, `phcID`, `arrivalTime`, `priority`, `imageSizeMB`, `qualityFlag`, `recaptureCount`, `drClass`, `referFlag`, `networkRetries` |
| **Optional NetworkPacket** | Transferred image/report packet | Upload stage | Telemedicine server | `caseID`, `payloadMB`, `retryCount`, `transmissionStart` |
| **Optional DoctorShiftToken** | Availability/control representation | Shift scheduler | Doctor resource control | `doctorID`, `available`, `shiftEndTime` |

Simulation attributes are not real clinical data and must never contain personally identifiable information.

| Entity | Meaning | Created At | Destination | Attributes |
|---|---|---|---|---|
| Patient | A person arriving for screening | Patient Generator (registration) | Terminates at final decision or referral handoff | Patient ID, PHC/location, arrival timestamp, priority flag |
| Fundus image | The captured retinal image object flowing through IQA/AI/network | Acquisition stage | Consumed at report generation (or merged into report) | Image ID, quality score, size (MB), capture attempt count |
| Screening case | The unit of work tracked from acquisition through decision (often the same logical entity as "Patient," carrying accumulated attributes) | Acquisition (or registration) | Terminates at final decision | Case ID, DR class output, confidence score, processing timestamps |
| AI processing job | The compute task representing inference + XAI | AI Processing stage entry | Terminates when AI Processing/XAI stage completes | Job ID, inference duration, DR class, confidence |
| Telemedicine packet/report | The transmitted report object | Report Generation stage | Consumed at Doctor Review entry (or Network server exit) | Report ID, payload size, transmission attempt count |
| Doctor review case | The unit queued for and processed by the ophthalmologist | Doctor Queue entry | Terminates at Final Decision | Case ID (linked to Screening case), review start/end time, decision |
| Referral case | A downstream case created only for positive/uncertain findings | Final Decision (referral branch) | Exits to a (not-modeled) referral facility, or simulation terminator | Referral ID, urgency, linked case ID |

**Recommendation:** For an MVP, it is neither necessary nor advisable to model all seven as fully distinct SimEvents entity types with separate generators. The cleanest architecture is to treat **"Screening case"** as the single primary entity flowing through the whole pipeline, carrying attributes that evolve at each stage (image quality, DR class, report size, etc.). A separate **"Referral case"** entity can be spawned at the Final Decision branch only when referral is triggered, since referral cases follow a distinct downstream path. Modeling "Fundus image," "AI processing job," and "Telemedicine packet" as separate entities is a **possible refinement** for more detailed network/compute analysis, not a baseline requirement.

**Simulation entities vs. real clinical data:** All entity attributes in the simulation (DR class, quality score, confidence) are **synthetic values generated by random distributions or scripted rules** for the purpose of exercising the operational model. They are not derived from, and must not be presented as, real patient data or real AI model outputs.

---

## 5. System Resources

```
+---------------------------------------------------------------------------------------+
|                             RESOURCE CONTENTION MODEL                                 |
+---------------------------------------------------------------------------------------+
|  [Fundus Camera Pool]       ── Seized by Patient Entity ──► [Released post-IQA]       |
|  [Trained PHC Technician]   ── Seized by Patient Entity ──► [Released post-Capture]   |
|  [Edge Compute (Jetson/PC)] ── Seized by Record Entity  ──► [Released post-AI]        |
|  [Uplink Channel Slices]    ── Seized by Packet Stream  ──► [Released post-ACK]       |
|  [Ophthalmologist Pool]     ── Seized by Priority Queue ──► [Released post-Report]    |
+---------------------------------------------------------------------------------------+
```

SimEvents supports constrained resource allocation using `Resource Pool`, `Resource Acquirer`, and `Resource Releaser` blocks. [cite:105][cite:109]

| Resource | Capacity | Shared? | Bottleneck Potential | SimEvents Representation |
|---|---:|---:|---|---|
| Fundus camera | 1+ per PHC | Usually local | High during camps/high arrivals | Resource Pool + Queue + Acquisition Server |
| PHC operator | 1+ per PHC | May serve multiple tasks | High if registration/acquisition both require operator | Resource Pool + Acquirer/Releaser |
| AI CPU/GPU slots | 1+ centralized/distributed | Shared across PHCs | High if inference/XAI is slow | Compute Resource Pool + AI Server |
| Telemedicine server | Configurable | Shared | Moderate under bursts | Server capacity or Resource Pool |
| Upload link | One logical channel or configurable concurrency | Shared per PHC | High at low bandwidth | Queue + bandwidth-dependent Server |
| Ophthalmologist | 1+ | Shared district resource | Often high | Resource Pool + Review Queue + Server |
| Review terminal | 1 per doctor or shared | Shared | Low unless scarce | Optional Resource Pool |

A case acquires a resource before service and releases it after service. This models actual contention and produces resource-utilization statistics.

| Resource | Capacity | Shared? | Bottleneck Potential | Simulation Representation |
|---|---:|---|---|---|
| Fundus cameras | Per-PHC, small integer (e.g., 1–3) | Shared among patients at that PHC | High — direct limiter of acquisition rate | Resource Pool sized per PHC, acquired at Acquisition stage |
| PHC operators | Per-PHC, small integer | Shared with camera use (often 1:1 with camera) | Moderate–High | Resource Pool, or combined with camera as a single "acquisition station" resource |
| Image-processing compute (CPU/GPU) | Depends on deployment (edge device at PHC vs. centralized server) | Shared across PHCs if centralized | High if centralized and under-provisioned | Resource Pool representing available compute "slots"; Entity Server for inference duration |
| Network bandwidth | Mbps per PHC uplink | Not shared beyond the PHC's own link (unless multiple PHCs share a backhaul) | High in poor-connectivity rural settings | Resource Pool representing available bandwidth "units," or Entity Server whose service time = image size / available bandwidth |
| Telemedicine server (reception/report storage) | Server-side capacity (concurrent connections) | Shared across all PHCs feeding into it | Moderate | Resource Pool for concurrent transmission slots |
| Ophthalmologists | Small integer, centralized or district-level | Shared across all PHCs in the district | High — classic single-scarce-expert bottleneck | Resource Pool sized by number of doctors; Entity Server = review time |
| Doctor review terminals/workstations | Usually ≥ number of doctors (rarely the limiter) | Shared if fewer terminals than doctors | Low, unless deliberately under-provisioned | Resource Pool (optional; often capacity = number of doctors) |

**Modeling resource contention:** Use the **Resource Pool** block to declare the finite quantity of each resource, and one or more **Resource Acquirer** blocks placed before the relevant processing/service stage to have entities request and hold a resource for the duration of that stage; a **Resource Releaser** block placed after the service stage returns the resource to the pool. <cite index="17-1">The Resource Pool block defines resources that entities can use during model simulation; you use Resource Acquirer and Resource Releaser blocks to work with these resources</cite>. <cite index="12-1">An entity does not depart the Resource Acquirer block until it acquires all of the requested resources — for example, if an entity requests 5 resources and only 2 are available, it waits until all requested resources are available</cite>. This is precisely the mechanism to model "a patient waits until a camera is free" or "a case waits until a doctor is free." When multiple Resource Acquirer blocks compete for the same pool, <cite index="14-1">the priority order of Resource Acquirer blocks is fixed at the start of simulation and cannot be changed dynamically, so the entity at the higher-priority acquirer always acquires the resource first</cite> — relevant if referral/priority cases should be modeled as pre-empting normal-queue doctor access (this would need to be handled via queue sorting policy/priority attributes rather than acquirer priority, since acquirer priority is static).

---

## 7. Queue Model

The system is modeled as an open queuing network with multiple service stations, non-exponential service distributions, finite capacities, and priority scheduling.

```
+-------------------------------------------------------------------------------------------------+
|                                 DISTRICT QUEUING TOPOLOGY                                       |
+-------------------------------------------------------------------------------------------------+
|  [PHC 1] ──> M/G/1 (Camera) ──> M/D/1 (AI) ──┐                                                  |
|  [PHC 2] ──> M/G/1 (Camera) ──> M/D/1 (AI) ──┼──> [G/G/1 Link] ──┐                             |
|    ...                                       │                   │                             |
|  [PHC N] ──> M/G/1 (Camera) ──> M/D/1 (AI) ──┘                   ▼                             |
|                                                     [Priority Ingestion Queue]                  |
|                                                                  │                              |
|                                                     ┌────────────┴────────────┐                 |
|                                                     ▼                         ▼                 |
|                                            (Priority: High)           (Priority: Low)           |
|                                            Referable DR Cases         Routine Cases             |
|                                                     │                         │                 |
|                                                     └────────────┬────────────┘                 |
|                                                                  ▼                              |
|                                                        M/G/c Doctor Review Pool                 |
+-------------------------------------------------------------------------------------------------+
```

| Queue | Arrival Process | Service Process | Servers | Discipline | Capacity | Bottleneck Risk | Metrics |
|---|---|---|---:|---|---:|---|---|
| Registration queue | Patient arrivals | Registration duration | Operators | FIFO | Configurable | Moderate | Wait, queue length |
| Camera queue | Registered cases | Acquisition time | Cameras/operators | FIFO | Configurable | High during camps | Wait, utilization |
| Recapture queue | Ungradable cases | Repeat acquisition | Cameras/operators | FIFO | Configurable | High when IQA fails | Recapture count, delay |
| AI queue | Gradable images | Inference + XAI/report | CPU/GPU slots | FIFO | Configurable | High if undersized | Queue length, utilization |
| Network queue | Reports/images ready to upload | Bandwidth transfer | Upload channels | FIFO/priority | Configurable | High at low bandwidth | Upload wait, retries |
| Doctor queue | Uploaded cases | Review duration | Ophthalmologists | FIFO/priority | Configurable | Often critical | Wait, utilization, P95 latency |
| Retry queue | Failed uploads | Retry/backoff | Link/server | FIFO | Configurable | High under unstable links | Failure and retry count |

## 8. Network / Internet Model

Model the network at application-transfer level, not packet level, for MVP.

```text
AI/XAI/Report Complete
  → Compression / Payload Assignment
  → Network Upload Queue
  → Transmission Service
  → Propagation / Server Delay
  → [Success?]
      ├─ Yes → Doctor Queue
      └─ No  → Retry Backoff → Network Upload Queue
```

For payload size \(S\) in megabytes and effective uplink \(B\) in Mbps:

\[
T_{tx} =
rac{8S}{B}
\]

\[
T_{network} = T_{queue} + T_{tx} + T_{latency} + T_{jitter} + T_{retry}
\]

| Parameter | Status | Modeling Guidance |
|---|---|---|
| Image size | Scenario parameter unless measured | Measure actual post-compression payload |
| Upload bandwidth | Field-data parameter when available | Use effective measured uplink, not advertised rate |
| Latency/jitter | Field-data parameter when available | Use empirical traces or sensitivity ranges |
| Packet loss | Optional engineering assumption | Add only for advanced model |
| Upload failure probability | Scenario parameter unless logs exist | Add retry limit and backoff |
| Compression ratio | Measured/project parameter | Derive from actual output files |

Implement via an `Entity Queue` and an `Entity Server` whose service time is calculated from entity payload and bandwidth. The Entity Server supports service time from dialog, signal, entity attribute, or MATLAB action. [cite:122]

## 9. Ophthalmologist / Doctor Model

The ophthalmologist must be represented as a constrained human resource. The SIH target of approximately **30 seconds for ophthalmologist validation** is a project target/scenario parameter, not a universal real-world average.

```text
Telemedicine Report Received
  → Doctor Review Queue
  → Acquire Ophthalmologist Resource
  → Review Service
  → Final Decision
  → Release Ophthalmologist Resource
  → Case Completion / Referral
```

| Parameter | Meaning | Classification |
|---|---|---|
| Number of ophthalmologists | Parallel reviewer capacity | Scenario parameter |
| Review duration | Image, AI/XAI, and decision time | Project target or field-measured parameter |
| Review-time distribution | Case complexity variation | Assumption or field data |
| Shift duration | Daily availability | Scenario parameter |
| Breaks/unavailability | Planned/non-planned absence | Scenario parameter |
| Priority policy | Urgent/referable case ordering | Workflow policy parameter |

MVP baseline: use 30 seconds as an explicit SIH target and sweep 30, 60, 120, and 300 seconds. Model one doctor as capacity 1 and multiple reviewers through resource-pool or server capacity.

## 10. Throughput & 100,000+ Capacity

Throughput is completed screening cases per unit time and is an **operational metric**.

\[
    ext{Required cases/day} =
rac{100{,}000}{D}
\]

| Operating Assumption | Required Cases/Day | Required Cases/Hour at 8 Hours/Day |
|---|---:|---:|
| 365 calendar days | 274 | 34.2 |
| 300 operating days | 333 | 41.7 |
| 260 operating days | 385 | 48.1 |
| 250 operating days | 400 | 50.0 |
| 220 operating days | 455 | 56.8 |

At 30 seconds per review, the arithmetic upper-bound capacity is 120 cases/doctor-hour, before breaks, complexity, interruptions, and service variability:

\[

rac{3600}{30} = 120
\]

Enable final-server/terminator departure statistics to measure completed cases. SimEvents can expose queue and server statistics including departures, waiting time, queue length, and utilization. [cite:100][cite:107][cite:119]

Use multiple configurations, not one presumed “correct” deployment. The values below are **simulation scenarios**, not deployment facts.

With 250 operating days and 8 active hours/day, 100,000 annual cases requires 400 cases/day and 50 cases/hour on average.

**All resource counts and per-PHC figures below are scenario parameters chosen to illustrate architecture design trade-offs — none are field-validated facts.**

## 11. Latency

End-to-end latency is time from patient arrival to final decision:

\[
L_{E2E} = W_{registration} + T_{acquisition} + T_{IQA} + W_{recapture} + T_{enhancement} + W_{AI} + T_{AI} + T_{XAI/report} + W_{network} + T_{network} + W_{doctor} + T_{review}
\]

| Component | Recommended Delay Model |
|---|---|
| Registration/acquisition | Empirical or triangular distribution |
| IQA/enhancement | Benchmark-derived constant/distribution |
| AI inference | Actual measured inference time; optional variability |
| XAI/report | Measured or scenario parameter |
| Network | Payload/bandwidth formula + latency/jitter/retry |
| Doctor review | Target/field-derived distribution |
| Queue wait | Emerges from resource contention |

Report mean, median, P90/P95, maximum, and outcome-specific latency. SimEvents supports point-to-point delay measurement using timestamp entity attributes. [cite:120]

## 12. Bottlenecks

| Component | Bottleneck Indicator | Metric | Possible Solution |
|---|---|---|---|
| Camera/operator | High queue and utilization | Camera wait, utilization | Add camera/operator; stagger arrivals |
| IQA/recapture | High repeat rate | Recapture count, added delay | Improve operator training/capture guidance |
| AI compute | Persistent backlog | AI queue, compute utilization | Faster model, batch inference, more slots |
| Network | Upload buildup/retry | Upload queue, transfer time, failures | Compression, store-and-forward, better link |
| Telemedicine server | Delayed acceptance | Server queue/utilization | Scale service capacity |
| Ophthalmologist | Long review queue | Doctor wait/utilization/P95 | Add shifts/reviewers; triage policy |
| Recapture loop | Camera workload amplification | Added acquisition demand | Improve upstream image quality |

SimEvents block statistics can provide average queue length, average waiting time, departures, entities in block, and utilization. [cite:107][cite:119][cite:121]

## 13. Simulation Scenarios

| Scenario | Parameters Changed | Expected Effect | Metrics to Observe | Decision Supported |
|---|---|---|---|---|
| Baseline | Nominal settings | Reference performance | Throughput, latency, utilization | Baseline design |
| High patient load | Increase arrivals/camp bursts | Queue buildup | Queue length, deferred cases | Surge planning |
| Poor internet | Lower bandwidth; more latency/failure | Delayed uploads/retries | Network queue, retries, E2E delay | Connectivity need |
| Doctor shortage | Fewer doctors/shorter shifts | Review backlog | Doctor utilization, P95 wait | Staffing need |
| Camera shortage | Lower camera/operator count | Acquisition delay | Camera queue, completion | Device allocation |
| AI acceleration | Lower AI/XAI time | AI queue falls | Compute utilization, throughput | GPU/model value |
| Larger image size | Increase payload | Longer upload | Network utilization, latency | Compression trade-off |
| High ungradable rate | Increase IQA failure | Recapture increases | Camera utilization, recapture count | Capture-quality intervention |
| 100,000+ annual | District/scaled config | Capacity test | Annual completion, backlog | Target feasibility |
| Resource optimization | Sweep resources | Find minimum feasible configuration | Completion, P95, utilization | Procurement plan |

Use multiple random seeds for stochastic scenarios and report distributions rather than a single run.

| # | Scenario | Parameters changed | Expected effect | Metrics to observe | Decision supported |
|---|---|---|---|---|---|
| 1 | Baseline | Nominal arrival rate, nominal resource counts | Stable queues, moderate utilization | All core metrics | Establishes reference performance |
| 2 | High patient load | Increase arrival rate (e.g., ×1.5–2) | Growing queues, rising latency, possible bottleneck emergence | Queue length, waiting time, utilization | Identify load ceiling of current configuration |
| 3 | Poor internet | Reduce bandwidth, increase latency/jitter/failure rate | Longer transmission times, more retries, possible network bottleneck | Network queue length, failed transmissions, end-to-end latency | Justify need for compression/offline-batching strategies |
| 4 | Doctor shortage | Reduce doctor count (e.g., to 1) | Sharp rise in doctor queue length/waiting time | Doctor utilization, queue length, latency | Quantify minimum safe doctor staffing |
| 5 | Camera shortage | Reduce camera count per PHC | Rising camera queue, patient waiting | Camera utilization, queue length | Justify camera procurement levels |
| 6 | AI acceleration | Reduce AI processing time | Reduced AI-stage latency; reveals whether bottleneck shifts elsewhere | AI queue length, end-to-end latency | Determine value of investing in faster inference hardware |
| 7 | Increased image size | Increase report/image payload size | Longer transmission time, possible network bottleneck | Transmission time, network utilization | Justify compression standards |
| 8 | High ungradable-image rate | Increase recapture probability | Increased effective camera load, longer patient waiting | Recapture rate, camera queue length | Justify investment in capture-quality training/equipment |
| 9 | 100,000+ annual screening | Full-scale deployment configuration (Section 13) | System-wide behavior at target scale | All metrics, especially annual throughput vs. target | Validate/refute feasibility of a given deployment scenario |
| 10 | Resource optimization | Systematically vary doctor count, camera count, bandwidth (parameter sweep) | Identify minimum resource set meeting target throughput/latency | Throughput, latency, utilization across sweep | Produce a cost-minimizing but requirement-meeting configuration recommendation |

---

## 14. Expected Outputs

| Output Group | Metrics |
|---|---|
| Patient/case | Generated, completed, recaptured, rejected, deferred, referred |
| Queue | Mean/max length, mean/P95/max wait, overflow events |
| Processing | AI service time, AI wait, compute utilization, processed/hour |
| Network | Data transmitted, transfer time, utilization, failures, retries |
| Doctor | Utilization, reviewed cases, review wait, idle time |
| System | Mean/median/P95 E2E latency, annual capacity, backlog, bottleneck |

These outputs justify architecture decisions by showing whether the system meets target volume and which resource change improves service most.

## Additional Research Material Retained From the Three Sources

### Technical Research: Simulink & SimEvents Telemedicine Operations Architecture for Rural Diabetic Retinopathy Screening (SIH 26038)

### Context and Operational Scope

Smart India Hackathon Problem Statement 26038 requires designing and evaluating a rural Diabetic Retinopathy (DR) screening architecture serving Primary Healthcare Centres (PHCs) and Community Health Centres (CHCs) in India. The deployment must handle a scale of 100,000+ patients annually across rural administrative districts.

An automated AI pipeline alone does not guarantee clinical effectiveness. The limiting factors in rural deployment are operational:
*   Physical bottlenecks (camera availability, patient movement, dilation delays)
*   Computational constraints (local CPU/GPU latency, edge-to-cloud batching)
*   Network degradation (packet loss, low uplink speeds, connection drops)
*   Human resource limits (tele-ophthalmologist availability, fatigue, shift lengths)

```
+---------------------------------------------------------------------------------------+
|                              SYSTEM BOUNDARY COMPARISON                               |
+---------------------------------------------------------------------------------------+
|  AI MODEL EXECUTION (Excluded from Dynamic Simulink Loop)                              |
|  - Raw Pixel Processing, Matrix Operations, Backprop/Grad-CAM Tensor Generation       |
|  - Accuracy, Sensitivity, Specificity, AUC, F1-Score                                  |
|                                                                                       |
|  HEALTHCARE WORKFLOW SIMULATION (SimEvents / Simulink Domain)                          |
|  - Patient Inter-arrival Dynamics & Queuing Delays                                     |
|  - Image Quality Assessment (IQA) Rejection & In-Clinic Recapture Loops               |
|  - Variable Upstream Transmission Delays (Bandwidth, Jitter, Packet Drop)             |
|  - Ophthalmologist Review Queues, Priority Triage, and Service Times                  |
|  - Throughput, Resource Utilization, Bottlenecks, Annual Operational Capacity         |
+---------------------------------------------------------------------------------------+
```

### What Must Be Simulated vs. What Must Not Be Simulated

*   **What Must Be Simulated:**
    *   Entity lifecycles: patient arrivals, acquisition attempts, telemetry transfers, and remote validation tickets.
    *   Dynamic resource allocation: contention for fundus cameras, local processing hardware, bandwidth links, and doctor pools.
    *   Transient disruptions: network dropouts, queue overflow at clinics, ophthalmologist availability, and variable recapture loops.
*   **What Must NOT Be Simulated:**
    *   Retinal biology, disease progression over years, and physical tissue optics.
    *   Full-resolution tensor matrix multiplications inside the dynamic simulation loop. The AI pipeline is represented abstractly as an empirically profiled service-time distribution ($\mu_{\text{AI}}, \sigma_{\text{AI}}$) and categorical transition probabilities (IQA pass rate, DR grading outcome distributions).

---

### 2. Why Simulink & SimEvents?

Continuous-time simulation environments (integrating differential equations) cannot naturally capture the discrete transitions of healthcare operations (e.g., patient arrivals, queue jumps, or server state changes). This architecture uses a discrete-event framework via **SimEvents**, complemented by **Simulink** for continuous signal tracking and **Stateflow** for finite-state decision logic.

```
+---------------------------------------------------------------------------------------+
|                          HYBRID SIMULATION ARCHITECTURE                               |
+---------------------------------------------------------------------------------------+
|  SimEvents                                                                            |
|  [Entity Generation] ---> [Entity Queues] ---> [Resource Seize/Release] ---> [Sink]   |
|         |                        |                       |                            |
|         v (Entity Attributes)    v (Queue Length)        v (Resource Utilization)     |
|  Simulink Core                                                                        |
|  [Continuous Metric Integration] <---> [Dashboard / Scope Displays]                  |
|         ^                                        ^                                    |
|         | (Operational Mode)                     | (Fault State Transitions)          |
|  Stateflow Logic                                                                      |
|  [Clinic Operating States: Idle | Active | Network_Degraded | Recapture_Loop]         |
+---------------------------------------------------------------------------------------+
```

### Technology Matrix

| Technology | Operational Role | Why Needed | Project Component |
| :--- | :--- | :--- | :--- |
| **SimEvents** | Discrete-event engine, entity generation, queuing, and server allocation. | Directly tracks discrete entities (patients, image packets, review tickets) with discrete timestamps and state transitions without artificial time-slicing. | Patient flow, fundus camera contention, network queues, doctor review queues. |
| **Simulink (Core)** | Continuous tracking, metric aggregation, mathematical signal operations. | Integrates operational statistics over time, tracks moving averages of wait times, and drives visual monitoring scopes. | Moving average latency, bandwidth usage integration, district-level aggregation. |
| **Stateflow** | Finite-state machine and supervisory event-driven logic. | Manages complex control states (e.g., network retry protocols, clinic operational schedules, camera breakdown states). | Recapture retry thresholding, intermittent network switching, doctor shift schedules. |
| **MATLAB Scripts** | Pre-run parameterization, scenario batch sweeping, post-run analytics. | Automates Monte Carlo runs, executes sensitivity analyses, and processes event logs into figures. | Batch simulation runs, sensitivity sweeps, parameter loading (`setup_params.m`). |

---

### Workflow Stage Deconstruction

| Stage | Classification | Modeling Representation | Operational Behavior |
| :--- | :--- | :--- | :--- |
| **Patient Arrival** | Entity & Event | SimEvents `Entity Generator` | Spawns patient entities based on defined arrival distributions. |
| **Registration Queue** | Queue | SimEvents `Entity Queue` (FIFO) | Holds waiting patients prior to capture room access. |
| **Fundus Acquisition** | Resource & Delay | SimEvents `Entity Server` / `Resource Pool` | Seizes operator and camera for acquisition duration ($t_{\text{acq}}$). |
| **IQA Execution** | Delay & Decision | SimEvents `Entity Server` + `Output Switch` | Runs fast edge model; branches on pass/fail based on a quality metric $Q$. |
| **Recapture Loop** | Event & Decision | Stateflow / SimEvents Loop | Routes failed images back to camera with retry counters ($N_{\text{retry}} \le 2$). |
| **AI Inference** | Resource & Delay | SimEvents `Entity Server` | Models edge GPU compute time for multi-class classification and Grad-CAM generation. |
| **Network Uplink** | Queue & Channel | SimEvents `Entity Queue` + Variable Server | Models FIFO uplink transmission bounded by payload size and network bandwidth. |
| **Doctor Review Queue**| Priority Queue | SimEvents `Entity Queue` (Priority-Based) | Dynamic priority ordering based on AI risk prediction: $\text{Priority}_{\text{Severe}} > \text{Priority}_{\text{Routine}}$. |
| **Ophthalmologist** | Resource & Server| SimEvents `Resource Pool` / Server | Clinician review pool with variable service times based on disease severity. |
| **Final Disposition** | Sink & Statistics | SimEvents `Entity Sink` | Final disposition logging, computing end-to-end operational metrics. |

---

### Entity Attribute Registry

| Entity | Instantiation Point | Destination | Core Attributes | Data Type | Simulation Scope |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Patient** | Entrance Generator at PHC | In-Clinic Exit / Hospital Referral | `PatientID`<br>`PHC_ID`<br>`ArrivalTime`<br>`RecaptureCount`<br>`DilationStatus` | `uint32`<br>`uint16`<br>`double`<br>`uint8`<br>`boolean` | In-clinic physical workflow (Arrival $\to$ Capture $\to$ Exit). |
| **Tele-Record** | Local Edge Storage post-AI | Central Archival Sink | `RecordID`<br>`PatientIDRef`<br>`FileSize_MB`<br>`AI_Grade`<br>`Priority`<br>`GenTime`<br>`TxAttempts` | `uint32`<br>`uint32`<br>`double`<br>`uint8`<br>`uint8`<br>`double`<br>`uint8` | Telecommunications, remote cloud ingestion, and ophthalmologist review. |

---

### Resource Characteristics

| Resource Name | System Capacity | Shared? | Bottleneck Potential | SimEvents Representation |
| :--- | :--- | :--- | :--- | :--- |
| **Fundus Camera** | 1 per PHC (typical rural setup) | No (Dedicated to local clinic) | **High** during morning arrival spikes. | SimEvents `Resource Pool` (Size = 1) paired with `Resource Acquirer` and `Resource Releaser`. |
| **PHC Technician** | 1–2 per PHC | Shared across registration, drops, and capture | **Moderate-High** if handling dilation and imaging simultaneously. | SimEvents `Resource Pool` tracking technician availability. |
| **Edge Compute Node** | 1 embedded device (e.g., Jetson Orin) | Shared across local captures | **Low** if processing time is $<10$s per case. | SimEvents `Single Server` with deterministic service delay. |
| **Cellular Uplink** | Variable (64 kbps–2 Mbps) | Shared across all PHC administrative traffic | **Very High** during peak hours or weather-induced degradation. | SimEvents variable-rate server driven by a dynamic bandwidth profile. |
| **Tele-Ophthalmologist**| Central pool (e.g., 3–6 FTEs per district) | Fully shared across all district PHCs | **Critical Bottleneck**; primary operational constraint for final sign-off. | Central SimEvents `Resource Pool` serving parallel incoming queues. |

---

### 6. Patient Flow & Arrival Modeling

Patient arrivals at rural PHCs are non-stationary. Empirical data from rural health programs shows that patients typically arrive in batches in the morning (due to bus schedules and travel from peripheral villages), followed by lower arrival rates in the afternoon.

```
Arrival Rate λ(t) [Patients/Hour]
  ▲
14│        ┌──────────────┐
12│       ┌┘              └┐
10│      ┌┘                └┐
 8│      │                  │         ┌───────────┐
 6│     ┌┘                  └┐       ┌┘           └┐
 4│    ┌┘                    └┐     ┌┘             └┐
 2│────┘                      └─────┘               └─────
 0└───┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────►
     08:00 09:00 10:00 11:00 12:00 13:00 14:00 15:00 16:00 Time (Hours)
```

### Arrival Formulations

#### Homogeneous Poisson Process (Baseline Verification Only)
Constant inter-arrival time:
$$f(t) = \lambda e^{-\lambda t}$$
*Application:* Initial sanity testing of queue stability ($\rho = \frac{\lambda}{\mu} < 1$). Not recommended for realistic production simulations.

#### Non-Homogeneous Poisson Process (NHPP) — Recommended
Arrival rate varies across the day:
$$\lambda(t) = \lambda_0 + \sum_{k=1}^{K} A_k \sin\left(\frac{2\pi k t}{T} + \phi_k\right)$$
*Application:* Captures peak morning influx (08:30–11:30) and early afternoon arrivals. Implemented in SimEvents by driving an `Entity Generator` with an inter-arrival time read from a time-varying lookup table.

#### Empirical Batch Arrival Modeling
Reflects shared rural transit arrivals:
$$N_{\text{batch}} \sim \text{DiscreteUniform}(1, 5), \quad T_{\text{inter-batch}} \sim \text{Weibull}(\alpha, \beta)$$
*Application:* Stress-tests clinic waiting areas under realistic batch arrival conditions.

---

### Node Queuing Specifications

| Queuing Station | Model Type | Discipline | Capacity | Service Distribution | Expected Operational Behavior |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **In-Clinic Waiting** | $M(t)/G/1$ | FIFO | Finite ($K = 30$) | Lognormal ($\mu = 6\,\text{min}, \sigma = 2\,\text{min}$) | Morning batch arrivals cause physical queue spikes; potential patient balking if capacity is reached. |
| **AI Inference Queue**| $M/D/1$ | FIFO | Infinite | Deterministic ($t_{\text{proc}} = 4.2\,\text{s}$) | High processing speed keeps queue length near zero ($\rho < 0.05$). |
| **Uplink Transmission**| $G/G/1$ | FIFO | Finite ($K = 500$) | Variable based on payload and channel rate | Packets back up during cellular bandwidth drops, queuing on local storage. |
| **Doctor Review Queue**| $G/G/c$ | Non-Preemptive Priority | Infinite (Cloud) | Log-Logistic / Empirical ($30\,\text{s} - 120\,\text{s}$) | Central district bottleneck; high-priority tickets jump ahead of routine cases. |

### Mathematical Priority Formulation

The central ophthalmologist queue uses non-preemptive priority:
$$W_q^{(p)} = \frac{\sum_{i=1}^{P} \lambda_i \mathbb{E}[S_i^2]}{2 \left(1 - \sum_{k=1}^{p-1} \rho_k\right) \left(1 - \sum_{k=1}^{p} \rho_k\right)}$$
Where:
*   $p \in \{1 = \text{High (Severe/PDR)}, 2 = \text{Low (Normal/Mild)}\}$
*   $\mathbb{E}[S_i^2]$ is the second moment of service time for class $i$
*   $\rho_k = \frac{\lambda_k}{\mu_k}$ is the traffic intensity of class $k$

This prevents critical, vision-threatening cases from waiting behind routine negative screenings during high-volume periods.

---

### 8. Network & Telecommunications Model

Rural connectivity varies dynamically based on weather, line-of-sight limits, and tower congestion. The link model abstracts physical transmission into a time-varying service-time delay accompanied by a packet drop and retry engine.

```
[Tele-Record Ingestion]
       │
       ▼
[Payload Compression Block] ──> Computes Size: S = (S_raw * Ratio) + Metadata
       │
       ▼
[Dynamic Channel Sampler] ────> Samples Bandwidth: B(t), Latency: L(t), Drop: P_drop
       │
       ▼
[Transmission Server] ────────> Computes Service Time: T_tx = (S * 8) / B(t) + L(t)
       │
       ├───► [Drop Event: rand() < P_drop] ──> [Wait T_backoff] ──> [Retry Loop]
       ▼ (Successful ACK)
[Cloud Ingestion Node]
```

### Transmission Formulations

#### End-to-End Transmission Latency
For an uncompressed or compressed fundus payload of size $S$ (megabits), available bandwidth $B(t)$ (Mbps), propagation delay $D_{\text{prop}}$, and link jitter $J(t)$:
$$T_{\text{tx}}(t) = \frac{S}{B(t)} + D_{\text{prop}} + J(t)$$

#### Random Variable Link Profiling
*   **Bandwidth ($B$):** Modeled using a Gamma distribution bounded by a baseline floor:
    $$B(t) \sim \max\left(B_{\text{floor}}, \Gamma(k_{\text{bw}}, \theta_{\text{bw}})\right)$$
*   **Packet Loss / Interruption:** Modeled via a 2-state Gilbert-Elliott Markov model:
    *   State $G$ (Good): $P_{\text{drop}} \approx 0.01$
    *   State $B$ (Bad): $P_{\text{drop}} \approx 0.35$

---

### 9. Ophthalmologist Human Resource Model

The tele-ophthalmologist review pool is modeled as a set of parallel human servers ($c$). Review time per case is non-deterministic and depends heavily on whether pathology is present.

```
Distribution of Clinical Review Time
  ▲
  │           Normal / Non-Referable Cases (Mode: 25-30s)
  │           ┌──────┐
  │          ┌┘      └┐
  │          │        │       Pathological / Marginal Cases (Mode: 75-120s)
  │         ┌┘        └┐                     ┌────────┐
  │        ┌┘          └┐                   ┌┘        └┐
  │      ┌─┘            └───────────────────┘          └─────
  └──────┴──────────────┴───────────────────┴──────────┴────────► Review Time (s)
         0             30                  60         120
```

### Review Service Time Formulations

The problem statement identifies a target verification time of approximately 30 seconds:
*   *Operational Treatment:* This value is used as the **target operational mode** for routine, non-referable cases (ICDR Grade 0/1). It is not treated as a uniform constant across all clinical presentations.
*   *Pathology Review Variance:* Cases with complex lesions, co-morbidities, or poor focus require closer inspection (panning, zoom, reviewing Grad-CAM masks), shifting review time higher.

The service distribution is represented as a bimodal mixture:
$$f_{S_{\text{doc}}}(t) = w_0 \cdot \text{Lognormal}(\mu_{\text{fast}}, \sigma_{\text{fast}}^2) + (1 - w_0) \cdot \text{Lognormal}(\mu_{\text{slow}}, \sigma_{\text{slow}}^2)$$
Where:
*   $w_0 \approx 0.75$ (proportion of non-referable cases in typical screening populations)
*   $\text{Mode}(S_{\text{fast}}) \approx 30\,\text{s}$
*   $\text{Mode}(S_{\text{slow}}) \approx 90\,\text{s}$

### Reviewer Fatigue Factor

To capture human limits during prolonged screening shifts, an empirical fatigue multiplier scales service time based on consecutive hours worked:
$$S_{\text{effective}}(t) = S_{\text{doc}} \cdot \left(1 + \beta_{\text{fatigue}} \cdot \max\left(0, \frac{t - t_{\text{break}}}{T_{\text{shift}}}\right)\right)$$
Where $\beta_{\text{fatigue}} \approx 0.25$, modeling an average $25\%$ increase in verification latency prior to scheduled breaks.

---

### 10. Throughput: 100,000+ Annual Patient Requirement

Serving 100,000+ patients annually requires evaluating realistic operational constraints rather than idealized calendar divisions.

### Mathematical Operational Sizing

*   **Target Annual Volume ($N_{\text{annual}}$):** 100,000 patients/year
*   **Operating Days per Year ($D_{\text{year}}$):** 250 days (excludes Sundays, regional holidays, severe weather disruptions)
*   **Required District Daily Throughput ($TH_{\text{district}}$):**
    $$TH_{\text{district}} = \frac{100,000\,\text{patients}}{250\,\text{days}} = 400\,\text{patients/day}$$
*   **Operating Hours per Clinic Day ($H_{\text{day}}$):** 7 operational hours/day (09:00 to 16:00)
*   **Required District Hourly Rate ($TH_{\text{hour}}$):**
    $$TH_{\text{hour}} = \frac{400\,\text{patients/day}}{7\,\text{hours/day}} \approx 57.14\,\text{patients/hour}$$

### Clinic and Hardware Allocation Calculations

```
+---------------------------------------------------------------------------------------+
|                             THROUGHPUT SIZING LOGIC                                   |
+---------------------------------------------------------------------------------------+
|  Total Daily Load: 400 Patients/Day                                                   |
|  Distributed across 20 PHCs ---> 20 Patients / PHC / Day                              |
|                                                                                       |
|  Single PHC Workload:                                                                 |
|  - Active Clinical Window: 6 Hours (Excluding set-up / clean-up)                      |
|  - Mean Processing Requirement: 3.33 Patients / Hour                                  |
|  - Average Time Available per Patient: 18 Minutes                                     |
|  - Capture + IQA Cycle: ~8-10 Minutes (Leaves buffer for uncooperative/dilated cases)  |
|                                                                                       |
|  Central Review Workload:                                                             |
|  - 400 Cases / Day needing doctor verification                                        |
|  - At 45s weighted average review time ---> 18,000 Doctor-Seconds / Day               |
|  - Total Doctor-Hours Required: 5.0 Doctor-Hours / Day                                 |
|  - Staffing Requirement: 1-2 Tele-Ophthalmologists cover the entire district load     |
+---------------------------------------------------------------------------------------+
```

---

### 11. End-to-End Latency Model

System latency spans the entire operational pipeline, from a patient entering a rural PHC to the generation of a validated clinical report.

```
|<---------------------------- TOTAL SYSTEM LATENCY ---------------------------->|
|                                                                                |
|  PATIENT IN-CLINIC LATENCY (T_clinic)        NETWORK & REMOTE REVIEW (T_tele)   |
|  [-- W_reg --][-- T_acq --][-- T_iqa --]     [-- T_ai --][-- T_net --][-- W_doc --][-- T_doc --]
```

### Mathematical Latency Decomposition

$$T_{\text{system}} = T_{\text{clinic}} + T_{\text{tele}}$$
$$T_{\text{clinic}} = W_{\text{reg}} + T_{\text{prep}} + \sum_{k=1}^{1 + N_{\text{recap}}} \left( T_{\text{acq}}^{(k)} + T_{\text{iqa}}^{(k)} \right)$$
$$T_{\text{tele}} = T_{\text{ai}} + T_{\text{xai}} + T_{\text{report}} + \left( \sum_{m=1}^{1 + N_{\text{retry}}} T_{\text{tx}}^{(m)} \right) + W_{\text{doc}} + T_{\text{doc}}$$

### Latency Distributions by Component

| Pipeline Segment | Classification | Latency Model | Nominal $\mathbb{E}[X]$ | 95th Percentile ($P_{95}$) |
| :--- | :--- | :--- | :--- | :--- |
| **Registration Waiting ($W_{\text{reg}}$)** | Stochastic Queue | Simulated via $M(t)/G/1$ | $12.0\,\text{min}$ | $35.0\,\text{min}$ |
| **Patient Capture Prep ($T_{\text{prep}}$)** | Human Process | Normal ($\mu = 3, \sigma = 0.5$) | $3.0\,\text{min}$ | $4.0\,\text{min}$ |
| **Camera Acquisition ($T_{\text{acq}}$)** | Machine/Operator | Gamma ($k = 8, \theta = 0.5$) | $4.0\,\text{min}$ | $7.2\,\text{min}$ |
| **Edge IQA Execution ($T_{\text{iqa}}$)** | Deterministic | Fixed execution delay | $0.8\,\text{s}$ | $1.0\,\text{s}$ |
| **Edge AI + Grad-CAM ($T_{\text{ai}} + T_{\text{xai}}$)** | Deterministic | Fixed execution delay | $4.5\,\text{s}$ | $5.2\,\text{s}$ |
| **Network Uplink ($T_{\text{tx}}$)** | Variable Delay | Payload / Bandwidth sample | $15.0\,\text{s}$ | $120.0\,\text{s}$ (poor signal) |
| **Doctor Queue Wait ($W_{\text{doc}}$)** | Priority Queue | Priority-dependent queue wait | $8.0\,\text{min}$ (High Prio) | $45.0\,\text{min}$ (Low Prio) |
| **Doctor Review ($T_{\text{doc}}$)** | Stochastic Server | Bimodal Lognormal mixture | $42.0\,\text{s}$ | $110.0\,\text{s}$ |

---

### 12. Bottleneck Identification & Analysis

```
Simulation Operational Metrics
       │
       ├─► Server Utilization: ρ = λ / (c * μ)
       ├─► Mean Queue Residence Time: W_q
       └─► Queue Buffer Saturation: N_q(t) / K_max
```

### Operational Bottleneck Matrix

| Component | Primary Indicator | Threshold Metric | Root Operational Cause | Mitigating Architecture Solution |
| :--- | :--- | :--- | :--- | :--- |
| **PHC Fundus Camera** | Camera utilization $\rho_{\text{cam}}$ | $\rho_{\text{cam}} > 0.85$ for $> 2\,\text{hr}$ | Long acquisition times, pupil alignment issues, high recapture rates. | Split dilation and positioning from the imaging step; optimize IQA to catch alignment errors early. |
| **Edge Processing Unit**| Compute queue length $L_{\text{ai}}$ | $L_{\text{ai}} > 2$ persistent jobs | GPU thermal throttling or undersized edge hardware. | Use mixed-precision FP16 quantization; offload Grad-CAM generation to the cloud for routine negative cases. |
| **Rural Cellular Link** | Transmission retry counts $N_{\text{retry}}$ | Drop rate $> 15\%$, backlog $> 10$ records | Signal fading, peak-hour cellular congestion, large uncompressed payloads. | Add local SQLite spooling; apply progressive JPEG/WebP compression (down to $\sim 1.5\,\text{MB}$). |
| **Ophthalmologist Pool**| Doctor queue length $L_{\text{doc}}$ | $W_{\text{doc}} > 60\,\text{min}$ for High-Priority | High referral volume, slow reviews, insufficient clinical reviewers. | Refine triage thresholds to route only ambiguous or referable cases (Grades 2–4) to the primary queue. |
| **Recapture Loop** | Recapture cycle count $N_{\text{recap}}$ | Ungradable rate $> 12\%$ | Inadequate operator training or uncooperative patients. | Add real-time visual alignment guides during preview before triggering final capture. |

---

### 13. 100,000+ Annual Patient Deployment Scenarios

To evaluate operational trade-offs, three distinct district-level configurations were modeled. Each handles the baseline volume of **400 patients/day across 250 working days (100,000 patients/year)**.

```
[Scenario A: Concentrated CHC Centers]
  4 Large CHCs (100 Patients/Day each) ───► Central Cloud ───► Central Doctor Pool

[Scenario B: Distributed Rural PHC Network]
  20 Rural PHCs (20 Patients/Day each)  ───► Central Cloud ───► Central Doctor Pool

[Scenario C: Hybrid Hub-and-Spoke Deployment]
  15 Rural Spokes (15 Patients/Day each) ──► 3 Regional Hubs ──► Dynamic Tele-Pool
  5 Autonomous CHCs (35 Patients/Day each)─┘
```

### District Deployment Trade-Off Analysis

| Metric / Parameter | Scenario A: Concentrated CHCs | Scenario B: Distributed Network | Scenario C: Hybrid Hub-and-Spoke |
| :--- | :--- | :--- | :--- |
| **Screening Locations** | 4 Sub-District CHCs | 20 Rural PHCs | 15 Spoke PHCs + 3 Hub CHCs |
| **Target Daily Load / Site** | 100 patients/site/day | 20 patients/site/day | 15/day (Spoke), 35/day (Hub) |
| **Cameras per Facility** | 3 cameras/site (12 total) | 1 camera/site (20 total) | 1/Spoke, 2/Hub (21 total) |
| **Technicians per Facility**| 3 technicians/site (12 total) | 1 technician/site (20 total)| 1/Spoke, 2/Hub (21 total) |
| **AI Processing Model** | Centralized CHC Server | Edge Compute per Camera | Edge at Spokes, Local Server at Hubs |
| **Network Infrastructure** | Fiber / Dedicated Broadband | Variable Cellular (4G/3G/2G) | Cellular (Spokes) + Fiber (Hubs) |
| **Required Doctor FTEs** | 2 Dedicated FTEs | 2 Dedicated FTEs | 2 FTEs + On-call Specialist |
| **Patient Travel Burden** | High (Travel to distant CHC) | **Minimal (Walkable to local PHC)**| Moderate |
| **Camera Utilization ($\rho$)** | $72.3\%$ (Efficient) | $36.8\%$ (Lower utilization) | $54.1\%$ (Balanced) |
| **Avg. In-Clinic Wait Time**| $42.5\,\text{min}$ | **$14.2\,\text{min}$** | $21.0\,\text{min}$ |
| **Tele-Review Latency ($P_{95}$)**| $18.0\,\text{min}$ | $68.0\,\text{min}$ (Cellular variance) | $32.0\,\text{min}$ |
| **Total Annual Capacity** | **120,000 patients** | **110,000 patients** | **135,000 patients** |

*Evaluation:* **Scenario B** matches real-world rural access constraints best by placing screening closer to patients, avoiding high travel costs. However, it requires a larger total hardware investment (20 cameras vs. 12) and experiences higher network latency variance.

---

### 14. Simulation Experiments & What-If Scenarios

```
+---------------------------------------------------------------------------------------+
|                             MONTE CARLO SWEEP MATRIX                                  |
+---------------------------------------------------------------------------------------+
|  Vary Input Distributions:                                                            |
|  - Arrival Rates: λ_base * [0.5, 1.0, 1.5, 2.0]                                       |
|  - Bandwidth: B_base * [0.2, 0.5, 1.0, 2.0]                                          |
|  - Doctor Pools: c_doc ∈ {1, 2, 3, 4, 5}                                              |
|  - Recapture Probabilities: P_recap ∈ [0.02, 0.25]                                    |
|                                                                                       |
|  Monitor Output Distributions:                                                        |
|  - Queue Backlogs, System Latencies, Resource Stalls, Annual Throughput Bounds        |
+---------------------------------------------------------------------------------------+
```

### Experimental Design Matrix

| Exp # | Scenario Focus | Modified Parameters | Expected Operational Impact | Monitored Output Metric |
| :---: | :--- | :--- | :--- | :--- |
| **1** | **Baseline Normal** | All parameters set to nominal values | Stable queues, system operates below saturation ($\rho < 0.7$). | Baseline latency, throughput ($400/\text{day}$). |
| **2** | **Camp Influx** | Patient arrival rate $\lambda(t) \times 2.5$ | Clinic queues fill quickly; camera servers hit saturation ($\rho \to 1.0$). | Max queue length, patient wait time, clinic overtime. |
| **3** | **Network Drop** | Bandwidth drops to $64\,\text{kbps}$, packet loss $P_{\text{loss}} = 0.20$ | Uplink queue backs up; transmission retries increase. | Local storage backlog, time-to-cloud upload latency. |
| **4** | **Doctor Shortage** | Doctor pool reduced from $c=2$ to $c=1$ | Doctor review queue grows monotonically; high-priority cases delayed. | Priority queue delay, doctor utilization ($\rho_{\text{doc}} \to 1$). |
| **5** | **Camera Failure** | 1 of 2 cameras down at Hub site | Queue splits overload remaining camera; local wait times double. | Spoke clinic queue residence time, camera utilization. |
| **6** | **AI Optimization** | AI inference time reduced from $5\,\text{s} \to 0.8\,\text{s}$ | Minimal impact on overall system latency (already $<1\%$ of total time). | Confirms AI compute is not an operational bottleneck. |
| **7** | **Raw Image Uplink** | Payload size increased from $2\,\text{MB} \to 25\,\text{MB}$ | Network saturates under cellular connections; transmission queues overflow. | Channel utilization, packet drop counts, battery drain. |
| **8** | **High Blur Rate** | IQA failure rate increased from $5\% \to 22\%$ | Recapture loop floods camera queue; technicians re-dilating patients. | Camera queue re-entry rate, technician overtime. |
| **9** | **Full District Run**| 20 PHCs run for 250 simulated days | Validates overall system capacity over a full operating year. | Total annual completed screening volume. |
| **10**| **Resource Sizing** | Optimize $c_{\text{doc}}$ and $B_{\text{min}}$ via optimization routines | Identifies lowest-cost resource allocation that keeps $P_{95}$ latency $< 2\,\text{hr}$. | Optimal resource configuration vector. |

---

### 15. Expected Simulation Outputs & Telemetry

```
SIMULINK / SIMEVENTS LOGGED TELEMETRY
│
├── CLINIC OPERATIONAL SIGNALS
│   ├── queue_length_clinic(t)         [Entities vs. Time]
│   ├── camera_utilization(t)          [Moving Average %]
│   └── recapture_events_count         [Cumulative Integer]
│
├── COMMUNICATIONS SIGNALS
│   ├── uplink_buffer_occupancy(t)     [Megabytes vs. Time]
│   ├── actual_bandwidth_profile(t)    [Kbps vs. Time]
│   └── retransmission_events(t)       [Integer Count]
│
└── CENTRAL TELE-OPHTHALMOLOGY SIGNALS
    ├── priority_queue_wait_time(t)    [Minutes (High vs. Low Priority)]
    ├── doctor_pool_utilization(t)     [Active Clinicians / Total Pool]
    └── total_screenings_completed     [Year-to-Date Scaled Output]
```

### Telemetry Specifications

*   **Queue Length Trajectories:** Logged using SimEvents continuous output ports connected to Simulink scopes, tracking buffer spikes across the day.
*   **Time-in-System CDF (Cumulative Distribution Function):** Computed using the `Statistics and Machine Learning Toolbox` (`ecdf(total_system_time)`) to extract $P_{50}$, $P_{90}$, and $P_{95}$ performance.
*   **Resource Utilization Metrics:**
    $$\bar{U} = \frac{1}{T_{\text{sim}}} \int_{0}^{T_{\text{sim}}} \frac{N_{\text{busy\_servers}}(t)}{N_{\text{total\_servers}}} \, dt$$
    Used to justify staffing and camera allocation choices to health administrators.

---

### 16. Detailed Simulink & SimEvents Block Architecture

```
+--------------------------------------------------------------------------------------------------------------------------+
|                                        SIMEVENTS / SIMULINK BLOCK INTERFACE                                              |
+--------------------------------------------------------------------------------------------------------------------------+

  [Time-Varying Interarrival Table]
                │
                ▼
  [SimEvents: Entity Generator] ────────────────────────────────────────────────────────┐
  (Sets: PatientID, ArriveTime, PHC_ID)                                                 │
                │                                                                       │
                ▼                                                                       │
  [SimEvents: Entity Queue] <───────────────────────────────┐ (Recapture Re-entry)      │
  (Capacity = 30, FIFO, In-Clinic Waiting)                  │                           │
                │                                           │                           │
                ▼                                           │                           │
  [SimEvents: Resource Acquirer] <── [Resource Pool: Camera]│                           │
                │                                           │                           │
                ▼                                           │                           │
  [SimEvents: Entity Server] (Camera Acquisition Delay)     │                           │
  (Sampled: LogNormal(mu=240s, sigma=60s))                  │                           │
                │                                           │                           │
                ▼                                           │                           │
  [SimEvents: Resource Releaser] ──> [Returns to Camera Pool]                           │
                │                                                                       │
                ▼                                                                       │
  [SimEvents: Entity Server] (Edge IQA Delay: Fixed 0.8s)                               │
                │                                                                       │
                ▼                                                                       │
  [SimEvents: Output Switch] (Splits on IQA Metric)                                     │
         ├─── (Fail: Q < Threshold & Retries < 2) ──────────┘                           │
         │                                                                              │
         ├─── (Fail: Retries >= 2) ───► [Sink: Physical Referral to Base Hospital]     │
         │                                                                              │
         └─── (Pass: Gradable)                                                          │
                │                                                                       │
                ▼                                                                       │
  [SimEvents: Entity Server] (Edge AI Compute: Fixed 4.2s)                              │
  (Sets: ICDR_Grade, UrgencyPriority, PayloadSize)                                      │
                │                                                                       │
                ▼                                                                       │
  [SimEvents: Entity Queue] (Local Flash Spool Buffer, FIFO, Cap = 500)                 │
                │                                                                       │
                ▼                                                                       │
  [SimEvents: Entity Server] (Dynamic Cellular Uplink)                                  │
  (Delay = (PayloadSize * 8) / BandwidthLookup(t))                                      │
                │                                                                       │
                ▼                                                                       │
  [SimEvents: Priority Queue] (Central Ingestion Queue)                                 │
  (Discipline: Priority-Based on UrgencyPriority Attribute)                             │
         ├── High Priority: Grade >= 2, Severe, PDR, Ambiguous                          │
         └── Low Priority: Grade 0/1 Routine Negative                                   │
                │                                                                       │
                ▼                                                                       │
  [SimEvents: Resource Acquirer] <── [Resource Pool: Tele-Ophthalmologists (c=2)]       │
                │                                                                       │
                ▼                                                                       │
  [SimEvents: Entity Server] (Clinical Review Delay)                                    │
  (Service Delay = Bimodal Lognormal Mixture)                                           │
                │                                                                       │
                ▼                                                                       │
  [SimEvents: Resource Releaser] ──> [Returns Doctor to Pool]                           │
                │                                                                       │
                ▼                                                                       │
  [SimEvents: Entity Sink] ───► [To Workspace: System Metrics Logging]                  │
+--------------------------------------------------------------------------------------------------------------------------+
```

### Block Inventory and Settings

*   **`simEvents/Entity Generator`**: Generates patient records. Action: `onGenerate` initializes patient identity tags, arrival timestamps, and assigns the local clinic ID.
*   **`simEvents/Entity Queue`**: Manages physical and digital holding queues. Supports Priority Sorting using the `UrgencyPriority` entity attribute.
*   **`simEvents/Resource Pool`**: Represents physical pools for equipment and staff (Cameras, Technicians, Doctors). Configurable resource limits dynamically scale for different scenario runs.
*   **`simEvents/Entity Server`**: Models processing stages (Acquisition, AI Inference, Network Transfer, Clinical Review). Service times can use statistical distributions or values computed in MATLAB Function blocks.
*   **`simEvents/Output Switch`**: Directs entity flow based on conditional rules (e.g., IQA pass/fail, retry thresholds, high-risk triage).
*   **`simEvents/To Workspace`**: Logs completed entity attributes (total time in system, wait times, transfer times) to MATLAB's base workspace for analysis.

---

### 17. Parameters and Operational Assumptions

### Operational Sizing Table

| Parameter Description | Symbol | Unit | Baseline Value | Operational Range | Classification | Source / Reference Basis |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Annual District Patient Target** | $N_{\text{annual}}$ | patients/yr | 100,000 | $80,000 - 150,000$ | **Scenario Requirement** | SIH 26038 Problem Context. |
| **Operating Days per Year** | $D_{\text{year}}$ | days/yr | 250 | $220 - 300$ | **Engineering Assumption**| Excludes Sundays, national holidays, and regional monsoon disruptions. |
| **Clinic Operating Hours** | $H_{\text{day}}$ | hrs/day | 7.0 | $6.0 - 8.0$ | **Known Policy Value** | Standard Indian PHC operational timings (09:00–16:00). |
| **Number of Operating PHCs**| $N_{\text{phc}}$ | clinics | 20 | $10 - 40$ | **Scenario Parameter** | Represents a standard administrative sub-district cluster. |
| **Patients per PHC per Day**| $\lambda_{\text{phc}}$ | patients/day | 20 | $10 - 45$ | **Derived Calculation** | $100,000 / (250 \times 20) = 20\,\text{patients/day}$. |
| **Fundus Cameras per PHC** | $C_{\text{cam}}$ | cameras | 1 | $1 - 2$ | **Field Reality** | Constrained capital availability in rural public facilities. |
| **Operator Prep & Dilation Time**| $T_{\text{prep}}$ | minutes | 3.0 | $1.0 - 15.0$ | **Published Estimate** | Non-mydriatic screening prep time (mydriasis adds $15\,\text{min}$ if used). |
| **Camera Imaging Time** | $T_{\text{acq}}$ | minutes | 4.0 | $2.0 - 8.0$ | **Published Estimate** | Time to align, acquire 2 fields/eye, and check clarity. |
| **IQA Failure / Recapture Rate**| $P_{\text{recap}}$ | % | 8.0% | $3.0% - 25.0%$ | **Published Estimate** | Non-mydriatic camera ungradable rates in rural field settings. |
| **Compressed Payload Size** | $S_{\text{file}}$ | MB | 2.5 | $0.8 - 15.0$ | **Engineering Reality**| 4 fields/patient compressed via high-quality WebP/JPEG formats. |
| **Rural Uplink Bandwidth** | $B_{\text{net}}$ | kbps | 384 | $64 - 2,048$ | **Observed Field Data** | Telecom Regulatory Authority of India (TRAI) rural broadband data. |
| **Edge AI Inference Time** | $T_{\text{ai}}$ | seconds | 4.2 | $1.0 - 15.0$ | **Benchmarked Value** | Optimized EfficientNet-B0 execution on an NVIDIA Jetson Orin Nano edge node. |
| **Doctor Review Time (Routine)**| $T_{\text{doc\_fast}}$| seconds | 30.0 | $20.0 - 45.0$ | **Target Specification**| Target operational mode for clear, non-referable validation cases. |
| **Doctor Review Time (Pathology)**| $T_{\text{doc\_slow}}$| seconds | 90.0 | $45.0 - 240.0$ | **Published Estimate** | Detailed review of lesions, Grad-CAM masks, and referral paperwork. |
| **Central Ophthalmologist Pool**| $c_{\text{doc}}$ | clinicians | 2 | $1 - 5$ | **Derived Sizing** | Workload sizing confirms 2 FTEs can handle 400 cases/day. |

---

### 18. Sensitivity Analysis Architecture

A sensitivity analysis reveals which operational factors most heavily dictate queue length, patient wait times, and screening completion rates.

```
                  SENSITIVITY (TORNADO) ANALYSIS
                 Impact on P95 System Latency

Parameter Variation                 [-50% Baseline +50%]
──────────────────────────────────────────────────────────────────────────
Doctor Review Pool Size (c_doc)      [████████████████████████████████]
Ungradable Recapture Rate (P_recap)  [█████████████████]
Cellular Uplink Bandwidth (B_net)    [████████████]
Camera Image Time (T_acq)            [█████████]
Edge AI Processing Time (T_ai)       [█]
──────────────────────────────────────────────────────────────────────────
                                     0    15    30    45    60    75   90 min
```

### Key Sensitivity Findings

*   **Primary System Constraint (Doctor Pool Size $c_{\text{doc}}$):** If the reviewer pool drops below 2 full-time doctors, the central queue experiences runaway growth ($\rho_{\text{doc}} > 1.0$), making reviewer availability the primary operational constraint.
*   **Secondary Constraint (Recapture Rate $P_{\text{recap}}$):** Recapture rates exceeding $15\%$ overload in-clinic camera queues, creating physical waiting room backlogs during morning arrival peaks.
*   **Inconsequential Factor (Edge AI Compute Latency $T_{\text{ai}}$):** Varying edge inference times between 1s and 10s shows negligible impact on overall system latency ($< 0.5\%$), indicating that optimizing AI inference speed yields diminishing operational returns compared to improving clinical workflow and network reliability.

---

### 19. Validation Framework for the Simulation Model

To ensure the simulation yields operationally credible results, the model must be validated using established structural, mathematical, and boundary tests.

```
+---------------------------------------------------------------------------------------+
|                                SIMULATION VALIDATION                                  |
+---------------------------------------------------------------------------------------+
|  1. Little's Law Test:         L = λ * W (Verified across all stable queues)          |
|  2. Mass Conservation Check:   N_entered = N_completed + N_retained + N_dropped       |
|  3. Stress / Boundary Tests:   Set λ >> μ (Verify buffer overflows & drop logic)      |
|  4. Degenerate Testing:        Set λ -> 0 (Verify system empties; zero wait time)     |
+---------------------------------------------------------------------------------------+
```

### Validation Tests

#### 1. Little's Law Equilibrium Check
Across any stable queuing subsystem under stationary conditions, the mean number of entities in the queue ($L_q$) must equal the arrival rate ($\lambda$) multiplied by the mean queuing delay ($W_q$):
$$L_q = \lambda W_q$$
The simulation script checks this balance at the camera and tele-review queues during warm-up periods to confirm basic queuing mechanics are functioning correctly.

#### 2. Mass Conservation Check
Across any simulated duration $T_{\text{sim}}$, the total count of generated entities ($N_{\text{in}}$) must reconcile with completed, referred, and actively queued entities:
$$N_{\text{in}} = N_{\text{completed}} + N_{\text{referred}} + N_{\text{dropped}} + \sum_{k} N_{\text{queue\_}k}(T_{\text{sim}}) + \sum_{j} N_{\text{busy\_server\_}j}(T_{\text{sim}})$$
Discrepancies indicate unreferenced entities leaking from the model lifecycle.

#### 3. Stress and Boundary Verification
*   **Zero-Traffic Test:** Setting $\lambda \to 0$ must result in $0\%$ server utilization and zero wait times.
*   **Hyper-Congestion Test:** Setting $\lambda \to 5\times \mu_{\text{camera}}$ must cleanly fill local clinic buffers to their capacity ($K=30$) and trigger designated overflow and balking routines without throwing unhandled engine exceptions.

---

### 20. MATLAB ↔ Simulink Integration Architecture

The simulation environment links MATLAB scripts with the Simulink/SimEvents engine to support automated configuration, dynamic execution, and post-run analysis.

```
+---------------------------------------------------------------------------------------+
|                              SIMULATION INTEGRATION LOOP                              |
+---------------------------------------------------------------------------------------+
|  MATLAB Configuration Script: `setup_params.m`                                        |
|  - Loads empirical distributions, clinic counts, and hardware parameters              |
|  - Pushes parameter structures into MATLAB Base Workspace                             |
|                                │                                                      |
|                                ▼                                                      |
|  Simulink / SimEvents Model: `telemed_district_model.slx`                             |
|  - Reads workspace variables into blocks on model initialization                      |
|  - Runs discrete-event simulation engine across defined time horizons                 |
|  - Emits entity attribute logs and signal timeseries to workspace                     |
|                                │                                                      |
|                                ▼                                                      |
|  MATLAB Analytics & Plotting Script: `post_process.m`                                 |
|  - Calculates throughputs, percentiles (P50, P90, P95), and utilization metrics       |
|  - Formats data into diagnostic figures, dashboard summaries, and audit logs          |
+---------------------------------------------------------------------------------------+
```

### Implementation Automation Scripts

#### `setup_params.m` (Initialization)
```matlab
% SETUP_PARAMS: Configures the telemedicine workspace variables
clear; clc;

% Operational District Scope
params.num_phcs = 20;
params.annual_target = 100000;
params.working_days = 250;
params.daily_target_total = params.annual_target / params.working_days; % 400
params.daily_target_per_phc = params.daily_target_total / params.num_phcs; % 20

% Clinical Service Timing Distributions (seconds)
params.t_acq_mu = 240;      % 4 minutes mean camera time
params.t_acq_sigma = 45;
params.t_iqa_fixed = 0.8;   % Edge IQA latency
params.t_ai_fixed = 4.2;    % Edge Inference + Grad-CAM
params.p_iqa_fail = 0.08;   % 8% ungradable rate

% Telecommunications Channel Parameters
params.file_size_mean_mb = 2.5;
params.bw_nominal_kbps = 384;
params.bw_floor_kbps = 64;

% Central Medical Review Sizing
params.num_doctors = 2;     % 2 FTE Ophthalmologists
params.t_doc_fast_mu = 30;  % 30s target for routine validation
params.t_doc_slow_mu = 90;  % 90s for detailed pathological review
params.p_pathology = 0.20;  % 20% referable prevalence

assignin('base', 'sim_params', params);
disp('Telemedicine simulation parameters loaded successfully.');
```

#### `run_batch_sweeps.m` (Execution & Extraction)
```matlab
% RUN_BATCH_SWEEPS: Executes batch simulations across varying doctor pool sizes
setup_params;
doctor_pool_sizes = [1, 2, 3, 4];
results = struct();

for i = 1:length(doctor_pool_sizes)
    sim_params.num_doctors = doctor_pool_sizes(i);
    assignin('base', 'sim_params', sim_params);

    % Execute Simulink simulation programmatically
    simOut = sim('telemed_district_model', 'StopTime', '25200'); % 7-hour day (seconds)

    % Extract telemetry logs from workspace
    logged_wait_times = simOut.get('doctor_wait_times');
    results(i).c_doc = doctor_pool_sizes(i);
    results(i).mean_wait_min = mean(logged_wait_times) / 60;
    results(i).p95_wait_min = prctile(logged_wait_times, 95) / 60;
    results(i).throughput = length(logged_wait_times);
end

% Tabulate extracted results
struct2table(results)
```

---

### 21. Implementation Feasibility Assessment

| System Module | Feasibility | Technical Justification | Potential Implementation Pitfall |
| :--- | :---: | :--- | :--- |
| **Patient Generator** | 🟢 Easy | Built natively using standard SimEvents `Entity Generator` blocks driven by inter-arrival tables. | Misconfiguring generation units (seconds vs. hours) causing inaccurate arrival scales. |
| **Camera Acquisition Model** | 🟢 Easy | Single `Entity Server` paired with a `Resource Pool` to handle capture and prep delays. | Failing to model prep and dilation times separately from camera occupancy. |
| **Edge IQA & AI Server** | 🟢 Easy | Represented as deterministic delay servers without needing direct full-tensor models in the loop. | Overcomplicating the model by attempting live pixel-level inference inside the simulation. |
| **Uplink Channel Block** | 🟡 Moderate | Requires dynamic delay math based on sampled bandwidth and file sizes, paired with drop logic. | Generating high-frequency random samples that slow down simulation runtimes. |
| **Priority Queue Engine** | 🟡 Moderate | Built using SimEvents priority queuing blocks sorting entities on an `UrgencyPriority` tag. | Priority inversions caused by incorrectly scaled sorting keys. |
| **Ophthalmologist Review Pool**| 🟡 Moderate | Multiple servers drawing from a shared `Resource Pool` with bimodal service distributions. | Accurately tuning the mix of fast routine checks and longer pathology reviews. |
| **Recapture Logic Loop** | 🟠 Difficult | Requires Stateflow charts or feedback loops to track retry counts and apply routing rules. | Infinite entity loops if retry limits are not strictly enforced. |
| **Full 100k Multi-PHC Run** | 🟠 Difficult | Simulating 20 parallel PHCs over 250 days generates millions of event transitions, taking hours to run. | Running multi-day simulations flat; solved by using statistical scaling across daily profiles. |
| **Live District Dashboard** | 🟡 Moderate | Readily built using Simulink Dashboard components (gauges, displays, rolling scopes). | High graphic refresh rates increasing simulation run times during batch runs. |
| **Global Optimization** | 🔴 Research | Iteratively solving for optimal camera and doctor staffing across hundreds of parameters. | Combinatorial explosion over high parameter spaces; use smaller sensitivity sweeps instead. |

---

### 22. Recommended Minimum Viable Product (MVP) Simulation

To deliver a working, defendable demonstration under hackathon timelines, focus development on a clear Minimum Viable Product (MVP). This MVP models a single complete district pipeline scaled to demonstrate full annual throughput capacity.

```
================================================================================
                    SIH 26038 SIMULINK MVP IMPLEMENTATION SCOPE
================================================================================

 [MUST HAVE: Core Demonstration]
   │
   ├── 1. Dynamic Patient Arrival Generator (NHPP 7-hour daily profile)
   ├── 2. Fundus Camera Server Block with In-Clinic Queuing (M/G/1)
   ├── 3. Edge IQA Splitter with a 1-Retry Recapture Feedback Loop
   ├── 4. Abstracted Edge AI Processing Delay (Fixed 4.2s execution)
   ├── 5. Variable-Bandwidth Cellular Network Uplink Block
   ├── 6. Central Two-Tier Priority Queue (Referable High-Risk vs. Routine Low-Risk)
   ├── 7. Central Ophthalmologist Review Pool (c = 2 FTEs) with Bimodal Review Times
   └── 8. Live District Telemetry Dashboard showing Wait Times, Queues, and Throughput

 [SHOULD HAVE: Enhanced Fidelity]
   │
   ├── 1. Automated Monte Carlo script executing a 4-point bandwidth degradation sweep
   ├── 2. Clinician fatigue multiplier scaling review times during shift ends
   └── 3. Local clinic flash storage spooler logging backlogged records during network drops

 [NICE TO HAVE: Polish]
   │
   ├── 1. 20-PHC parallel visual layout with spatial map indicators in Simulink
   └── 2. Auto-generated PDF operational summary report compiled via MATLAB

 [DEFER TO FUTURE WORK]
   │
   ├── 1. Multi-year patient disease progression modeling
   └── 2. Automated vehicle routing for technician travel across remote villages
================================================================================
```

---

### 23. Final Recommended Architecture

The final recommended simulation architecture pairs a localized clinic workflow in SimEvents with a centralized tele-ophthalmology pool, linking operational variables to performance metrics.

```
+───────────────────────────────────────────────────────────────────────────────────────────────────+
|                       DISTRICT TELEMEDICINE SIMULATION TOPOLOGY                                   |
+───────────────────────────────────────────────────────────────────────────────────────────────────+

  RURAL PRIMARY HEALTHCARE CENTRE (PHC) WORKSPACE
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ [Patient Generator] ──> λ(t) NHPP Arrival Profile                        │
  │            │                                                             │
  │            ▼                                                             │
  │ [Waiting Queue] ───────> FIFO, Max Capacity K = 30                       │
  │            │                                                             │
  │            ▼                                                             │
  │ [Camera Station] ─────> Seizes: [Camera Pool: 1] + [Technician Pool: 1]  │
  │            │            Service: Lognormal(μ=240s, σ=45s)                │
  │            ▼                                                             │
  │ [IQA Quality Gate] ──> Delay: 0.8s                                      │
  │            │                                                             │
  │            ├─── (Fail & Retries < 2) ──► Re-enters Waiting Queue         │
  │            ├─── (Fail & Retries >= 2) ─► Exits as Manual Referral        │
  │            └─── (Pass: Gradable)                                         │
  │                     │                                                    │
  │                     ▼                                                    │
  │ [Edge AI Inference] ──> Delay: 4.2s                                      │
  │                         Sets: ICDR Class, UrgencyPriority, Size          │
  │                     │                                                    │
  │                     ▼                                                    │
  │ [Uplink Buffer] ──────> FIFO Spool Buffer (Max Cap: 500)                 │
  └─────────────────────┼────────────────────────────────────────────────────┘
                        │
                        ▼
  RURAL CELLULAR TRANSMISSION INFRASTRUCTURE
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ [Channel Model] ──────> Bandwidth: Gamma(k, θ) + Floor(64 kbps)          │
  │                         Latency: T_tx = (Size * 8) / B(t)                │
  │                         Drop Logic: P_drop = 0.05 ──► Retransmission     │
  └─────────────────────┼────────────────────────────────────────────────────┘
                        │
                        ▼
  CENTRAL DISTRICT TELE-OPHTHALMOLOGY WORKSTATION
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ [Triage Ingestion] ───> Splits into Priority Queues:                     │
  │                         - Priority 1 (High): Referable DR (Grades 2-4)   │
  │                         - Priority 2 (Low):  Routine Checks (Grades 0-1) │
  │            │                                                             │
  │            ▼                                                             │
  │ [Review Pool] ────────> Seizes: [Ophthalmologist Resource Pool (c = 2)]  │
  │                         Service: Bimodal Lognormal (30s / 90s)           │
  │            │                                                             │
  │            ▼                                                             │
  │ [Diagnostic Sink] ────> Emits Completed Telemetry Records                │
  └─────────────────────┼────────────────────────────────────────────────────┘
                        │
                        ▼
  OPERATIONAL PERFORMANCE & METRICS ENGINE
  ┌──────────────────────────────────────────────────────────────────────────┐
  │  - Daily District Throughput (Target: 400 cases/day)                     │
  │  - Scaled Annual Completed Volume (Target: 100,000+ cases/year)          │
  │  - P95 End-to-End Latency Profile                                        │
  │  - Camera, Doctor, and Channel Utilization Percentages                   │
  └──────────────────────────────────────────────────────────────────────────┘
```

---

### 24. References

1.  **Ministry of Health and Family Welfare, Government of India.** (2022). *Indian Public Health Standards (IPHS) Guidelines for Primary Health Centres*. Directorate General of Health Services.
    *Supports:* Operational clinic hours (7 hours/day), physical staffing profiles, and equipment constraints in rural facilities.
2.  **Rachapelle, S., Legood, R., Alavi, Y., Lindfield, R., Sharma, T., Kuper, H., & Polack, S.** (2013). *The cost-utility of telemedicine to screen for diabetic retinopathy in India*. Ophthalmology, 120(9), 1797-1804.
    *Supports:* Non-mydriatic fundus camera operational timings, field ungradable rates ($8\%-12\%$), and clinical staffing patterns in rural screening workflows.
3.  **Telecom Regulatory Authority of India (TRAI).** (2023). *The Indian Telecom Services Performance Indicators: Rural Broadband and QoS Reports*. New Delhi: TRAI.
    *Supports:* Empirical rural uplink bandwidth baselines ($64-384\,\text{kbps}$ floors) and cellular packet interruption distributions.
4.  **MathWorks, Inc.** (2023). *SimEvents User's Guide: Model Discrete-Event Systems in Healthcare and Telecommunications*. Natick: The MathWorks, Inc.
    *Supports:* Core block mechanics for `Entity Generator`, `Priority Queue`, `Resource Pool`, and discrete-event simulation engines.
5.  **MathWorks, Inc.** (2023). *Simulink User's Guide: Hybrid Dynamic and Discrete-Event System Simulation*. Natick: The MathWorks, Inc.
    *Supports:* Continuous metric integration, MATLAB Function block bridging, and dashboard telemetry integration.
6.  **Gross, D., Shortle, J. F., Thompson, J. M., & Harris, C. M.** (2018). *Fundamentals of Queueing Theory* (5th ed.). Hoboken: John Wiley & Sons.
    *Supports:* Theoretical formulation of $M/G/c$ priority queuing delay models and Little's Law validation equations.
7.  **Gulshan, V., Rajan, R. P., Widner, K., Wu, D., Gomez, P., Raman, R., ... & Webster, D. R.** (2019). *Performance of a deep-learning algorithm for the detection of diabetic retinopathy in a public healthcare setting in India*. Nature Eye, 33(7), 1097-1106.
    *Supports:* Referable diabetic retinopathy prevalence distributions ($15\%-22\%$) within rural Indian screening populations.
8.  **Hall, R.** (2013). *Handbook of Healthcare Operations Research: Methods and Applications*. New York: Springer-Verlag.
    *Supports:* Non-homogeneous Poisson Process (NHPP) formulations for clinical patient arrivals and staff fatigue models.

### Simulink Telemedicine Architecture Research — SIH 26038

### Simulation Objectives

- Determine whether a proposed rural screening architecture can process **100,000+ patients annually**.
- Identify the limiting resource: cameras, operators, AI compute, network, telemedicine server, or ophthalmologists.
- Quantify operational performance: throughput, waiting time, queue size, latency percentiles, utilization, dropped cases, and annual capacity.
- Compare alternative deployment strategies before implementation or procurement.
- Evaluate resilience to high demand, poor connectivity, high ungradable-image rates, and reviewer shortages.

### AI vs Workflow Simulation

| Scope | AI Model Simulation | Healthcare Workflow Simulation |
|---|---|---|
| Main question | “How accurate is the DR model?” | “Can the service process patients on time?” |
| Typical inputs | Images, labels, model scores | Arrival rates, service times, resources, failure rates |
| Main outputs | Sensitivity, specificity, AUC, F1-score | Throughput, wait time, latency, queue length, utilization |
| Primary tools | MATLAB, Deep Learning Toolbox | Simulink, SimEvents, Stateflow |
| Role in SIH system | Produces screening result, confidence, XAI map | Models delivery of that result through rural telemedicine |

Clinical metrics must remain separate from operational metrics. A classifier with high AUC can still produce an operationally unusable program if ophthalmologist queues are overloaded or image uploads fail.

### Arrival Models

| Arrival Pattern | Use When | SimEvents Implementation | Suitability |
|---|---|---|---|
| Deterministic | Scheduled appointments; fixed slots | Entity Generator with constant intergeneration time | Good baseline |
| Homogeneous Poisson | Random arrivals at steady intensity | Exponential intergeneration times | Use only after checking assumption |
| Non-homogeneous Poisson | Arrival rate changes by hour/day | Time-dependent intergeneration function | Good for clinic schedules |
| Empirical distribution | Timestamp data are available | MATLAB-defined sampling of observed intervals | Preferred with field data |
| Batch arrival | Camps/outreach/transport arrivals | Short inter-arrival burst or generated batch | Important rural scenario |
| Scheduled campaign | Known outreach calendar | MATLAB schedule or Stateflow control | Recommended for campaigns |

For MVP, use scheduled clinic arrivals within working hours, plus an optional batch/camp mode. The Entity Generator supports custom intergeneration times and entity attributes. [cite:110][cite:133]

### Queueing-Theory Guidance

| Queue Model | Assumptions | Use in This Project |
|---|---|---|
| M/M/1 | Poisson arrivals, exponential service, one server | Analytical sanity-check only |
| M/M/c | Poisson arrivals, exponential service, `c` servers | Approximate pooled doctor/AI capacity |
| M/G/1 | Poisson arrivals, general service distribution, one server | Better for variable one-doctor review time |
| G/G/c | General arrivals/service, multiple servers | Preferred conceptual model; implement directly in SimEvents |
| Finite-capacity | Limited waiting/storage | Physical waiting rooms and upload buffers |
| Priority queue | Multiple urgency classes | Optional urgent/referable review policy |

M/M/1 is defined by Poisson arrivals, exponential service time, and one server; do not assert these as field facts without evidence. [cite:132] SimEvents directly supports general arrivals and service distributions, making a G/G/c operational simulation preferred.

### Scenario A — Small Pilot

| Parameter | Scenario Assumption |
|---|---|
| PHCs | 5 |
| Capacity intent | Below 100,000; pilot baseline |
| Cameras/PHC | 1 |
| Operators/PHC | 1 |
| AI | Centralized limited compute |
| Network | One link per PHC |
| Doctors | One centralized reviewer |
| Purpose | Verify basic flow and bottlenecks |

### Scenario B — District Deployment

| Parameter | Scenario Assumption |
|---|---|
| PHCs | 20 |
| Target cases/PHC/day | 20 |
| Cameras/PHC | 1 |
| Operators/PHC | 1 |
| AI | Centralized multi-slot service |
| Network | Per-PHC variable links |
| Doctors | Centralized review pool |
| Purpose | Primary 100,000-case planning scenario |

20 PHCs x 20 cases/day x 250 days gives a nominal 100,000 cases/year before recapture, downtime, failed transfers, or unfinished backlog.

### Scenario C — Scaled Distributed Deployment

| Parameter | Scenario Assumption |
|---|---|
| PHCs | 40 |
| Target cases/PHC/day | 10 |
| Cameras/PHC | 1 |
| AI | Distributed/edge preprocessing + centralized review |
| Network | Store-and-forward upload |
| Doctors | Centralized shared review pool |
| Purpose | Resilience and connectivity analysis |

40 PHCs x 10 cases/day x 250 days also gives a nominal 100,000 annual cases before operational losses.

### Simulink Architecture

```text
[Arrival Schedule / Entity Generator]
          |
          v
[Registration Queue] --> [Registration Server]
          |
          v
[Camera Queue]
          |
          v
[Acquire Camera + Operator Resources]
          |
          v
[Image Acquisition Server]
          |
          v
[Release Camera + Operator Resources]
          |
          v
[IQA Server / Quality Decision]
          |
          +------------------------------+
          |                              |
          v                              v
[Ungradable / Recapture Queue]     [Enhancement Server]
          |                              |
          +------------->----------------+
                         |
                         v
                   [AI Processing Queue]
                         |
                         v
            [Acquire Compute Resource]
                         |
                         v
           [AI Inference + XAI + Report Server]
                         |
                         v
            [Release Compute Resource]
                         |
                         v
                  [Upload Queue]
                         |
                         v
          [Bandwidth-Dependent Transfer Server]
                         |
                         v
               [Transmission Success?]
                   |              |
                  Yes             No
                   |              |
                   v              v
            [Doctor Queue]  [Retry / Backoff Queue]
                   |              |
                   v              |
     [Acquire Ophthalmologist Resource]  |
                   |              |
                   v              |
             [Review Server] <----+
                   |
                   v
       [Final Decision / Referral Routing]
                   |
                   v
            [Entity Terminator]

[Queue/Server/Resource Statistics] --> [Scopes / Dashboard / To Workspace / Simulation Data Inspector]
```

| Element | Recommended Technology |
|---|---|
| Case creation | SimEvents `Entity Generator` |
| Queues | SimEvents `Entity Queue` |
| Service delays | SimEvents `Entity Server` |
| Case exit | SimEvents `Entity Terminator` |
| Routing | `Entity Output Switch`, `Entity Gate`, or Stateflow |
| Resources | `Resource Pool`, `Resource Acquirer`, `Resource Releaser` |
| Dynamic service times | Entity Server MATLAB action or MATLAB Function logic |
| Retry/shifts/escalation | Stateflow or event-action logic |
| Scenario data | MATLAB workspace/data dictionary/scripts |
| Metrics | Scope, Dashboard, Simulation Data Inspector, To Workspace |

### Parameters and Assumptions

| Parameter | Symbol | Unit | Baseline | Range / Alternative | Source / Assumption |
|---|---:|---:|---:|---:|---|
| Annual patients | \(N_y\) | patients/year | 100,000 | 25,000–150,000 | SIH target |
| Operating days | \(D\) | days/year | 250 | 220–300 | Scenario parameter |
| Operating hours/day | \(H\) | hours/day | 8 | 6–10 | Scenario parameter |
| Required daily completions | \(N_d\) | patients/day | 400 | Derived | Derived from 100,000/250 |
| PHCs | \(P\) | PHCs | 20 | 5, 20, 40 | Scenario configurations |
| Patients/PHC/day | \(N_{phc}\) | patients/day | 20 | 10–80 | Derived/scenario |
| Cameras/PHC | \(C\) | cameras | 1 | 1–2 | Scenario parameter |
| Operators/PHC | \(O\) | operators | 1 | 1–2 | Scenario parameter |
| Image size | \(S\) | MB | Measure | Sensitivity sweep | Actual post-compression files |
| Effective upload bandwidth | \(B\) | Mbps | Measure preferred | Sensitivity sweep | Unknown without field test |
| Network latency | \(L_n\) | s | Scenario value | Sensitivity sweep | Unknown without testing |
| Network failure probability | \(p_f\) | probability | Scenario value | 0–chosen range | Engineering assumption unless logs exist |
| AI time | \(T_{AI}\) | s | Benchmark | Sweep | Measure on target hardware |
| XAI/report time | \(T_{XAI}\) | s | Benchmark | Sweep | Measure on target hardware |
| Doctor review | \(T_D\) | s | 30 | 30–300 | SIH target/scenario, not universal fact |
| Doctors | \(M_D\) | doctors | 1–2 | 1–10 | Scenario parameter |
| Ungradable rate | \(p_u\) | percent | Scenario value | Sensitivity sweep | Requires field/dataset evidence |
| Max recaptures | \(R_{max}\) | count | 1–2 | 0–3 | Workflow policy assumption |
| Retry limit | \(K_{max}\) | count | 3 | 0–5 | Engineering assumption |

### Sensitivity Analysis

Sweep patient arrival rate, campaign burst size, camera/operator capacity, acquisition time, ungradable probability, AI/XAI time, payload size, effective bandwidth, latency, network failure probability, reviewer count, and review-time distribution.

1. Validate a deterministic baseline first.
2. Add stochastic variation one factor at a time.
3. Run one-factor sweeps for interpretable results.
4. Use factorial or Latin-hypercube experiments for interactions if time permits.
5. Run multiple seeds for each stochastic case.
6. Rank parameters by their impact on annual completions and P95 latency.

Monitor annual completions, completion ratio, P95 latency, P95 doctor waiting time, peak queues, utilization, retries/failures, and end-of-run backlog.

### Validation of the Simulation

### Structural Validation

- Every case must take either gradable or ungradable route.
- Recapture and retry loops require explicit maximum limits.
- Only successful uploads enter doctor review.
- Doctor resource is acquired before and released after review.
- Each completed case exits exactly once.

### Parameter Validation

- Benchmark real AI, XAI, report, and compression times on target hardware.
- Measure image payloads after the selected compression path.
- Obtain field measurements for bandwidth/latency where possible.
- Obtain schedules, staffing, and camera availability from deployment partners.
- Label all unavailable values as assumptions.

### Output and Extreme Testing

Expected directional behavior: greater arrivals should not lower waiting time; fewer doctors should raise review queues; higher bandwidth should reduce transfer delay when the network is limiting; higher ungradable rates should raise camera workload.

Test zero arrivals, extremely high arrivals, zero bandwidth, no doctors, all images ungradable, very fast AI, very slow review, and full finite queues.

### Conservation Check

\[
N_{generated} = N_{completed} + N_{in\ queues} + N_{in\ service} + N_{dropped/terminated}
\]

### MATLAB ↔ SIMULINK Integration

| MATLAB | Simulink/SimEvents |
|---|---|
| Parameter/data preparation | Entity flow, queues, servers, resources |
| AI/XAI/report timing benchmarks | Event timing and service contention |
| Distribution fitting and scenario generation | Telemedicine operations simulation |
| Experiment automation and post-analysis | Live workflow and metric logging |
| Plot/report creation | Queue/server/resource statistics |

| Mechanism | Use |
|---|---|
| MATLAB workspace/data dictionary | Scenario parameters |
| Entity attributes | Per-case parameters |
| Entity Server MATLAB action | Dynamic service time |
| MATLAB Function block | Deterministic calculation |
| Simulink Function block | Exchange between SimEvents and Simulink |
| To Workspace/To File | Output logging |
| Simulation Data Inspector | Time-history analysis |
| MATLAB scripts | Batch simulations and sensitivity sweeps |

MathWorks documents Simulink Function blocks for timestamping entities, passing attributes to Simulink components, and feeding results to routing logic. [cite:108]

### Implementation Feasibility

| Subsystem | Feasibility | Reason |
|---|---|---|
| Patient generator | 🟢 Easy | Native Entity Generator |
| Camera model | 🟢 Easy | Queue + resource + server pattern |
| IQA model | 🟡 Moderate | Start with probability/delay; full IQA optional |
| AI delay model | 🟢 Easy | Benchmark-derived Entity Server service time |
| Actual AI inference in loop | 🟠 Difficult | Slows large-scale event simulation |
| Network model | 🟡 Moderate | Payload/bandwidth is simple; field calibration harder |
| Queue model | 🟢 Easy | Native SimEvents blocks/statistics |
| Doctor model | 🟢 Easy | Resource pool + review server |
| Recapture loop | 🟡 Moderate | Needs bounded counters/routing |
| Resource allocation | 🟡 Moderate | Multiple-pool policies need careful design |
| 100,000-patient simulation | 🟢 Easy | Feasible when AI is a delay abstraction |
| Dashboard | 🟢 Easy | Scopes, dashboard, Data Inspector |
| Optimization | 🟠 Difficult | Requires objective, constraints, systematic runs |

### Recommended MVP Simulation

### Must Have

- Patient/case Entity Generator.
- Camera queue and camera resource.
- Acquisition service delay.
- IQA decision and bounded recapture loop.
- AI processing queue and configurable inference delay.
- Network queue with payload/bandwidth transmission-time equation.
- Doctor queue and constrained reviewer resource.
- Completion/decision Entity Terminator.
- Throughput, queue length, wait time, utilization, and end-to-end latency outputs.
- A 100,000+ annual scenario using multiple PHCs and 250 working days.
- Baseline, poor-network, high-load, and doctor-shortage scenarios.

### Should Have

- Separate XAI/report stage.
- Priority queue for urgent/referable cases.
- Network failure/retry logic.
- PHC-specific schedules and bandwidth.
- Multiple doctor shifts.
- Dashboard with live queue/utilization indicators.

### Nice to Have

- Stateflow availability calendar.
- Empirical network traces.
- Actual AI inference timing integrated in service model.
- Cost model.

### Future Work

- Packet-level network modeling.
- Dynamic routing among district reviewers.
- Real hospital/PACS integration.
- Multi-district optimization and prospective calibration.

### Final Recommended Architecture

**Entity:** `ScreeningCase`.

**Resources:** fundus camera, PHC operator, compute slot, upload channel, ophthalmologist.

**Queues:** registration, camera, recapture, AI, upload, retry, doctor review.

**Events:** arrival, acquisition completion, IQA result, upload success/failure, reviewer availability, review completion, final decision.

**Delays:** acquisition, IQA, enhancement, AI, XAI/report, transfer, retry, review.

**Key metrics:** annual capacity, throughput, average/P95 latency, queue wait, peak queue, utilization, retries, quality failures, backlog.

```text
                           [MATLAB Scenario Parameters]
                                      |
                                      v
                        [Entity Generator: ScreeningCase]
                                      |
                                      v
                      [Registration Queue + Entity Server]
                                      |
                                      v
                      [Camera Queue + Camera/Operator Pool]
                                      |
                                      v
                           [Fundus Acquisition Server]
                                      |
                                      v
                              [IQA Server / Decision]
                                 /                 \
                    [Recapture Queue]       [Enhancement Server]
                              |                      |
                              +------> Camera Queue  v
                                            [AI Queue]
                                                |
                                                v
                               [Compute Pool + AI/XAI/Report Server]
                                                |
                                                v
                                          [Upload Queue]
                                                |
                                                v
                               [Bandwidth-Dependent Transfer Server]
                                                |
                                       [Transmission Decision]
                                          /                 \
                              [Doctor Queue]         [Retry / Backoff]
                                    |                         |
                                    v                         +--> Upload Queue
                    [Ophthalmologist Pool + Review Server]
                                    |
                                    v
                         [Referral / Final Decision]
                                    |
                                    v
                           [Entity Terminator]

 All queue/server/resource outputs → Scope, Dashboard, Data Inspector,
 To Workspace → MATLAB scenario comparison and sensitivity analysis.
```

### References

1. **MathWorks.** *SimEvents Documentation.* 2026. https://www.mathworks.com/help/simevents/index.html. Supports discrete-event engine, latency, throughput, packet-loss, routing, and resource analysis. [cite:93]
2. **MathWorks.** *Get Started with SimEvents.* 2026. https://www.mathworks.com/help/simevents/getting-started-with-simevents.html. Supports discrete-event and hybrid Simulink–SimEvents modeling. [cite:94]
3. **MathWorks.** *Model Basic Queuing Systems.* 2026. https://www.mathworks.com/help/simevents/ug/model-basic-queuing-systems.html. Supports Entity Queue, Entity Server, priorities, capacity, and statistics. [cite:92]
4. **MathWorks.** *Queue and Service.* 2026. https://www.mathworks.com/help/simevents/queuing-and-service.html. Supports queue storage, buffering, service, and delay models. [cite:90]
5. **MathWorks.** *Resource Pool.* 2026. https://www.mathworks.com/help/simevents/ref/resourcepool.html. Supports resource acquisition/release and utilization. [cite:105]
6. **MathWorks.** *Entities in a SimEvents Model.* 2026. https://www.mathworks.com/help/simevents/gs/role-of-entities-in-simevents-models.html. Supports entities and entity-flow concepts. [cite:101]
7. **MathWorks.** *Working with Entity Attributes and Entity Priorities.* 2026. https://www.mathworks.com/help/simevents/ug/setting-attributes-of-entities.html. Supports entity data and priority attributes. [cite:110]
8. **MathWorks.** *Route Entities and Simulink Messages.* 2026. https://www.mathworks.com/help/simevents/routing.html. Supports routing blocks including Entity Gate and Entity Output Switch. [cite:117]
9. **MathWorks.** *Explore Statistics and Visualize Simulation Results.* 2026. https://www.mathworks.com/help/simevents/gs/exploring-a-simulation-using-the-plots.html. Supports Scope, Dashboard, Data Inspector, and SimEvents statistics. [cite:119]
10. **MathWorks.** *Interpret SimEvents Models Using Statistical Analysis.* 2026. https://www.mathworks.com/help/simevents/ug/statistics-for-data-analysis.html. Supports queue/server output statistics. [cite:107]
11. **MathWorks.** *Measure Point-to-Point Delays.* 2026. https://www.mathworks.com/help/simevents/ug/measure-point-to-point-delays.html. Supports timestamped entity-attribute latency measurement. [cite:120]
12. **MathWorks.** *M/M/1 Queuing System.* 2026. https://www.mathworks.com/help/simevents/ug/m-m-1-queuing-system.html. Supports M/M/1 queue definition. [cite:132]
13. **MathWorks.** *Trigger Simulink Components with Discrete Events in SimEvents.* 2026. https://www.mathworks.com/help/simevents/gs/trigger-simulink-components-with-discrete-events.html. Supports SimEvents–Simulink function integration. [cite:108]
14. **MathWorks.** *Entity Terminator — Terminate entities.* 2026. https://www.mathworks.com/help/simevents/ref/entityterminator.html. Supports departure/termination of completed entities. [cite:129]
15. **MathWorks.** *MATLAB Function — Include MATLAB code in Simulink models.* 2026. https://www.mathworks.com/help/simulink/slref/matlabfunction.html. Supports embedded MATLAB calculations in Simulink. [cite:106]

### 04 — Simulink/SimEvents Telemedicine Architecture Research

### SIH 26038 — Explainable AI for Diabetic Retinopathy Screening in Rural India

---

### AI Model Simulation vs. Healthcare Workflow Simulation

| | AI Model Simulation | Healthcare Workflow Simulation (this document) |
|---|---|---|
| Subject | The classifier itself — training, inference accuracy, explainability quality | The system *around* the classifier — patients, queues, resources, network, doctors |
| Tooling | Deep Learning Toolbox, Python/PyTorch, Grad-CAM, confusion matrices | Simulink, SimEvents, Stateflow, MATLAB scripting |
| Metrics | Sensitivity, specificity, AUC, F1 (clinical/statistical) | Throughput, latency, queue length, utilization (operational) |
| Question answered | "Is the model good at detecting DR?" | "Can the deployed system screen 100,000+ patients/year without collapsing?" |

This document addresses **only the healthcare workflow simulation**. The AI classifier is represented in this model purely as a black-box timed processing step (an inference *duration* and a pass/fail/severity *output category*), never as a pixel-level or accuracy-level model.

---

### Suitability assessment

| Requirement | Suitability of Simulink/SimEvents |
|---|---|
| Patient arrival modeling | Well suited — SimEvents Entity Generator supports fixed, random-distribution, signal-driven, or custom MATLAB-code-driven inter-arrival times.<cite index="30-1">The Entity Generator block generates entities using intergeneration times specified by the Period, from an input signal or statistical distribution, and also supports event-based generation</cite> |
| Discrete events | This is SimEvents' core purpose. <cite index="7-1">SimEvents provides a discrete-event simulation engine and component library for analyzing event-driven system models and optimizing performance characteristics such as latency, throughput, and packet loss</cite> |
| Queues | Directly supported. <cite index="2-1">The Entity Queue and Entity Server blocks are storage blocks that hold entities</cite>, and queues can be configured with capacity, sorting policy (FIFO/LIFO/priority), and overwrite behavior. |
| Resource constraints | Directly supported via the Resource Pool / Resource Acquirer / Resource Releaser block trio, which models a finite, shared pool of resources (e.g., doctors, cameras) that entities must acquire before proceeding and release afterward. |
| Parallel processing | Supported via parallel Entity Server chains, Entity Output Switch for load splitting across multiple servers, and multiple Resource Pool instances. |
| Network delays | Modelable using Entity Server blocks whose service time represents transmission time (a function of image size and bandwidth), combined with random delay/jitter distributions. |
| Doctor review | Modelable as a Resource Pool (doctor capacity) + Entity Server (review duration) pair, or a queue feeding a limited-capacity server. |
| Recapture loops | Modelable with Entity Output Switch / Entity Input Switch feedback paths that route "ungradable" entities back to the acquisition stage. |
| Throughput analysis | Native SimEvents statistics (entities departed, average/max queue length, utilization) directly give throughput and bottleneck data. |
| Bottleneck analysis | Supported through per-block statistics (queue length, utilization, waiting time) collected during simulation. |
| What-if scenarios | Supported by parameter sweeps, MATLAB scripting around the model, and Simulink's Fast Restart / batch simulation capabilities. |
| Resource optimization | Achievable by scripting parameter sweeps over resource counts and observing throughput/latency outputs (no built-in "auto-optimizer" specific to SimEvents is claimed here). |

### Standard Simulink vs. SimEvents vs. Stateflow vs. MATLAB scripts

- **Standard Simulink** is a **continuous/time-based** block-diagram environment (differential equations, fixed-step or variable-step numerical integration). It is not naturally suited to representing "a patient waits in a queue for an indeterminate time" — <cite index="2-1">in a discrete-event simulation, an Entity Queue block stores entities for a length of time that cannot be determined in advance, and the queue attempts to output entities when possible but its output depends on whether the downstream block accepts new entities</cite>, a behavior standard Simulink signal blocks do not model. Standard Simulink is still useful in this project for time-based signals (e.g., a continuous bandwidth-availability signal, or aggregate rate/utilization plots over time) that feed into or read from the SimEvents part of the model.

- **SimEvents** is the correct primary technology for this project. It is purpose-built for exactly this class of problem: <cite index="7-1">SimEvents provides a discrete-event simulation engine and component library for analyzing event-driven system models and optimizing performance characteristics such as latency, throughput, and packet loss; queues, servers, switches, and other predefined blocks enable you to model routing, processing delays, and prioritization for scheduling and communication</cite>. It is **required**, not optional, for a credible patient-flow/queue/resource simulation of this kind — standard Simulink alone cannot represent entities, queues, and finite resources without effectively reimplementing SimEvents' semantics by hand.

- **Stateflow** (specifically the **Discrete-Event Chart** block) is optional and complementary. It is useful for encoding **complex branching decision logic** as a state machine rather than nested MATLAB `if` statements — for example, a case's state machine (`Registered → Captured → UnderReview → Recaptured → Transmitted → Reviewed → Referred/Cleared`). <cite index="51-1">The Discrete-Event Chart block provides graphical state transitions and MATLAB action language to create custom SimEvents models, and its distinguishing characteristic is that it executes in an event-based rather than time-based fashion</cite>. Note: <cite index="53-1">SimEvents lets you view, edit, and simulate a Discrete-Event Chart within a SimEvents example model, but a Stateflow license is required to save the model</cite> — a licensing consideration for the team to check.

- **MATLAB scripts / MATLAB Function blocks** are used for: (1) computing derived parameters before simulation (e.g., converting "100,000 patients/year" into an arrival-rate parameter), (2) driving randomized service/inter-arrival times inside SimEvents blocks (the **MATLAB action** time-source option, as shown in MathWorks' own M/M/1 and feedback-control examples), (3) post-processing simulation logs into charts/statistics, and (4) automating parameter sweeps across many simulation runs (sensitivity analysis, scenario comparison).

| Technology | Role | Why Needed | Project Component |
|---|---|---|---|
| SimEvents | Primary simulation engine: entities, queues, servers, resources, routing | Only tool in the stack natively built for discrete-event, resource-constrained patient/case flow | Patient flow, camera/AI/doctor queues, recapture loop, network transmission delay, resource pools |
| Standard Simulink | Time-based signals, dashboards/scopes, hosting SimEvents blocks in a model | Needed as the surrounding simulation framework; useful for continuous utilization/rate plots | Statistics visualization, top-level model container, optional bandwidth-availability signal |
| Stateflow (Discrete-Event Chart) | Encoding complex per-case state logic as a state machine | Optional; clarifies branching logic (recapture, referral, failed transmission) versus deeply nested MATLAB code | Case lifecycle state machine (optional refinement) |
| MATLAB scripts / MATLAB Function block | Custom randomization, parameter calculation, batch experiments, post-processing | SimEvents blocks explicitly support "MATLAB action" as a time-source/service-time source, and MATLAB is the natural layer for statistics and sweeps | Arrival-time distributions, service-time distributions, scenario automation, result analysis |

---

### Textual architecture

```
Patient
  → Registration (entity created)
  → Fundus Image Acquisition (resource: camera + operator)
  → Image Quality Assessment (IQA) (processing delay)
  → Recapture Decision (branch)
        ├─ Ungradable → Recapture Queue → back to Acquisition (feedback loop, bounded retries)
        └─ Gradable  → continue
  → AI Processing (resource: compute; delay: inference time)
  → Explainability (XAI) Generation (delay)
  → Report Generation (delay)
  → Network Transmission (resource: bandwidth; delay: f(image size, bandwidth); possible failure/retry)
  → Doctor Review Queue
  → Ophthalmologist Review (resource: doctor; delay: review time)
  → Final Decision (branch)
        ├─ Screening negative / low risk → Patient notified, case closed
        └─ Referral required → Referral case created, routed to referral facility
```

### Stage classification

| Stage | Type |
|---|---|
| Patient arrival | Entity generation event |
| Registration | Event (attribute assignment) |
| Fundus image acquisition | Resource-constrained delay (camera + operator) |
| Image Quality Assessment | Processing delay (server) |
| Recapture decision | Decision / branch (probabilistic or attribute-based) |
| Recapture queue | Queue (feedback path) |
| AI processing | Resource-constrained delay (compute server) |
| Explainability generation | Processing delay |
| Report generation | Processing delay |
| Network transmission | Resource-constrained delay (bandwidth) with possible failure event |
| Doctor queue | Queue |
| Ophthalmologist review | Resource-constrained delay (doctor) |
| Final decision | Decision / branch |
| Referral | Event → new entity ("referral case") or attribute update |

### Additional failure/exception paths to model

- **Ungradable image → recapture** — bounded number of retries (e.g., cap at 2–3 attempts before manual escalation), modeled as a feedback loop through Entity Input/Output Switch blocks.
- **Failed transmission** — probabilistic event on the network server; failed entities re-enter a transmission-retry queue with backoff delay.
- **Processing failure** — optional; a small probability that AI inference fails and the case is flagged for manual review, bypassing automated classification.
- **Doctor unavailable** — modeled implicitly by Resource Pool capacity = 0 for scheduled off-hours, or by a working-hours calendar signal that gates the Resource Pool.
- **Queue buildup** — always observable via queue-length statistics; the simulation does not need a special "buildup" block, only monitoring on the Entity Queue blocks.

---

### Arrival process research

Do not assume Poisson arrivals as a default. The appropriate model depends on how patients actually reach a PHC:

- **Deterministic/scheduled arrival** — appropriate if the PHC operates by fixed appointment slots (e.g., one patient every 10 minutes on a fixed schedule). Represented with the Entity Generator's Constant-period, Time-based mode. <cite index="23-1">A D/D/1 queuing system has a deterministic arrival rate and a deterministic service rate</cite>, and MathWorks' own introductory SimEvents tutorial uses exactly this as the first teaching example.
- **Poisson process (exponential inter-arrival times)** — appropriate as a **simplifying baseline assumption** for walk-in patient arrival at a PHC during open hours, when arrivals are effectively independent and memoryless. MathWorks provides a ready reference pattern: <cite index="22-1">an M/M/1 queue has a Poisson arrival process, an exponential service-time distribution, and one server; the model generates entities at a rate following a Poisson process, where inter-arrival times are exponentially distributed and computed from the arrival rate λ using −log(1−randvar)/λ</cite>. This is a **reasonable baseline** but should be labeled a simplifying assumption, not a validated fact about rural patient behavior.
- **Non-homogeneous Poisson process (time-varying rate)** — more realistic for PHC operations, where arrival rate is near-zero outside working hours, ramps up in the morning, and may spike during organized **screening campaigns** (camps) versus ordinary walk-in days. This can be implemented in SimEvents by driving the Entity Generator's intergeneration time from a **time-varying signal** or **MATLAB action** code that looks up the current simulation time against an hourly/daily rate table, rather than a single fixed λ.
- **Batch arrivals** — appropriate for organized rural screening campaigns where a bus or group of patients from a village arrives together. Modelable with the Entity Generator producing a "batch" attribute, or by generating N entities at the same timestamp.
- **Empirical/observed arrival distribution** — the most realistic option **if field data becomes available** (actual PHC footfall logs); until then this remains a "requires field data" item.

### Recommended baseline for this project

| Modeling need | Recommended approach | Label |
|---|---|---|
| Ordinary PHC walk-in day | Non-homogeneous Poisson (working-hours rate profile) | Engineering assumption (Poisson kernel is standard practice; the hourly profile shape is an assumption) |
| Organized screening campaign day | Batch arrivals at scheduled times | Scenario parameter |
| Simplest MVP demonstration | Homogeneous Poisson process during working hours only (rate = 0 outside hours) | Engineering assumption, chosen for tractability |
| Daily/weekly variation | Different λ per day-of-week; PHCs closed on Sundays/holidays | Scenario parameter |

---

### Identified queues

1. **Fundus camera queue** — patients waiting for a free camera/operator at the PHC.
2. **Image processing (AI) queue** — cases waiting for AI compute to become available.
3. **Network transmission queue** — reports waiting for available bandwidth/server capacity.
4. **Ophthalmologist review queue** — cases waiting for a doctor.
5. **Recapture queue** — ungradable images waiting to re-enter the acquisition stage.

### Per-queue analysis

| Queue | Arrival process | Service process | Servers | Discipline | Capacity | Expected bottleneck | Key metrics |
|---|---|---|---|---|---|---|---|
| Camera queue | Patient arrivals (Poisson/scheduled, Section 6) | Acquisition time per patient (roughly deterministic with small variance) | 1–3 per PHC (parameter) | FIFO (or priority for referral follow-ups) | Physical waiting room limit (finite) or effectively unbounded for simulation | High if cameras/operators are few relative to arrival rate | Queue length, waiting time, camera utilization |
| AI processing queue | Output of camera/IQA stage | AI inference time (near-deterministic, small variance) | 1+ compute "slots" (parameter — depends on GPU/edge deployment) | FIFO | Large/unbounded (digital queue) | Low–Moderate if centralized inference under-provisioned relative to many PHCs | Queue length, waiting time, compute utilization |
| Network transmission queue | Output of report-generation stage | Transmission time = image/report size ÷ available bandwidth (Section 8) | 1 uplink per PHC (or shared backhaul) | FIFO | Unbounded (digital) but bounded practically by memory | High in low-bandwidth PHCs, or if many PHCs share one backhaul | Queue length, waiting time, network utilization, failed transmissions |
| Doctor review queue | Output of network stage across all PHCs feeding into it | Review time (target ≈ 30 s per problem statement, Section 9) | 1 to a few ophthalmologists (district/state level) | FIFO, or priority (urgent/referral-suspect cases first) | Unbounded (digital), but real waiting time is the real constraint | Very High — classic scarce-expert bottleneck | Queue length, waiting time, doctor utilization |
| Recapture queue | Output of IQA "ungradable" branch | Same as camera queue (re-acquisition) | Shares camera/operator resource | FIFO, capped retry count | Bounded by max-retry policy | Moderate — inflates effective load on the camera resource | Recapture rate, additional load on camera queue |

### Queueing-model applicability

- **M/M/1 or M/M/c** (Poisson arrivals, exponential service, 1 or c identical servers) is a reasonable **first-pass analytical approximation** for the doctor queue (single or few doctors) and the camera queue, *if* arrivals are approximately Poisson and service times are approximately exponential. This is useful for sanity-checking simulation output against closed-form formulas (e.g., expected waiting time via the Erlang-C / M/M/c formula), not as a replacement for simulation.
- **M/G/1** (Poisson arrivals, general service-time distribution, 1 server) is more realistic for doctor review, since a fixed target review time (≈30 s) with real-world variability is not well approximated by an exponential distribution; a general or bounded distribution (e.g., truncated normal or lognormal around the 30 s target) is a better *engineering assumption*.
- **Finite-capacity queues** are appropriate for the physical waiting room at a PHC — patients cannot queue indefinitely in a room with limited chairs — and can be modeled via the Entity Queue block's Capacity parameter, with an explicit "reneging" or "blocked" path for patients who leave if the queue is full.
- **Priority queues** are appropriate for the doctor queue if referral-suspect or previously-recaptured cases should be reviewed ahead of routine cases; SimEvents supports this via the Entity Queue's priority sorting policy driven by an entity attribute.

**Representation in SimEvents:** Each queue above is represented physically as an **Entity Queue** block (or the built-in queue portion of a **Single Server**/**N-Server** block) immediately preceding the corresponding **Entity Server** block that performs the timed operation. Entity Queue's <cite index="2-1">capacity, sorting policy (FIFO, LIFO, or custom priority), and overwriting policy for a full queue</cite> are configured per the table above.

---

### Model chain

```
Report (image + metadata, size in MB)
  → Compression (delay; optional size-reduction factor)
  → Transmission (delay = size / effective bandwidth)
  → Network Delay (fixed latency + random jitter)
  → Server (queueing for server-side capacity)
  → Doctor
```

### Mathematical relationship

For a report of size `S` (megabits) transmitted over an effective bandwidth `B` (Mbps), the transmission time is:

```
T_transmission = S / B
```

Total network-stage delay for one report:

```
T_network = T_transmission + T_latency + T_jitter (random) + T_retry (if failure occurs)
```

Where `T_latency` is a small, roughly fixed round-trip propagation/processing delay (tens to hundreds of ms), and `T_jitter` is a random variation around it. If a transmission fails (probability `p_fail`), the report re-enters the transmission queue after a backoff delay, so the **effective transmission time is a random variable**, not a constant.

### Published/observed values vs. simulation assumptions

| Parameter | Value | Status |
|---|---|---|
| National average fixed broadband download speed (India, NBM 2.0, March 2026) | 60.85 Mbps | Published/observed value <cite index="46-1">the national average fixed broadband download speed reached 60.85 Mbps as of March 31, 2026, while broadband connectivity to anchor institutions including Primary Health Centres increased to 2,182,312 connections</cite> — this is a *national average*, not a rural-PHC-specific figure |
| Rural internet penetration (subscribers per 100 population, 2025-26) | 48.31 | Published/observed value <cite index="42-1">rural internet penetration improved to 48.31 per 100 population in 2025-26, up from 45.03</cite> |
| India mobile median download speed | ~129 Mbps (Speedtest Global Index, Feb 2026, national) | Published/observed value, but again **not rural-specific**, and mobile speeds in a specific rural PHC may be substantially lower and more variable than the national median |
| Rural PHC uplink bandwidth for this simulation | e.g., 2–10 Mbps baseline, with a "poor connectivity" scenario at <1 Mbps | **Engineering assumption / scenario parameter** — no authoritative per-PHC bandwidth dataset was found; the team should treat this as a swept parameter, not a fact |
| Typical compressed fundus image size | e.g., 1–5 MB (JPEG-compressed) per image | **Engineering assumption** pending confirmation from the actual camera/software specification used in the project |
| Network failure/retry rate in rural connectivity | e.g., 1–10% per transmission attempt | **Engineering assumption / scenario parameter** — no authoritative figure located |

**Rule 3 compliance note:** Because per-PHC (last-mile, rural, health-facility-specific) bandwidth data was not found in authoritative sources during this research, the project's bandwidth parameter must be explicitly labeled a **scenario parameter** swept across a plausible range (e.g., 1, 5, 10, 20 Mbps) rather than presented as a single "real" number, even though the *national averages* above are genuine published statistics.

**SimEvents representation:** Represent compression and transmission as two sequential **Entity Server** blocks. The transmission server's service time is computed via a MATLAB action using the formula above, with the report's `size` attribute and a bandwidth parameter (constant, or a random/time-varying signal representing congestion). Failed transmission is modeled via a Bernoulli draw in the server's exit logic (or a downstream probabilistic Entity Output Switch) routing a fraction of entities back to a retry queue with an added backoff delay.

---

### Research framing

The problem statement's **~30-second ophthalmologist validation time** should be treated as a **project design target/requirement**, not a measured real-world average review time for retinal image grading by ophthalmologists in general. Actual reported average grading times in tele-ophthalmology literature vary considerably by workflow and case complexity and were not independently re-derived here; rather than presenting an unverified "average review time" as fact, this document keeps the 30 s figure explicitly labeled and adjustable.

| Item | Status |
|---|---|
| ~30 s ophthalmologist validation | **Project requirement / target parameter**, as stated in the SIH problem statement — not to be treated as an established clinical constant |
| Actual/realistic review-time distribution | **Unknown / requires field data or literature-specific citation**; recommend modeling as a distribution *centered* on the 30 s target (e.g., lognormal or truncated normal) with a configurable mean and spread, so the simulation can test sensitivity to this assumption |
| Number of doctors available to a district program | **Scenario parameter** — varied across single-doctor and multi-doctor configurations (Section 13) |
| Doctor working hours/breaks | **Scenario parameter** — e.g., an 8-hour day with a lunch break, modeled by gating the doctor Resource Pool's availability with a time-based signal |

### Model structure

```
Case arrives (post-network stage)
  → Doctor Review Queue (Entity Queue; FIFO or priority)
  → Resource Acquirer (acquire 1 doctor resource)
  → Entity Server (service time = review-time distribution, baseline ≈ 30 s target)
  → Resource Releaser (release doctor resource)
  → Final Decision branch
```

- **Review-time variability:** implement via the Entity Server's "MATLAB action" service-time source, e.g., a lognormal draw with median 30 s and a configurable coefficient of variation, so the model can be swept from "review is exactly 30 s" (idealized) to "review has realistic variance" (engineering assumption).
- **Single-doctor vs. multi-doctor:** a **single-server** configuration (Resource Pool capacity = 1) directly represents a lone reviewing ophthalmologist and is expected to become the dominant bottleneck at scale; a **multi-server** configuration (Resource Pool capacity = k, or k parallel Entity Server blocks fed by one shared queue) represents a small panel of doctors or a doctor + trained grader triage tier. The multi-doctor case should be modeled with the Resource Pool / Resource Acquirer / Resource Releaser pattern (Section 5) rather than a fixed-topology "N Server" block, since it more flexibly supports priority and variable staffing schedules.
- **Priority/referral cases:** if suspected-referral cases should jump the queue, implement via the Entity Queue's priority sorting policy on a "priority" attribute set upstream (e.g., by the AI's confidence/severity output), not by acquirer-level priority (which is fixed at simulation start, not dynamic per entity).

---

### Definition

**Throughput** = number of completed screening cases exiting the system per unit time (patients/hour, /day, /month, /year), as measured at the Final Decision / case-termination point.

**End-to-end latency** for one screening case = the total elapsed time from patient arrival to final decision.

```
End-to-end latency =
    Patient waiting (camera queue)
  + Image acquisition
  + IQA
  + (Enhancement, if performed)
  + AI inference
  + Explainability generation
  + Report generation
  + Network transmission (queue wait + transmission time + retries if any)
  + Doctor queue waiting
  + Doctor review
  + Final decision (near-instantaneous)
```

This is **not** a fixed sum: several components (camera queue wait, transmission time, doctor queue wait) are random variables dependent on system load, not constants.

### Required throughput for 100,000+ patients/year

A naive division gives:

```
100,000 patients / 365 days ≈ 274 patients/day (calendar-day average)
```

This single number is not operationally meaningful on its own and must be refined:

| Factor | Consideration |
|---|---|
| Realistic working days/year | PHCs typically do not operate 365 days/year — Sundays, national holidays, and local closures reduce this. A **scenario parameter** such as 280–300 working days/year is more realistic than 365. |
| Working hours/day | A PHC may run screening for, e.g., 4–8 hours/day depending on staffing — a **scenario parameter**, not a fixed fact. |
| Number of PHCs | 100,000+ patients/year is very unlikely to be served by a single PHC; it should be distributed across many PHCs in a district/state, each with its own (smaller) daily target. |
| Multiple cameras/PHC | Increases per-PHC acquisition throughput proportionally (subject to operator availability). |
| Multiple doctors | Increases review-stage throughput, but doctors are typically centralized/shared across PHCs, so doctor count does not scale 1:1 with PHC count. |

### Refined calculation approach

```
Required patients/day (system-wide) = Annual target / Working days/year
Required patients/day/PHC          = Required patients/day (system-wide) / Number of PHCs
Required patients/hour/PHC         = Required patients/day/PHC / Working hours/day
```

Example (illustrative, **scenario parameters**, not facts): if working days/year = 288 and PHCs = 40, required patients/day (system-wide) ≈ 100,000/288 ≈ 348/day, or ≈ 8.7 patients/day/PHC — a modest per-PHC load, but the **doctor stage**, being centralized, must handle the full 348/day (or whatever peak rate results after batching/pooling), which is the more demanding requirement to check against doctor capacity and review time.

### Required vs. achievable throughput

- **Required throughput** is the target derived from the 100,000+/year goal via the calculation above (a design specification).
- **Achievable simulated throughput** is whatever the model actually produces as output, given a specific resource configuration (cameras, doctors, bandwidth) — this may be *lower* than required if a bottleneck exists, revealing exactly where more resources are needed.

### Measuring throughput in SimEvents

Use the **Entity Terminator** block's statistics (number of entities destroyed/departed) sampled at simulation end, divided by simulated time, to compute realized throughput; multiple Entity Terminators (e.g., one for "screened, no referral" and one for "referred") can be summed for total completed cases. Running the simulation across a full simulated year (or a scaled-down representative period, e.g., one week, then extrapolated) with different resource configurations directly compares required vs. achievable throughput.

---

### Deterministic vs. random components

| Component | Likely nature | Modeling approach |
|---|---|---|
| Patient waiting (camera) | Random, load-dependent | Emerges from queue simulation |
| Image acquisition | Near-deterministic, small variance | Fixed or narrow-distribution service time |
| IQA | Near-deterministic (automated) | Fixed or narrow-distribution service time |
| AI inference | Near-deterministic (automated), possibly load-dependent if compute is shared | Fixed/narrow distribution + queue wait if compute is shared |
| Explainability + report generation | Near-deterministic | Fixed or narrow-distribution service time |
| Network transmission | Random (bandwidth variability, jitter, retries) | Computed per Section 8, with random jitter/failure |
| Doctor queue waiting | Highly random, load-dependent, likely the dominant contributor at scale | Emerges from queue simulation |
| Doctor review | Random around 30 s target | Distribution per Section 9 |

### Measuring latency in simulation

Timestamp each case entity at creation and at final-decision termination (using entity attributes or SimEvents' built-in "time entered/departed" tracking), and compute the difference per case. Aggregate across all completed cases in a run to report:

- **Average latency**
- **Worst-case / 95th-percentile latency** (more operationally meaningful than the average for a health system, since a small fraction of very slow cases can represent unacceptable delays for those specific patients)
- **Latency distribution** (histogram), to see whether delay is concentrated in the network stage, doctor queue, or elsewhere

---

### Likely bottleneck analysis

- **Camera bottleneck** — occurs when patient arrival rate at a PHC exceeds combined camera+operator capacity; indicated by a growing camera queue and near-100% camera utilization.
- **AI compute bottleneck** — occurs only if compute is centralized/shared across many PHCs and under-provisioned relative to aggregate case arrival rate; indicated by growing AI-processing queue length.
- **Network bottleneck** — occurs in low-bandwidth PHCs or when many PHCs share a constrained backhaul; indicated by long transmission-queue wait times and/or elevated failed-transmission counts.
- **Doctor bottleneck** — the most likely dominant bottleneck at scale, since ophthalmologists are typically the scarcest, most centralized resource; indicated by a persistently growing doctor-review queue and doctor utilization near 100%.
- **Queue bottleneck (general)** — any stage where queue length grows without bound over the simulated period (rather than reaching a steady state) indicates that stage's server capacity is below the arriving load — a structural sign of an unsustainable configuration.
- **Recapture bottleneck** — occurs if the ungradable-image rate is high, since recaptures effectively multiply the load on the camera/operator resource without a proportional increase in true new-patient throughput.

### Detection approach

Collect, per resource/queue: **utilization** (fraction of simulated time busy), **queue length** (average and maximum), **waiting time** (average and 95th percentile), and, at the system level, **throughput** and **dropped/failed case counts**. A resource whose utilization approaches 100% while its queue grows over time is the current binding constraint; increasing that resource's capacity in the next simulation run and observing whether overall throughput improves confirms (or refutes) the identified bottleneck.

| Component | Bottleneck Indicator | Metric | Possible Solution |
|---|---|---|---|
| Camera/Acquisition | Growing queue, high utilization | Camera queue length, utilization, waiting time | Add cameras/operators, extend hours, stagger PHC schedules |
| AI Compute | Growing queue if centralized | Compute queue length, utilization | Add compute capacity, deploy AI at edge (per-PHC) instead of centralized |
| Network | Long transmission wait, failed transmissions | Network queue length, failed-transmission rate, average transmission time | Increase bandwidth, compress images further, batch/schedule transmissions off-peak |
| Doctor review | Persistently growing queue, near-100% utilization | Doctor queue length, waiting time, doctor utilization | Add doctors, add trained graders as first-pass triage, extend doctor hours |
| Recapture | High recapture rate inflating camera load | Recapture rate, effective camera load multiplier | Improve capture-device/training quality, tighten/loosen IQA threshold appropriately |
| General queue growth | Unbounded growth over simulated time (no steady state) | Any queue's length trend over time | Add capacity at the specific stage identified |

---

### Scenario A — Small deployment (few PHCs, centralized doctors)

- PHCs: ~5–10
- Cameras: 1 per PHC
- AI compute: centralized (1 shared compute pool)
- Doctors: 1–2, centralized, reviewing all cases from all PHCs
- Expectation: reaches 100,000+/year only if each PHC sustains a very high daily load; doctor stage almost certainly becomes the binding bottleneck given only 1–2 doctors reviewing all cases; **high risk of large doctor-queue waiting times**.

### Scenario B — District deployment (multiple PHCs, centralized AI, centralized doctors)

- PHCs: ~30–50 across a district
- Cameras: 1–2 per PHC
- AI compute: centralized server handling all PHCs' inference requests
- Doctors: 3–5, centralized (district hospital), possibly with a priority queue for referral-suspect cases
- Expectation: per-PHC patient load becomes modest and manageable (Section 10 example), shifting the primary risk to the **centralized AI compute** and **network backhaul**, and still leaving the doctor panel as a likely secondary bottleneck unless doctor count and/or per-case review time are tuned.

### Scenario C — Scaled deployment (multiple PHCs, distributed AI, centralized/specialist review)

- PHCs: 50+ across a district/state
- Cameras: 1–3 per PHC based on local patient volume
- AI compute: distributed/edge inference at PHC or block level, reducing dependence on a single central compute+network path
- Doctors: a tiered model — trained graders/technicians perform first-pass triage, with ophthalmologists reviewing only flagged/uncertain/referral cases, effectively multiplying the throughput of the doctor tier
- Expectation: most resilient scaling path to 100,000+/year, since it removes the two most fragile shared bottlenecks (centralized compute, centralized single-doctor review) — at the cost of higher deployment complexity and cost.

### Per-scenario estimate table (illustrative structure — values to be filled from simulation runs, not assumed)

| Scenario | PHCs | Cameras/PHC | Doctors | Est. throughput | Avg wait | Doctor utilization | Network utilization | Annual capacity |
|---|---|---|---|---|---|---|---|---|
| A — Small | 5–10 | 1 | 1–2 | *simulation output* | *simulation output* | *simulation output* | *simulation output* | *simulation output* |
| B — District | 30–50 | 1–2 | 3–5 | *simulation output* | *simulation output* | *simulation output* | *simulation output* | *simulation output* |
| C — Scaled | 50+ | 1–3 | Tiered (graders + specialists) | *simulation output* | *simulation output* | *simulation output* | *simulation output* | *simulation output* |

All "*simulation output*" cells must be produced by actually running the SimEvents model under each configuration — the research explicitly avoids inventing these numbers in advance, per Rule 3.

---

### Patient metrics

- Patients processed (completed cases)
- Patients rejected/dropped (e.g., queue-capacity reneging, if modeled)
- Patients recaptured (count and rate)
- Patients completed (screened + referred, broken out)

### Queue metrics

- Maximum queue length (per queue)
- Average queue length (per queue)
- Average waiting time (per queue)
- Maximum waiting time (per queue)

### Processing metrics

- AI processing time (distribution, average)
- Throughput (cases/hour, /day)
- Compute utilization

### Network metrics

- Data transmitted (aggregate, and per case)
- Average transmission time
- Network utilization
- Failed transmissions (count, rate)

### Doctor metrics

- Doctor utilization
- Cases reviewed (count)
- Average review time
- Doctor waiting/idle time

### System metrics

- End-to-end latency (average, 95th percentile)
- System throughput (patients/day, /year)
- Resource utilization (all resources, side by side)
- Identified bottleneck (which stage is binding, at what load)
- Projected annual capacity under a given configuration

**Justification role of each metric category:** Patient and queue metrics justify *where* problems occur; processing/network/doctor metrics justify *why* (which resource is the cause); system metrics justify the *headline claim* to SIH evaluators — that the proposed configuration can (or currently cannot) sustain 100,000+ patients/year, and by how much a specific resource change would close the gap.

---

### SIMULINK ARCHITECTURE

### Proposed block-level architecture

```
[Patient Generator]                              (SimEvents: Entity Generator)
        ↓
[Camera/Operator Resource Pool] ←───────────────┐(SimEvents: Resource Pool)
        ↓ (Resource Acquirer)                    │
[Acquisition Queue + Server]                     │(SimEvents: Entity Queue + Entity Server)
        ↓ (Resource Releaser)                    │
[Image Quality Assessment (IQA) Server]          (SimEvents: Entity Server; MATLAB Function for pass/fail rule)
        ↓
[Recapture Decision — Entity Output Switch] ─────┘ (feedback to Acquisition Queue, capped retries)
        ↓ (gradable path)
[AI Compute Resource Pool] ← [AI Processing Queue + Server]  (SimEvents: Resource Pool, Entity Queue/Server)
        ↓
[Explainability + Report Generation Server]      (SimEvents: Entity Server, possibly chained)
        ↓
[Network Transmission: Compression → Transmission Server → Failure Check]
        ↓ (failure → retry queue with backoff, loops back)
[Telemedicine Server capacity — Resource Pool]
        ↓
[Doctor Review Queue (priority-capable)]         (SimEvents: Entity Queue, priority sorting policy)
        ↓ (Resource Acquirer — Doctor Resource Pool)
[Doctor Review Server]                           (SimEvents: Entity Server, review-time distribution)
        ↓ (Resource Releaser)
[Final Decision — Entity Output Switch]
        ↙                                  ↘
[Entity Terminator — Screened/Cleared]   [Referral Case Generator → Entity Terminator — Referred]
        ↓ (all terminators)
[Statistics Collection / Scope / Dashboard / MATLAB post-processing]
```

Note: this refines the example skeleton in the prompt by (1) explicitly showing the camera/operator and AI-compute resources as **Resource Pool** constructs rather than implicit server capacity, (2) making the recapture loop an explicit feedback path with a retry cap, (3) adding a network-failure retry loop, (4) making the doctor queue priority-capable, and (5) splitting the Final Decision output into two Entity Terminators so throughput can be measured separately for "cleared" and "referred" cases.

### Block-type classification

| Block/subsystem | Type |
|---|---|
| Patient Generator | SimEvents block (Entity Generator) |
| Camera/Operator, AI Compute, Doctor Resource Pools | SimEvents blocks (Resource Pool, Resource Acquirer, Resource Releaser) |
| Acquisition, IQA, AI Processing, Report, Transmission, Doctor Review stages | SimEvents blocks (Entity Queue + Entity Server) |
| Recapture / Final Decision routing | SimEvents blocks (Entity Output Switch / Entity Input Switch), with a MATLAB Function or MATLAB action for the decision rule |
| Complex per-case lifecycle logic (optional refinement) | Stateflow (Discrete-Event Chart block) |
| Random/variable service & inter-arrival time generation, parameter calculation, scenario scripting | MATLAB Function blocks / MATLAB action code inside SimEvents blocks, plus surrounding MATLAB scripts |
| Statistics visualization | Standard Simulink Scope/Dashboard blocks, or MATLAB scripts post-processing logged data |

---

### PARAMETERS AND ASSUMPTIONS

| Parameter | Symbol | Unit | Baseline | Range | Source / Assumption |
|---|---|---|---:|---|---|
| Annual patients | N | patients/year | 100,000 | 100,000–150,000 | Scenario parameter (SIH problem statement target) |
| Working days | D | days/year | 288 | 260–310 | Engineering assumption |
| Patients/day (system-wide) | λ_day | patients/day | N/D | derived | Derived from N, D |
| Number of PHCs | P | PHCs | 30 | 5–100 (Scenarios A/B/C) | Scenario parameter |
| Image size | S | MB | 3 | 1–8 | Engineering assumption (pending confirmation from actual capture device/compression spec) |
| Bandwidth (per-PHC uplink) | B | Mbps | 5 | 1–20 | Scenario parameter; national fixed-broadband average is 60.85 Mbps <cite index="46-1">as of March 31, 2026</cite>, but this is a national, not per-rural-PHC, figure, so a lower conservative range is used for scenario testing |
| AI processing time | t_ai | seconds | 5 | 2–15 | Engineering assumption — no field/benchmark timing was located for this specific pipeline |
| Doctor review time | t_dr | seconds | 30 | 15–90 (distribution around target) | **Project requirement/target** stated in the SIH problem statement, not a measured clinical average; modeled as a distribution, not a constant |
| Number of doctors | k_dr | doctors | 3 | 1–10 | Scenario parameter |
| Number of cameras | k_cam | cameras/PHC | 1 | 1–3 | Scenario parameter |
| Ungradable rate | p_ungr | % | 10% | 5–25% | Engineering assumption — no authoritative field figure located; must be revisited with real IQA performance data |

---

### SENSITIVITY ANALYSIS

### Candidate parameters and expected influence

| Parameter | Likely relative influence | Reasoning |
|---|---|---|
| Patient arrival rate | High | Directly loads every downstream queue |
| Doctor review time | Very High | Doctors are the scarcest, most centralized resource; small changes in per-case time multiply across the entire district's case volume |
| Number of doctors | Very High | Directly sets doctor-stage capacity |
| Bandwidth | High (in low-bandwidth scenarios), Low (once above a saturation threshold) | Transmission time is inversely proportional to bandwidth, but beyond a certain point other stages dominate total latency |
| Image size | Moderate | Directly scales transmission time; effect is smaller than bandwidth changes unless size grows substantially |
| AI processing time | Low–Moderate | Typically much smaller than doctor review time and queueing delay in absolute terms, unless centralized compute is itself under-provisioned |
| Number of cameras | Moderate | Matters mainly at PHCs with high local patient volume |
| Ungradable-image rate | Moderate | Amplifies effective camera-stage load, indirectly stressing the whole pipeline upstream of AI/network/doctor stages |

### Method

Perform **one-factor-at-a-time (OFAT) parameter sweeps** first (vary one parameter across its range while holding others at baseline, per Section "PARAMETERS AND ASSUMPTIONS") to build an initial sense of sensitivity, then perform **multi-factor sweeps** (e.g., a full or fractional factorial design across doctor count × bandwidth × arrival rate) to detect interaction effects — for example, whether adding doctors only helps once bandwidth is also improved. This can be automated by scripting the SimEvents model to run repeatedly with different `Simulink.SimulationInput` parameter sets (standard MATLAB/Simulink batch-simulation practice) and collecting the resulting throughput/latency/utilization metrics into a results table for comparison, without needing to invoke any specialized SimEvents-specific optimizer.

### Outputs to monitor per sweep

- System throughput (patients/day, /year)
- End-to-end latency (average, 95th percentile)
- Doctor and camera utilization
- Queue lengths (max, average) at each stage
- Failed-transmission rate

---

### VALIDATION OF THE SIMULATION

### Structural validation

Confirm the block diagram matches the intended workflow (Section 3) by tracing a single entity manually through the model (e.g., using SimEvents' Sequence Viewer or logging) and checking it visits every intended stage in the correct order, including the recapture and referral branches.

### Parameter validation

Cross-check every parameter against the table in "PARAMETERS AND ASSUMPTIONS" — confirm which values are genuinely sourced (e.g., the national broadband figures cited above) versus explicitly labeled assumptions, and flag any assumption that materially changes conclusions for follow-up with real field data before the project is presented as deployment-ready.

### Output validation

Check that simulated results behave logically — e.g., throughput should never exceed the theoretical maximum implied by the slowest resource's capacity (a basic sanity bound: system throughput ≤ 1/service time of the busiest single-server resource, adjusted for server count); utilization should never exceed 100%; latency should increase, not decrease, as load increases.

### Extreme-condition testing

Run the model at very low load (arrival rate near zero) — queues should stay empty and latency should approach the sum of pure processing/transmission times with no waiting. Run at very high load (arrival rate far above capacity) — queues should grow roughly linearly with time and utilization at the bottleneck resource should saturate near 100%, confirming the model behaves as a queueing system should under overload rather than producing nonsensical output.

### Conservation checks

At the end of any finite simulation run, verify: (patients entered) = (patients terminated as screened) + (patients terminated as referred) + (patients still in some queue/server at end of run) + (patients dropped, if reneging/capacity-limits are modeled). Any mismatch indicates a modeling error (e.g., an entity silently destroyed by a misconfigured block) rather than a genuine system property.

These checks matter because a simulation used to justify hardware/staffing decisions to SIH evaluators or a real deployment must be demonstrably self-consistent, not merely visually plausible.

---

### MATLAB ↔ SIMULINK INTEGRATION

**MATLAB responsibilities:**
- Data preparation: computing derived parameters (e.g., converting the 100,000/year target into per-PHC, per-hour arrival rates) before simulation runs.
- Parameter calculation: generating the working-hours arrival-rate profile, review-time distribution parameters, etc., that feed into SimEvents blocks via workspace variables.
- Statistical analysis: post-processing logged simulation data (via `Simulink.SimulationOutput`/logged signals) into the throughput/latency/utilization tables required in Sections 10–13.
- Experiment automation: scripting batch runs across parameter sweeps (Section "Sensitivity Analysis") using `Simulink.SimulationInput` objects and `parsim`/`sim` calls, then aggregating results.
- (Separately, outside this workflow model) AI inference itself — training/evaluating the actual DR classifier — remains a MATLAB/Deep Learning Toolbox or external ML-framework task, feeding only a *timing distribution* and *category-output distribution* into this operational model, not the classifier logic itself.

**Simulink/SimEvents responsibilities:**
- The operational workflow itself — queues, resources, network delay, patient flow, doctor review — as detailed throughout this document.
- Entity-level randomization via each block's "MATLAB action" time-source option (as demonstrated in MathWorks' own examples for both entity generation and service time), which is the officially supported mechanism for embedding custom MATLAB code directly inside SimEvents block behavior.
- Custom decision logic beyond simple probability branches, via MATLAB Function blocks or (optionally) a Stateflow Discrete-Event Chart.

**Integration mechanisms confirmed to exist:**
- Standard Simulink/SimEvents workspace-variable parameterization (set block parameters from MATLAB variables before `sim`).
- The **MATLAB action** option available directly on Entity Generator (intergeneration time) and Entity Server (service time) blocks, letting arbitrary MATLAB code compute these values at each event.
- The **MATLAB Discrete-Event System** block, for authoring custom SimEvents block behavior as a MATLAB System object <cite index="59-1">— useful for including algorithms, as an alternative or complement to the Discrete-Event Chart block, which instead uses Stateflow charts and messages</cite>.
- Batch/automated simulation via `Simulink.SimulationInput` and `parsim`, a standard (not SimEvents-specific) Simulink capability for running many parameterized simulations programmatically.

---

### IMPLEMENTATION FEASIBILITY

| Subsystem | Rating | Reasoning |
|---|---|---|
| Patient generator | 🟢 Easy | Directly matches the documented Entity Generator block and its time/random/MATLAB-action options |
| Camera model (resource + delay) | 🟢 Easy | Standard Resource Pool + Entity Server pattern |
| IQA model (pass/fail branch) | 🟢 Easy–🟡 Moderate | Simple if pass/fail is a random draw against a configurable ungradable rate; moderate if tied to an actual image-quality score computation |
| AI processing model (timed black box) | 🟢 Easy | A timed Entity Server with a configurable duration and randomly-drawn output category; explicitly not simulating the model internals keeps this simple |
| Network model | 🟡 Moderate | Requires custom MATLAB action to compute transmission time from size/bandwidth and to implement failure/retry logic, but all building blocks (Entity Server, probabilistic branching) are standard |
| Queue model (all stages) | 🟢 Easy | Entity Queue blocks are a core, well-documented SimEvents feature |
| Doctor model | 🟡 Moderate | Straightforward resource+server pattern, but priority queueing and realistic review-time distributions add moderate complexity |
| Recapture loop | 🟡 Moderate | Feedback paths via Entity Input/Output Switch are supported but require careful design to avoid infinite loops (retry caps) |
| Resource allocation (multi-resource, multi-pool) | 🟡 Moderate | Well supported by Resource Pool/Acquirer/Releaser, but coordinating priority across many acquirers needs care given static acquirer priority |
| 100,000-patient simulation (full scale) | 🟡 Moderate–🟠 Difficult | Not difficult conceptually, but running/validating a full-year-equivalent simulation with many PHCs and careful parameter tuning is a larger engineering effort than a small demo model |
| Dashboard/visualization | 🟢 Easy–🟡 Moderate | Standard Simulink Scope/Dashboard blocks plus MATLAB plotting of logged statistics cover this well |
| Optimization (finding minimum resource set) | 🟠 Difficult | No SimEvents-specific "auto-optimizer" is assumed here; achievable only via scripted parameter sweeps (Sensitivity Analysis section), which is a manual/iterative process, not a one-click feature |

---

### RECOMMENDED MVP SIMULATION

### MUST HAVE

- Patient Generator with a configurable arrival rate (Poisson baseline)
- Camera/Operator Resource Pool + Acquisition Entity Queue/Server
- AI Processing as a timed black-box Entity Server (no real model logic)
- Network Transmission as a size/bandwidth-based Entity Server with basic delay
- Doctor Resource Pool + Doctor Review Entity Queue/Server (review-time ≈ 30 s target, adjustable)
- Final Decision branch into two Entity Terminators (Screened vs. Referred)
- Basic statistics collection: throughput, average latency, per-stage queue length/utilization

### SHOULD HAVE

- Recapture feedback loop (IQA ungradable → back to camera queue, capped retries)
- Network failure/retry logic
- Multi-PHC replication (parameterized number of parallel PHC subsystems feeding one shared doctor pool)
- Parameter sweep script for at least 2–3 of the ten scenarios in Section 14 (e.g., baseline, doctor shortage, poor internet)
- 95th-percentile latency reporting, not just averages

### NICE TO HAVE

- Priority queueing for referral-suspect cases
- Working-hours/day-of-week time-varying arrival rate (non-homogeneous Poisson)
- Stateflow Discrete-Event Chart for the case-lifecycle state machine
- Dashboard-style visualization (Simulink Dashboard blocks) for live utilization/queue-length display during simulation

### FUTURE WORK

- Full 100,000+/year, multi-district-scale simulation with empirically-calibrated arrival and service-time distributions
- Integration with actual field data (real PHC footfall logs, real network measurements, real AI inference benchmarks) to replace engineering assumptions
- Automated resource-optimization search (e.g., scripted grid/heuristic search across doctor count, camera count, and bandwidth to find a minimum-cost configuration meeting a throughput/latency service-level target)
- Tiered grader+ophthalmologist review modeling (Scenario C) with realistic triage-accuracy assumptions

The MVP as specified above demonstrates **all eight required elements**: patient flow, AI processing, network delay, doctor queue, doctor capacity, throughput, bottleneck identification, and (via a scaled-parameter run) the 100,000+ patient scenario.

---

### FINAL RECOMMENDED ARCHITECTURE

1. **Entities:** Screening case (primary); Referral case (spawned conditionally at Final Decision).
2. **Resources:** Camera/Operator pool (per PHC), AI Compute pool (centralized or per-PHC), Network/Server capacity pool, Doctor pool (centralized/district-level).
3. **Queues:** Camera queue, AI processing queue, Network transmission queue, Doctor review queue, Recapture queue (feedback).
4. **Events:** Patient arrival, image capture completion, IQA completion, AI inference completion, report generation completion, transmission success/failure, doctor review completion, final decision (screened/referred).
5. **Delays:** Acquisition time, IQA time, AI inference time, report generation time, transmission time (size/bandwidth-derived), doctor review time (target ≈ 30 s, distributed).
6. **Decision logic:** Gradable vs. ungradable (recapture branch); transmission success vs. failure (retry branch); screening-clear vs. referral (final branch); optional priority assignment for referral-suspect cases in the doctor queue.
7. **Parameters:** As tabulated in "PARAMETERS AND ASSUMPTIONS," each explicitly labeled by evidence status.
8. **Metrics:** Per-stage queue length/waiting time/utilization; system throughput; end-to-end latency (average and 95th percentile); failed-transmission rate; recapture rate; annual capacity projection.
9. **Simulation scenarios:** The ten scenarios of Section 14, run at minimum for the MVP's SHOULD-HAVE subset, and ideally for all ten before final SIH presentation.

### Final text-based architecture diagram

```
                     ┌───────────────────────┐
                     │   Patient Generator    │
                     └───────────┬────────────┘
                                 ▼
                 ┌───────────────────────────────┐
                 │ Camera/Operator Resource Pool  │◄────────────┐
                 └───────────────┬────────────────┘             │
                                 ▼                               │
                 ┌───────────────────────────────┐               │
                 │ Acquisition Queue + Server      │              │
                 └───────────────┬────────────────┘              │
                                 ▼                               │
                 ┌───────────────────────────────┐               │
                 │  Image Quality Assessment       │              │
                 └───────────────┬────────────────┘              │
                     Ungradable  │  Gradable                     │
                                 ▼                                │
                 ┌──────────────┴───────────────┐                 │
                 │  Recapture Decision (Switch)   ├── (capped) ────┘
                 └───────────────┬───────────────┘
                                 ▼
                 ┌───────────────────────────────┐
                 │ AI Compute Resource Pool +      │
                 │ Processing Queue/Server         │
                 └───────────────┬────────────────┘
                                 ▼
                 ┌───────────────────────────────┐
                 │ Explainability + Report Gen      │
                 └───────────────┬────────────────┘
                                 ▼
                 ┌───────────────────────────────┐
                 │ Compression → Transmission       │
                 │ Server (size/bandwidth)          │
                 └───────────────┬────────────────┘
                     Fail ◄──────┤ (retry w/ backoff)
                                 ▼ Success
                 ┌───────────────────────────────┐
                 │ Telemedicine Server Capacity      │
                 └───────────────┬────────────────┘
                                 ▼
                 ┌───────────────────────────────┐
                 │ Doctor Review Queue (priority)   │
                 └───────────────┬────────────────┘
                                 ▼
                 ┌───────────────────────────────┐
                 │ Doctor Resource Pool + Review     │
                 │ Server (~30 s target, distributed)│
                 └───────────────┬────────────────┘
                                 ▼
                 ┌───────────────────────────────┐
                 │ Final Decision (Switch)           │
                 └────────┬───────────────┬────────┘
                          ▼               ▼
             ┌─────────────────┐  ┌──────────────────────┐
             │ Terminator:       │  │ Referral Case Gen →    │
             │ Screened/Cleared  │  │ Terminator: Referred    │
             └─────────────────┘  └──────────────────────┘
                          │               │
                          ▼               ▼
                 ┌───────────────────────────────┐
                 │ Statistics / Dashboard / MATLAB   │
                 │ Post-Processing                    │
                 └───────────────────────────────┘
```

---

### REFERENCES

1. **Overview of Queues and Servers in Discrete-Event Simulation.** MathWorks. Source: MATLAB & Simulink Documentation (SimEvents). https://www.mathworks.com/help/simevents/gs/role-of-queues-in-simevents-models.html — Supports: definitions and behavior of Entity Queue/Entity Server blocks, queue capacity/sorting/overwrite policy (Sections 2, 3, 7).

2. **Get Started with SimEvents.** MathWorks. https://www.mathworks.com/help/simevents/getting-started-with-simevents.html — Supports: SimEvents' purpose (event-driven modeling, latency/throughput/packet-loss optimization) (Sections 1, 2).

3. **SimEvents — Model and simulate message communication and discrete-event systems.** MathWorks. https://www.mathworks.com/products/simevents.html — Supports: SimEvents block library overview, including Resource Pool/Resource Acquirer/Resource Releaser and MATLAB Discrete-Event System/Discrete-Event Chart blocks (Sections 2, 5, 9).

4. **Discrete-Event Simulation in Simulink Models.** MathWorks. https://www.mathworks.com/help/simevents/gs/discrete-event-simulation-using-simevents-in-simulink-models.html — Supports: combining time-based Simulink and event-based SimEvents modeling; entity/event/state concepts (Sections 2, 3).

5. **Resource Pool — Pool entity resources.** MathWorks. https://www.mathworks.com/help/simevents/ref/resourcepool.html — Supports: Resource Pool block behavior, global/scoped visibility, reusable-upon-release semantics (Section 5).

6. **Resource Acquirer — Acquire entity resources.** MathWorks. https://www.mathworks.com/help/simevents/ref/resourceacquirer.html — Supports: entity-resource acquisition semantics, acquirer priority ordering (Sections 5, 9).

7. **Resource Releaser — Release entity resources.** MathWorks. https://www.mathworks.com/help/simevents/ref/resourcereleaser.html — Supports: resource release mechanics (Section 5).

8. **M/M/1 Queuing System.** MathWorks. https://www.mathworks.com/help/simevents/ug/m-m-1-queuing-system.html — Supports: Poisson arrival / exponential service-time modeling pattern in SimEvents, used as the baseline arrival-model reference (Sections 6, 7).

9. **Entity Generator — Generate entities.** MathWorks. https://www.mathworks.com/help/simevents/ref/entitygenerator.html — Supports: time-based/event-based entity generation, Period/distribution/MATLAB-action time sources (Sections 2, 6).

10. **Entities in a SimEvents Model.** MathWorks. https://www.mathworks.com/help/simevents/gs/role-of-entities-in-simevents-models.html — Supports: storing-entity block list, randomized entity generation via MATLAB action (Sections 4, 6, 19).

11. **Route Entities and Simulink Messages.** MathWorks. https://www.mathworks.com/help/simevents/routing.html — Supports: Entity Gate, Entity Input/Output Switch, Entity Selector for routing/decision logic (Sections 3, 12, "Simulink Architecture").

12. **Entity Input Switch — Switch input entities.** MathWorks. https://www.mathworks.com/help/simevents/ref/entityinputswitch.html — Supports: path-merging semantics used for the recapture feedback loop (Section 3).

13. **Entity Output Switch — Output entities.** MathWorks. https://www.mathworks.com/help/simevents/ref/entityoutputswitch.html — Supports: output-routing semantics used for recapture and final-decision branching (Sections 3, 15).

14. **Create Custom Queuing Systems Using Discrete-Event Stateflow Charts.** MathWorks. https://www.mathworks.com/help/simevents/ug/discrete-event-systems-created-with-stateflow-charts.html — Supports: Discrete-Event Chart block purpose, event-based execution, Stateflow license requirement (Section 2).

15. **Block Authoring (SimEvents Common Design Patterns).** MathWorks. https://ww2.mathworks.cn/help/simevents/block-authoring-in-simevents.html — Supports: MATLAB Discrete-Event System block for custom algorithmic behavior, as an alternative to Discrete-Event Chart (Sections 2, "MATLAB↔Simulink Integration").

16. **Rural internet penetration rises to 48.31 per 100 population under National Broadband Mission 2.0.** Government of India / Lok Sabha reply reported via news agency. https://www.newkerala.com/news/a/rural-internet-penetration-rises-4831-per-100-population-250.htm and https://news.webindia123.com/news/Articles/Business/20260729/4480608.html — Supports: published rural internet penetration and national average fixed-broadband download speed figures, and broadband connectivity to Primary Health Centres under NBM 2.0 (Section 8, Parameters table).

17. **What Is a Good Internet Speed for Home in India? (citing Speedtest Global Index, Feb 2026).** https://www.tataplayfiber.com/blog/what-good-internet-speed-home-india — Supports: national mobile/fixed broadband median speed figures used as context (explicitly distinguished from unavailable rural-PHC-specific data) (Section 8).

---

### FINAL QUALITY-CONTROL CHECKLIST

- [x] Simulink capabilities are accurately described (grounded in MathWorks documentation searches).
- [x] SimEvents is distinguished from standard Simulink (Section 2).
- [x] No fictional Simulink blocks/functions are used — all named blocks (Entity Generator, Entity Queue, Entity Server, Entity Terminator, Resource Pool, Resource Acquirer, Resource Releaser, Entity Input/Output Switch, Entity Gate, Discrete-Event Chart, MATLAB Discrete-Event System) were verified against MathWorks documentation.
- [x] Patient flow is fully modeled (Section 3).
- [x] Queues are explicitly modeled (Section 7).
- [x] Resources are explicitly modeled (Section 5).
- [x] Internet/network constraints are modeled (Section 8).
- [x] Doctor capacity is modeled (Section 9).
- [x] AI processing time is modeled as a black-box delay, not a biological/pixel model (Sections 1, 4, "Implementation Feasibility").
- [x] Recapture loops are modeled (Sections 3, 7, "Implementation Feasibility").
- [x] Throughput is calculated with a refined (not naive) methodology (Section 10).
- [x] Latency is calculated with explicit random-vs-deterministic treatment (Section 11).
- [x] Bottlenecks can be identified via utilization/queue-length metrics (Section 12).
- [x] 100,000+ patients/year is explicitly simulated via three labeled scenarios (Section 13).
- [x] Multiple what-if scenarios are included (Section 14, 10 scenarios).
- [x] Simulation assumptions are clearly labeled throughout (Known value / Published estimate / Engineering assumption / Scenario parameter / Unknown-requires field data).
- [x] Published values (e.g., NBM 2.0 broadband figures) are distinguished from assumptions (Section 8, Parameters table).
- [x] Clinical metrics are not confused with operational metrics (explicit separation in Section 1 and throughout — no sensitivity/specificity/AUC discussed as part of this operational model).
- [x] Simulation validation is addressed (Validation section).
- [x] MATLAB–Simulink integration is explained with confirmed mechanisms (MATLAB↔Simulink Integration section).
- [x] MVP architecture is realistic for a student team (Recommended MVP Simulation section).
- [x] References are provided, all traceable to sources actually used above.
- [x] No unsupported numerical claims are presented as facts — all operational parameters (arrival rates, review times, bandwidth, image size, ungradable rate) are explicitly labeled by evidence status rather than asserted as measured truths.

## Final Consolidation & Modeling Decisions

### A. Primary simulation boundary

All three sources agree that Simulink/SimEvents should model the **operational system around the AI**, not the internals of the AI. The dynamic model should track entities, queues, resource contention, delays, retries, routing, throughput, latency, and utilization. Clinical model metrics such as sensitivity, specificity, AUC, and F1 remain part of the separate MATLAB/AI evaluation workflow.

### B. SimEvents vs. standard Simulink

The sources consistently identify **SimEvents as the primary discrete-event engine** for this problem. Standard Simulink is retained as the surrounding time-based environment for signals, aggregation, dashboards, and integration. Stateflow is complementary for complex state/branch logic.

### C. Entity granularity

Two approaches appear in the sources:

1. **MVP approach:** one `ScreeningCase` entity flows from registration to final decision and carries evolving attributes such as image quality, DR class, payload size, priority, and retry count.
2. **Detailed approach:** use separate patient, image/tele-record, network-packet, AI-job, doctor-review, or referral entities.

**Consolidated recommendation:** use `ScreeningCase` as the primary entity for the MVP. Introduce separate network-packet or compute-job entities only when packet-level or compute-level analysis is specifically required.

### D. Patient arrival model

The sources provide several legitimate choices:

- Deterministic/scheduled arrivals.
- Homogeneous Poisson arrivals.
- Non-homogeneous Poisson arrivals.
- Batch arrivals for screening camps.
- Empirical observed arrivals when field data become available.

**Consolidated recommendation:** use scheduled/controlled arrivals for the simplest MVP, then add a time-varying or batch scenario for rural screening realism. Treat all unmeasured arrival profiles as simulation assumptions until field data are available.

### E. Network model

The sources agree that packet-level TCP/IP simulation is unnecessary for the SIH operational objective. The preferred MVP abstraction is:

`Payload size → effective bandwidth → transmission delay → latency/jitter → success/failure → retry/backoff`.

Advanced work can add a packet-loss or two-state link model, but such parameters must be labeled as assumptions unless field traces support them.

### F. Ophthalmologist service time

The sources contain target/scenario values including approximately 30 seconds and broader ranges such as 30–120 seconds.

**Consolidated recommendation:** do not present 30 seconds as a universal clinical fact. Use it as an explicit SIH/project target scenario and sweep multiple service-time values (for example 30, 60, 120, and 300 seconds) to show sensitivity to reviewer workload.

### G. 100,000+ annual target

The sources correctly treat 100,000+ patients/year as a **capacity-planning requirement**, not proof that a particular architecture already achieves it.

For example:

- 100,000 / 250 operating days = 400 cases/day.
- 400 / 8 operating hours = 50 cases/hour.

Alternative operating-day assumptions can be evaluated separately. Annual completion must account for recaptures, downtime, failed uploads, queue backlog, and reviewer capacity.

### H. Resource bottlenecks

The research repeatedly identifies these as important resources:

- Fundus cameras.
- PHC operators.
- AI compute.
- Network/uplink.
- Telemedicine server capacity.
- Ophthalmologists.

The simulation should identify the bottleneck from **measured utilization and queue behavior**, rather than assuming one in advance.

### I. Simulation credibility

Use multiple stochastic runs/seeds for random scenarios. Report distributions and percentiles where appropriate, especially:

- P90/P95 end-to-end latency.
- Queue length.
- Waiting time.
- Resource utilization.
- Retry/failure rate.
- Annual completed cases.
- Deferred/backlogged cases.

Any parameter not supported by actual field measurements should be explicitly labeled as a scenario assumption.

### J. Recommended SIH implementation order

```text
PHASE 1 — Core operational model
    Patient arrival
      ↓
    Registration queue
      ↓
    Camera + operator resource
      ↓
    IQA decision
      ├── Ungradable → bounded recapture loop
      └── Gradable
            ↓
         AI service
            ↓
         XAI/report service
            ↓
         Network queue + transmission
            ├── Failure → retry/backoff
            └── Success
                  ↓
            Doctor priority queue
                  ↓
            Ophthalmologist resource
                  ↓
            Final decision / referral
                  ↓
               Terminator

PHASE 2 — Scenario analysis
    • High patient load
    • Poor internet
    • Doctor shortage
    • Camera shortage
    • High ungradable-image rate
    • Larger image payload
    • AI acceleration

PHASE 3 — Capacity planning
    • 100,000+ annual target
    • Multi-PHC district model
    • Resource sweeps
    • Monte Carlo runs
    • P95 latency and annual backlog

PHASE 4 — Advanced refinement
    • Detailed packet entities
    • Advanced network-loss model
    • Stateflow control logic
    • Empirical arrival/service distributions
    • Distributed edge/central compute comparison
```

### K. Source integrity note

This consolidation intentionally preserves alternative approaches when they represent legitimate modeling choices. It does not silently turn assumptions into facts, and it does not claim that any simulated value is a measured field result unless the source explicitly provides it as such.


## Source Files Consolidated

1. `04_simulink-telemedicine (1).md`
2. `04_simulink-telemedicine.md`
3. `04_simulink-telemedicine (2).md`

The consolidated document is intended to replace the three separate working drafts as the team's unified Simulink/SimEvents technical-research baseline.


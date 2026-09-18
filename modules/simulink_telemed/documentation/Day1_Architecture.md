# Role 3 — Day 1 Architecture

## Objective

Build and validate the core discrete-event topology
for the diabetic retinopathy screening digital twin.

## Entity Definition

Each entity represents one fundus screening packet.

## Entity Attributes

- retry_count
  - Integer
  - Initial value = 0

- iqa_status
  - 0 = IQA failure
  - 1 = IQA pass

- dr_severity
  - Integer from 0 to 4

- confidence_level
  - 1 = High
  - 2 = Medium
  - 3 = Low/Ambiguous

- iqa_route
  - 1 = FAIL
  - 2 = PASS

- retry_route
  - 1 = RETRY
  - 2 = UNGRADABLE

- review_route
  - 1 = NORMAL
  - 2 = HUMAN REVIEW

- review_priority
  - 1 = Lower priority
  - 2 = Medium priority
  - 3 = Highest priority

## Primary Flow

Entity Generator
→ Input Switch
→ Main Screening Queue
→ IQA + Edge Preprocessing
→ Quality Gate
→ AI Processing
→ Confidence/Severity Routing
→ Human Review or Structured Report

## Recapture Logic

If:

iqa_status == 0

and retry_count < 2,

then:

retry_count = retry_count + 1

and the entity returns to the IQA stage.

If the maximum retry count is reached,
the entity is routed to the Ungradable / Discard path.

## Human Review Logic

A case enters human review when:

confidence_level == 3

OR

dr_severity >= 2

Otherwise it proceeds to the normal structured report path.

## AI Processing

The AI stage is represented by an Entity Server
named:

CNN Inference + Grad-CAM

The server currently uses:

ai_processing_time

as its service time.

The actual CNN and Grad-CAM implementation will be
integrated later using measured processing time from
the MATLAB screening pipeline.

## Human Review

Cases requiring human review are routed to:

Priority Review Queue
→ Ophthalmologist Review Server
→ Reviewed Screening Report

## Day 1 Parameter Status

All numerical processing-time and arrival-rate values
used during Day 1 topology testing are temporary test
values.

Final simulation parameters will be replaced with
measured values from the MATLAB screening pipeline.

## Validation

The Day 1 topology was tested using five entity behaviors:

1. Normal case
2. Low-confidence case
3. Referable DR case
4. Bad-image retry case
5. Repeated bad-image / maximum-retry case

All five intended paths were tested.
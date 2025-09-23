# Lab 9: Jobs and CronJobs

## Duration: 45 minutes

## Objectives
- Create and manage Kubernetes Jobs for batch processing
- Configure CronJobs for scheduled tasks
- Handle job failures and retries
- Monitor job execution and troubleshooting

## Prerequisites
- Lab 8 completed (Health Checks)
- kubectl configured to use your namespace

## Instructions

### Step 1: Clean Up and Create Basic Job
Start with a simple batch job:

```bash
# Clean up previous resources
kubectl delete deployment --all
kubectl delete job --all
kubectl delete cronjob --all

# Create a basic job
sed 's/userX/user1/g' basic-job.yaml > my-basic-job.yaml
kubectl apply -f my-basic-job.yaml

# Check job status
kubectl get jobs
kubectl get pods -l job-name=user1-basic-job
kubectl describe job user1-basic-job
```

### Step 2: Monitor Job Execution
Watch job execution and completion:

```bash
# Monitor job progress
kubectl get job user1-basic-job -w
# Press Ctrl+C after job completes

# Check job completion
kubectl describe job user1-basic-job | grep -A 5 "Conditions"

# View job pod logs
kubectl logs -l job-name=user1-basic-job

# Check job events
kubectl get events --field-selector involvedObject.name=user1-basic-job
```

### Step 3: Parallel Job Processing
Create jobs that run multiple pods in parallel:

```bash
# Create parallel job
sed 's/userX/user1/g' parallel-job.yaml > my-parallel-job.yaml
kubectl apply -f my-parallel-job.yaml

# Watch parallel execution
kubectl get pods -l job-name=user1-parallel-job -w
# Press Ctrl+C after all pods complete

# Check completion count
kubectl describe job user1-parallel-job | grep -E "(Parallelism|Completions|Succeeded)"

# View logs from all pods
kubectl logs -l job-name=user1-parallel-job --prefix=true
```

### Step 4: Job with Failures and Retries
Test job failure handling:

```bash
# Create job that will fail initially
sed 's/userX/user1/g' failing-job.yaml > my-failing-job.yaml
kubectl apply -f my-failing-job.yaml

# Watch job retry attempts
kubectl get job user1-failing-job -w
# Press Ctrl+C after observing retries

# Check failed pods
kubectl get pods -l job-name=user1-failing-job
kubectl describe pod $(kubectl get pods -l job-name=user1-failing-job --field-selector=status.phase=Failed -o jsonpath='{.items[0].metadata.name}')

# View job backoff limit behavior
kubectl describe job user1-failing-job | grep -A 10 "Conditions"
```

### Step 5: Create Basic CronJob
Set up scheduled jobs:

```bash
# Create CronJob that runs every 2 minutes
sed 's/userX/user1/g' basic-cronjob.yaml > my-basic-cronjob.yaml
kubectl apply -f my-basic-cronjob.yaml

# Check CronJob status
kubectl get cronjob user1-basic-cronjob
kubectl describe cronjob user1-basic-cronjob

# Wait for first execution (may take up to 2 minutes)
kubectl get jobs -w
# Press Ctrl+C after seeing job creation

# Check created jobs
kubectl get jobs -l app=scheduled-task
```

### Step 6: CronJob History and Management
Manage CronJob execution history:

```bash
# Check CronJob history
kubectl get jobs -l app=scheduled-task
kubectl get pods -l app=scheduled-task

# View CronJob events
kubectl describe cronjob user1-basic-cronjob | grep -A 10 "Events"

# Suspend CronJob temporarily
kubectl patch cronjob user1-basic-cronjob -p '{"spec":{"suspend":true}}'
kubectl describe cronjob user1-basic-cronjob | grep "Suspend"

# Resume CronJob
kubectl patch cronjob user1-basic-cronjob -p '{"spec":{"suspend":false}}'
```

### Step 7: Complex Scheduled Jobs
Create more sophisticated scheduled tasks:

```bash
# Create data processing CronJob
sed 's/userX/user1/g' data-processing-cronjob.yaml > my-data-processing-cronjob.yaml
kubectl apply -f my-data-processing-cronjob.yaml

# Create backup CronJob
sed 's/userX/user1/g' backup-cronjob.yaml > my-backup-cronjob.yaml
kubectl apply -f my-backup-cronjob.yaml

# Check all CronJobs
kubectl get cronjob
kubectl describe cronjob user1-data-processing-cronjob
kubectl describe cronjob user1-backup-cronjob
```

### Step 8: Job Resource Management
Control job resource usage:

```bash
# Create resource-limited job
sed 's/userX/user1/g' resource-job.yaml > my-resource-job.yaml
kubectl apply -f my-resource-job.yaml

# Monitor resource usage
kubectl get pods -l job-name=user1-resource-job
kubectl top pods -l job-name=user1-resource-job

# Check resource constraints
kubectl describe job user1-resource-job | grep -A 10 "Pod Template"
```

### Step 9: Job Cleanup Policies
Test different job cleanup behaviors:

```bash
# Create job with TTL (time to live)
sed 's/userX/user1/g' ttl-job.yaml > my-ttl-job.yaml
kubectl apply -f my-ttl-job.yaml

# Wait for job completion
kubectl wait --for=condition=complete job/user1-ttl-job --timeout=120s

# Check TTL behavior (job should auto-delete after TTL expires)
kubectl get job user1-ttl-job
sleep 10
kubectl get job user1-ttl-job

# Manually trigger CronJob to test immediate execution
kubectl create job user1-manual-job --from=cronjob/user1-basic-cronjob

# Check manual job execution
kubectl get job user1-manual-job
kubectl logs -l job-name=user1-manual-job
```

### Step 10: Job Troubleshooting
Practice common job troubleshooting scenarios:

```bash
# Create problematic job
sed 's/userX/user1/g' problem-job.yaml > my-problem-job.yaml
kubectl apply -f my-problem-job.yaml

# Diagnose job issues
kubectl describe job user1-problem-job
kubectl get pods -l job-name=user1-problem-job
kubectl logs -l job-name=user1-problem-job

# Check job events and conditions
kubectl get events --field-selector involvedObject.name=user1-problem-job
kubectl describe job user1-problem-job | grep -A 5 "Conditions"

# Delete failed job
kubectl delete job user1-problem-job

# Check CronJob troubleshooting
kubectl describe cronjob user1-basic-cronjob
kubectl get events --field-selector involvedObject.name=user1-basic-cronjob

# View all job-related resources
kubectl get jobs,cronjobs,pods -l owner=user1
```

## Verification Steps

```bash
# 1. Verify jobs completed successfully
kubectl get jobs | grep user1 | grep Complete

# 2. Check CronJobs are scheduled
kubectl get cronjob | grep user1

# 3. Verify job pods executed
kubectl get pods | grep job | grep Completed

# 4. Check job logs contain expected output
kubectl logs -l job-name=user1-basic-job | grep -i success

# 5. Confirm CronJob created jobs
kubectl get jobs -l app=scheduled-task | wc -l
```

## Key Takeaways
- Jobs run pods to completion for batch processing
- CronJobs schedule jobs based on cron expressions
- Parallelism and completions control job execution patterns
- BackoffLimit controls retry behavior for failed jobs
- TTL automatically cleans up completed jobs
- Job troubleshooting involves checking pods, events, and conditions
- Suspend feature allows pausing CronJobs without deletion

## Cleanup
```bash
kubectl delete job user1-basic-job user1-parallel-job user1-failing-job user1-resource-job user1-manual-job
kubectl delete cronjob user1-basic-cronjob user1-data-processing-cronjob user1-backup-cronjob
```

---

**Remember**: Always use your assigned username prefix (userX-) for all resources you create!
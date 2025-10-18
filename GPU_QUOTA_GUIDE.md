# GPU Quota Solutions for Google Cloud

## 🚨 Current Issue: GPU Quota Exceeded

Your project has 0 GPU quota allocated. Here are solutions:

## Solution 1: Request GPU Quota Increase (Recommended)

### Step-by-Step Guide

1. **Go to Google Cloud Console** → IAM & Admin → Quotas
2. **Filter for GPU quotas**:
   - Search for: "GPUs (all regions)"
   - Or: "NVIDIA T4 GPUs"
3. **Select the quota** and click "Edit Quotas"
4. **Fill the request form**:
   - **Quota**: GPUs (all regions) per project
   - **New limit**: 1 (start small)
   - **Reason**: "Need GPU for Ollama LLM inference"
5. **Submit and wait** (usually 2-24 hours, sometimes longer)

### Alternative Quotas to Request

- `GPUs (all regions)` - Global quota
- `NVIDIA T4 GPUs` - Specific GPU type
- `NVIDIA L4 GPUs` - Newer, more efficient

## Solution 2: Use Different Region

Some regions have different quota availability:

```bash
# Try these regions (may have quota available)
gcloud compute regions list

# Popular regions with GPU availability:
# us-central1 (Iowa) - Usually good availability
# us-east1 (South Carolina)
# europe-west4 (Netherlands)
# asia-southeast1 (Singapore)
```

## Solution 3: CPU Deployment (Immediate Solution)

Deploy Ollama on CPU - works great for development:

```bash
chmod +x deploy-cpu.sh
./deploy-cpu.sh your-project-id us-central1
```

**CPU Performance:**

- ✅ No quota issues
- ✅ ~$0.15/hour vs $0.58/hour for GPU
- ✅ Good for development/testing
- ⚠️ Slower inference (5-15s vs 1-3s with GPU)

## Solution 4: Spot Instances (If GPU Quota Available)

Spot instances use spare capacity and are cheaper:

```bash
gcloud compute instances create ollama-spot \
  --provisioning-model=SPOT \
  --machine-type=n1-standard-4 \
  --accelerator=type=nvidia-tesla-t4,count=1 \
  --zone=us-central1-a
```

## Solution 5: Use Pre-built GPU Instances

If you have quota in another project, or use Marketplace:

```bash
# Use AI Platform / Vertex AI (different quota)
# Or use pre-built Ollama instances from Marketplace
```

## Quota Request Tips

### 📝 Request Details to Include

```
Project ID: zyniq-core
Requested quota: 1 GPU (T4)
Duration: Permanent
Use case: Machine learning inference for LLM API service
Expected usage: 8 hours/day, 5 days/week
```

### ⏰ Timeline

- **Basic requests**: 2-24 hours
- **First-time GPU users**: May take 2-3 days
- **Enterprise requests**: Can take a week+

### 📞 Escalation

If no response after 48 hours:

1. Reply to the quota approval email
2. Contact Google Cloud Support
3. Mention your use case and timeline needs

## Cost Comparison

| Option | Cost/Hour | Setup Time | Performance |
|--------|-----------|------------|-------------|
| GPU (T4) | $0.58 | 2-24h | Fast (1-3s) |
| CPU (Cloud Run) | $0.15 | 5 min | Medium (5-15s) |
| Spot GPU | $0.17 | Immediate | Fast (if available) |

## Immediate Actions

1. **Submit GPU quota request** (start this now)
2. **Deploy CPU version** for immediate testing:

   ```bash
   ./deploy-cpu.sh zyniq-core us-central1
   ```

3. **Monitor quota request** status

The CPU deployment will get you running immediately while you wait for GPU quota approval!
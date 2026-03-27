# Porting WhisperX-FastAPI to HPE Private Cloud AI

## What is WhisperX-FastAPI

[WhisperX-FastAPI](https://github.com/pavelzbornik/whisperX-FastAPI) is an open-source speech-to-text transcription service built on FastAPI. It uses [WhisperX](https://github.com/m-bain/whisperX) (faster-whisper + pyannote.audio) to provide:

- Fast speech-to-text transcription via the Whisper model family
- Speaker diarization (who spoke when) via pyannote.audio
- Word-level timestamp alignment
- REST API for audio file upload and async processing

Source repository: https://github.com/pavelzbornik/whisperX-FastAPI (v0.5.1)

## What was changed for PCAI

This Helm chart was created from scratch to deploy the upstream Docker image on HPE Private Cloud AI (AIE v1.8.0) using the BYOA (Bring Your Own Application) framework pattern. No application code was modified.

### PCAI-specific additions

1. **`templates/ezua/virtualservice.yaml`** — Istio VirtualService to expose the application through the PCAI gateway (`istio-system/ezaf-gateway`), making it accessible at `whisperx.${DOMAIN_NAME}`.

2. **`templates/ezua/kyverno.yaml`** — Kyverno ClusterPolicy (runs as a Helm pre-install hook) that injects `hpe-ezua/type: vendor-service` and `hpe-ezua/app: whisperx-fastapi` labels onto all Pods in the release namespace. These labels are required for PCAI to recognize the application as an imported framework.

3. **`hpe-ezua/*` labels in `_helpers.tpl`** — Common labels include `hpe-ezua/type` and `hpe-ezua/app` so that all resources are visible in the PCAI console.

4. **GPU scheduling** — The Deployment requests `nvidia.com/gpu: 1` by default. An optional `runtimeClassName` value is available if the cluster requires it.

5. **PersistentVolumeClaim for model cache** — WhisperX downloads models (~3 GB for large-v3-turbo plus diarization models) to `/root/.cache` on first start. A 20Gi PVC is mounted at this path to avoid re-downloading on pod restarts.

6. **Secret for HuggingFace token** — The `HF_TOKEN` (required by pyannote.audio for speaker diarization) is stored in a Kubernetes Secret rather than passed as a plaintext environment variable.

## How to build the Docker image

Clone the upstream repository and build the image:

```bash
git clone https://github.com/pavelzbornik/whisperX-FastAPI.git
cd whisperX-FastAPI
git checkout v0.5.1

# Build and push to your registry
docker build -t <YOUR_REGISTRY>/whisperx-fastapi:0.5.1 .
docker push <YOUR_REGISTRY>/whisperx-fastapi:0.5.1
```

The upstream Dockerfile handles all dependencies (CUDA, faster-whisper, pyannote.audio, etc.).

## How to configure and deploy

### Option A: Import via PCAI Console

1. Package the chart:
   ```bash
   helm package 0.1.0/whisperx-fastapi/
   ```
2. In PCAI Console, go to **Tools & Frameworks > Import Framework**.
3. Upload `whisperx-fastapi-0.1.0.tgz` and the logo image.
4. Configure the required values:
   - `image.repository` — your registry path
   - `hfToken` — your HuggingFace access token
   - `ezua.virtualService.endpoint` — will be auto-populated by PCAI

### Option B: Helm CLI

```bash
helm install whisperx ./0.1.0/whisperx-fastapi/ \
  --namespace whisperx \
  --create-namespace \
  --set image.repository=<YOUR_REGISTRY>/whisperx-fastapi \
  --set hfToken=hf_xxxxxxxxxx
```

### Key values to configure

| Value | Default | Description |
|-------|---------|-------------|
| `image.repository` | `REGISTRY/whisperx-fastapi` | Container image registry path |
| `hfToken` | `""` | HuggingFace token (required for diarization) |
| `whisperx.model` | `large-v3-turbo` | Whisper model size |
| `whisperx.device` | `cuda` | Inference device (cuda/cpu) |
| `persistence.size` | `20Gi` | Model cache PVC size |
| `resources.limits.nvidia.com/gpu` | `1` | GPU count |

## How to verify it's working

1. Check the pod is running:
   ```bash
   kubectl get pods -n whisperx -l app.kubernetes.io/name=whisperx-fastapi
   ```

2. Check readiness (model download may take a few minutes on first start):
   ```bash
   kubectl logs -n whisperx -l app.kubernetes.io/name=whisperx-fastapi -f
   ```

3. Test the health endpoints:
   ```bash
   # Via port-forward
   kubectl port-forward -n whisperx svc/whisperx-whisperx-fastapi 8000:8000
   curl http://localhost:8000/health
   curl http://localhost:8000/health/ready

   # Via PCAI endpoint (after VirtualService is active)
   curl https://whisperx.<DOMAIN_NAME>/health
   ```

4. Test transcription:
   ```bash
   curl -X POST https://whisperx.<DOMAIN_NAME>/api/v1/transcribe \
     -F "file=@sample.wav" \
     -F "language=en"
   ```

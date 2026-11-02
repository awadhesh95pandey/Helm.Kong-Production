# SSL certificate used by Kong

This is the certificate Kong presents for `https://finone.paisalo.in`.

The live site and the Kubernetes secret `kong-proxy-tls` in namespace `kong-production` use the same leaf certificate.

| | |
|---|---|
| Domain | `*.paisalo.in` and `paisalo.in` |
| Issuer | eMudhra `EM DV TLS CA - G2A-1` |
| Valid from | 20 Oct 2026 09:36 UTC |
| Valid until | 17 Jan 2027 09:36 UTC |
| Thumbprint | `D69DC2B8CF00D61ECAF5101E3F9152D05BC28EC2` |
| Kubernetes secret | `kong-proxy-tls` |
| Secret type | `kubernetes.io/tls` |
| Mounted in the pod | `/etc/kong/tls/tls.crt` and `/etc/kong/tls/tls.key` |

Files in this folder:

- `tls.crt` is the full chain stored in the secret. Kong loads this file.
- `leaf.crt` is only the `*.paisalo.in` server certificate, the first certificate in that chain.

The private key is not in this folder. It stays in the `tls.key` field of the secret. `*.crt` and `*.key` are already listed in `.gitignore`.

## How Kong uses it

1. The Helm chart has `global.tlsEnabled: true` in `helm/values-production.yaml`.
2. The proxy Service `kong-proxy` listens on port 443 and sends that traffic to container port 8443.
3. The Deployment mounts secret `kong-proxy-tls` at `/etc/kong/tls`.
4. Kong is started with:
   - `KONG_SSL_CERT=/etc/kong/tls/tls.crt`
   - `KONG_SSL_CERT_KEY=/etc/kong/tls/tls.key`
   - `KONG_PROXY_LISTEN=0.0.0.0:8000, 0.0.0.0:8443 ssl http2`
   - `KONG_SSL_PROTOCOLS=TLSv1.2 TLSv1.3`

Helm does not create this secret. It must already exist before the pods start.

## 1. Read the certificate that is running

From this repository:

```powershell
kubectl -n kong-production get secret kong-proxy-tls -o jsonpath="{.data.tls\.crt}" |
  ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
```

Check the certificate browsers receive:

```powershell
$tcp = New-Object System.Net.Sockets.TcpClient("finone.paisalo.in", 443)
$ssl = New-Object System.Net.Security.SslStream($tcp.GetStream(), $false, ({ $true }))
$ssl.AuthenticateAsClient("finone.paisalo.in")
$cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($ssl.RemoteCertificate)
$cert.Subject
$cert.Issuer
$cert.Thumbprint
$cert.NotAfter.ToUniversalTime()
$ssl.Dispose(); $tcp.Dispose()
```

The thumbprint must be `D69DC2B8CF00D61ECAF5101E3F9152D05BC28EC2` until this certificate is replaced.

## 2. Files you need when replacing it

From the certificate provider, keep two PEM files:

- `tls.crt` — server certificate first, then the intermediate certificates. Do not put the private key in this file.
- `tls.key` — the matching unencrypted private key, `BEGIN PRIVATE KEY` or `BEGIN RSA PRIVATE KEY`.

The first certificate in `tls.crt` must match `tls.key`. Check that before applying:

```powershell
openssl x509 -in tls.crt -noout -modulus
openssl rsa -in tls.key -noout -modulus
```

The two modulus values must be identical. `openssl` is available with Git for Windows under `C:\Program Files\Git\usr\bin\openssl.exe`.

## 3. Store the new certificate in Kubernetes

This replaces the secret in place. Kong pods keep the old files until they are restarted.

```powershell
kubectl -n kong-production create secret tls kong-proxy-tls `
  --cert=tls.crt `
  --key=tls.key `
  --dry-run=client -o yaml | kubectl apply -f -
```

## 4. Restart Kong so it loads the new files

A secret change does not reload the mounted files.

```powershell
kubectl -n kong-production rollout restart deployment/kong-gateway
kubectl -n kong-production rollout status deployment/kong-gateway
```

## 5. Confirm the new certificate is live

Repeat the `finone.paisalo.in` check from step 1. `Thumbprint` and `NotAfter` should match the new certificate.

Then open `https://finone.paisalo.in/pdlmailing` and confirm the browser shows the new certificate for `*.paisalo.in`.

This certificate expires on 17 Jan 2027. Replace it before that date.

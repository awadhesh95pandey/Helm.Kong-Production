# Kong Gateway for NBFC

This project contains the configuration for deploying Kong Gateway in a Kubernetes environment using Helm.

## Prerequisites

*   [Kubernetes](https://kubernetes.io/docs/setup/) cluster
*   [Helm](https://helm.sh/docs/intro/install/) v3+
*   [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

## Installation

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd kong-gateway
    ```

2.  **Create the Kubernetes secrets:**
    *   The `credentials/` directory contains placeholder files for secrets. You will need to replace them with your actual credentials.
    *   The `convert-jwks.sh` script can be used to convert a JWKS file to a PEM file.

3.  **Deploy the Helm chart:**
    ```bash
    helm install <release-name> ./helm
    ```

    You can also use a custom values file for different environments:
    ```bash
    helm install <release-name> ./helm -f helm/values-production.yaml
    ```

helm upgrade kong-gateway ./helm --namespace kong-system --values ./helm/values-production.yaml

## Configuration

The Kong Gateway configuration is managed in the `helm/kong-config/` directory. The configuration is organized into the following directories:

*   `consumers/`: Kong Consumers
*   `plugins/`: Kong Plugins
*   `routes/`: Kong Routes
*   `services/`: Kong Services
*   `upstreams/`: Kong Upstreams

The configuration is applied using a ConfigMap, which is mounted into the Kong pods. The `kong-deck-deployment.yaml` file in the `helm/templates/` directory contains the configuration for the deck deployment.

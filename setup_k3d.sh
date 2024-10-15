#! /bin/bash

# Install k3d
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Linux detected"

    if ! command -v curl &> /dev/null
    then
        echo "curl not found. Install curl before proceeding..."
        exit
    fi

    if ! command -v k3d &> /dev/null
    then
      echo "Installing k3d..."
      curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
    fi

elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "MacOS detected"

    if ! command -v brew &> /dev/null
    then
        echo "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    if ! command -v k3d &> /dev/null
    then
      echo "Installing k3d..."
      brew install k3d
    fi

else
    echo "Unsupported platform. Please install k3d manually"
fi

# Ask for cluster name
echo -n "Enter cluster name: "
read -r CLUSTER_NAME

# Create a k3d cluster with 1 server and 2 agents (workers)
CLUSTER_LIST=$(k3d cluster list)

if [[ $CLUSTER_LIST == *$CLUSTER_NAME* ]]; then
    echo "Cluster already exists"
else
    echo "Creating cluster..."
    k3d cluster create "$CLUSTER_NAME" \
      --servers 1 \
      --agents 2 \
      --port 30042:30042@loadbalancer \
      --port 30021:30021@loadbalancer
    echo "Cluster created"
    echo "Setting up worker node labels..."
    kubectl label node k3d-"$CLUSTER_NAME"-agent-0 node-role.kubernetes.io/worker=worker
    kubectl label node k3d-"$CLUSTER_NAME"-agent-1 node-role.kubernetes.io/worker=worker
fi
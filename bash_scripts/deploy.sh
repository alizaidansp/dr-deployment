#!/bin/bash
# Full Deployment Script for EKS + Kubernetes Resources
# Usage: ./deploy.sh [environment]

set -e  # Exit on error

# Configuration
ENVIRONMENT=${1:-dev}
TIMESTAMP=$(date +%Y%m%d%H%M%S)
TF_DIR=$(pwd)
K8S_DIR="${TF_DIR}/k8s"
LOG_DIR="${TF_DIR}/logs"
mkdir -p "${LOG_DIR}"

# Initialize logging
exec > >(tee -a "${LOG_DIR}/deployment-${TIMESTAMP}.log") 2>&1

echo "🚀 Starting deployment for environment: ${ENVIRONMENT}"
echo "📌 Timestamp: ${TIMESTAMP}"
echo "----------------------------------------"

terraform_init() {
    echo "🔧 Initializing Terraform..."
    terraform init
}

validate_infra() {
    echo "🔍 Validating Terraform configuration..."
    terraform validate
}

plan_infra() {
    echo "📝 Generating infrastructure plan..."
    terraform plan -out=tfplan.${TIMESTAMP}
}

apply_infra() {
    echo "🛠 Applying infrastructure changes..."
    terraform apply -auto-approve tfplan.${TIMESTAMP}
}

configure_kubectl() {
    echo "⚙ Configuring kubectl context..."
    aws eks --region $(terraform output -raw aws_region) update-kubeconfig \
        --name $(terraform output -raw cluster_name)
}

deploy_k8s() {
    echo "🚢 Deploying Kubernetes resources..."
    cd "${K8S_DIR}"
    
  
    
    
    declare -a MANIFESTS=(
        "services.yml"
        "deployment.yml"
    )
    
    for manifest in "${MANIFESTS[@]}"; do
        echo "📄 Applying ${manifest}..."
        kubectl apply -f "${manifest}"
    done
    
    # Clean up the temporary file
    # rm laravel-config-temp.yml
    
    cd "${TF_DIR}"
}


show_credentials() {
    echo "🔐 Deployment Credentials:"
    echo "--------------------------"
    echo "EKS Cluster Name: $(terraform output -raw cluster_name)"

}

# Main execution flow
main() {
    terraform_init
    validate_infra
    plan_infra
    apply_infra
    configure_kubectl
    deploy_k8s
    sleep 15  # Wait for resources to initialize
    # verify_deployment
    show_credentials
    
    echo "🎉 Deployment completed successfully!"
    echo "🕒 Total time: $(($(date +%s) - ${TIMESTAMP})) seconds"
}

# Run main function
time main


# Make executable
# chmod +x deploy.sh


# cd into k8s_deployment and run

# ~/all-dev/PHASE-2/AWS/Terraform/lloyd_assignment/bash_scripts/deploy.sh && tail -f logs/deployment-*.log
# modify migration-job(DB_HOST) and laravel-config(DB_HOST)

# kubectl delete all,configmap,secret,pvc,ingress --all -n default

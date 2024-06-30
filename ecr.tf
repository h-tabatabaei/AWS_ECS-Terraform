# --- ECR ---

resource "aws_ecr_repository" "app" {
  name                 = "demo-app"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "demo_app_repo_url" {
  value = aws_ecr_repository.app.repository_url
}
/*
# Get AWS repo url from Terraform outputs
export REPO=$(terraform output --raw demo_app_repo_url)
# Login to AWS ECR
aws ecr get-login-password | docker login --username AWS --password-stdin $REPO

# Pull docker image & push to our ECR
docker pull --platform linux/amd64 strm/helloworld-http:latest
docker tag strm/helloworld-http:latest $REPO:latest
docker push $REPO:latest
*/
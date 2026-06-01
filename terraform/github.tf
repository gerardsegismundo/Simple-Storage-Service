provider "github" {
  token = var.github_token
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "repo_name" {
  type    = string
  default = "https://github.com/gerardsegismundo/Simple-Storage-Service"
}

resource "github_repository_environment" "dev" {
  repository  = var.repo_name
  environment = "development"
}

resource "github_repository_environment" "staging" {
  repository  = var.repo_name
  environment = "staging"

  reviewers {
    users = ["gerardsegismundo"]
  }
}

resource "github_repository_environment" "prod" {
  repository  = var.repo_name
  environment = "production"

  reviewers {
    users = ["your-github-username"]
  }

  deployment_branch_policy {
    protected_branches = true
  }
}

resource "github_branch_protection" "develop" {
  repository_id = var.repo_name
  pattern       = "develop"

  required_status_checks {
    strict = true
  }

  required_pull_request_reviews {
    required_approving_review_count = 0
  }
}

resource "github_branch_protection" "staging" {
  repository_id = var.repo_name
  pattern       = "staging"

  required_pull_request_reviews {
    required_approving_review_count = 1
  }

  required_status_checks {
    strict = true
  }
}

resource "github_branch_protection" "main" {
  repository_id = var.repo_name
  pattern       = "main"

  required_pull_request_reviews {
    required_approving_review_count = 1
  }

  required_status_checks {
    strict = true
  }

  enforce_admins = true
}
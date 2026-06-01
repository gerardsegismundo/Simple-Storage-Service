provider "github" {
  token = var.github_token
}

# =========================
# VARIABLES
# =========================
variable "github_token" {
  type      = string
  sensitive = true
}

variable "repo_name" {
  type    = string
  default = "Simple-Storage-Service"
}

# =========================
# GITHUB ENVIRONMENTS
# =========================

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
    users = ["gerardsegismundo"]
  }

  deployment_branch_policy {
    protected_branches = true
  }
}

# =========================
# BRANCH PROTECTION RULES
# =========================

resource "github_branch_protection" "develop" {
  repository = var.repo_name
  pattern    = "develop"

  required_status_checks {
    strict = true
  }

  required_pull_request_reviews {
    required_approving_review_count = 0
  }
}

resource "github_branch_protection" "staging" {
  repository = var.repo_name
  pattern    = "staging"

  required_status_checks {
    strict = true
  }

  required_pull_request_reviews {
    required_approving_review_count = 1
  }
}

resource "github_branch_protection" "main" {
  repository = var.repo_name
  pattern    = "main"

  required_status_checks {
    strict = true
  }

  required_pull_request_reviews {
    required_approving_review_count = 1
  }

  enforce_admins = true
}
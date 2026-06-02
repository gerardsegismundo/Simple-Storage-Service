provider "github" {
  token = var.github_token
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
    users = [30321279]
  }
}

resource "github_repository_environment" "prod" {
  repository  = var.repo_name
  environment = "production"

  reviewers {
    users = [30321279]
  }

  deployment_branch_policy {
    protected_branches     = true
    custom_branch_policies = false
  }
}

# =========================
# BRANCH PROTECTION RULES
# =========================

# resource "github_branch_protection" "develop" {
#   repository_id = var.repo_name
#   pattern       = "develop"

#   required_status_checks {
#     strict = true
#   }

#   required_pull_request_reviews {
#     required_approving_review_count = 0
#   }
# }

# resource "github_branch_protection" "staging" {
#   repository_id = var.repo_name
#   pattern       = "staging"

#   required_status_checks {
#     strict = true
#   }

#   required_pull_request_reviews {
#     required_approving_review_count = 1
#   }
# }

# resource "github_branch_protection" "main" {
#   repository_id = var.repo_name
#   pattern       = "main"

#   required_status_checks {
#     strict = true
#   }

#   required_pull_request_reviews {
#     required_approving_review_count = 1
#   }

#   enforce_admins = true
# }
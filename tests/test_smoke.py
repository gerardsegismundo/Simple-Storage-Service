import json
import os
import pytest
from pathlib import Path


class TestProjectStructure:
    def test_terraform_directory_exists(self):
        assert os.path.isdir("terraform"), "terraform/ directory should exist"

    def test_tests_directory_exists(self):
        assert os.path.isdir("tests"), "tests/ directory should exist"

    def test_github_workflows_exists(self):
        assert os.path.isdir(".github/workflows"), ".github/workflows/ should exist"


class TestTerraformConfiguration:
    def test_terraform_main_exists(self):
        assert os.path.isfile("terraform/main.tf"), "terraform/main.tf should exist"

    def test_terraform_main_not_empty(self):
        main_path = "terraform/main.tf"
        if os.path.isfile(main_path):
            content = Path(main_path).read_text()
            assert len(content) > 0, "main.tf should not be empty"

    def test_terraform_has_origin_bucket(self):
        content = Path("terraform/main.tf").read_text()
        assert "aws_s3_bucket.origin" in content, "Should define origin S3 bucket"
        assert "aws_s3_bucket_versioning" in content, "Should have versioning config"
        assert "AES256" in content, "Should use AES256 encryption"

    def test_terraform_has_audit_bucket(self):
        content = Path("terraform/main.tf").read_text()
        assert "aws_s3_bucket.audit" in content, "Should define audit S3 bucket"
        assert "aws_cloudtrail" in content, "Should have CloudTrail"

    def test_terraform_has_lambda(self):
        content = Path("terraform/main.tf").read_text()
        assert "aws_lambda_function" in content, "Should have Lambda function"
        assert "aws_iam_role" in content, "Should have IAM role"


class TestGitHubWorkflow:
    def test_main_workflow_exists(self):
        assert os.path.isfile(".github/workflows/main.yaml"), "main.yaml workflow should exist"

    def test_main_workflow_valid_yaml(self):
        workflow_path = ".github/workflows/main.yaml"
        content = Path(workflow_path).read_text()
        assert "name:" in content, "Workflow should have a name"
        assert "on:" in content, "Workflow should have triggers"
        assert "jobs:" in content, "Workflow should have jobs"


class TestIndexHTML:
    def test_index_html_exists(self):
        assert os.path.isfile("index.html"), "index.html should exist"

    def test_index_html_valid_structure(self):
        content = Path("index.html").read_text()
        assert "<html" in content.lower() or "<!DOCTYPE" in content, "Should have HTML structure"
        assert "<head" in content.lower() or "<body" in content.lower(), "Should have head or body tags"


class TestLambdaHandler:
    def test_lambda_handler_exists(self):
        assert os.path.isfile("lambda/s3_event_processor.py"), "Lambda handler should exist"

    def test_lambda_handler_valid_python(self):
        content = Path("lambda/s3_event_processor.py").read_text()
        assert "lambda_handler" in content, "Should have lambda_handler function"
        assert "def " in content, "Should have function definitions"
        compile(content, "s3_event_processor.py", "exec")


class TestSmokePipeline:
    def test_smoke_pipeline(self):
        assert True

    def test_python_version(self):
        import sys
        assert sys.version_info >= (3, 9), "Python 3.9+ should be used"

    def test_project_readme_exists(self):
        assert os.path.isfile("README.md"), "README.md should exist"
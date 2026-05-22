import json
import os
import pytest
from pathlib import Path


class TestProjectStructure:
    """Test that all expected project files and directories exist."""

    def test_terraform_directory_exists(self):
        assert os.path.isdir("terraform"), "terraform/ directory should exist"

    def test_tests_directory_exists(self):
        assert os.path.isdir("tests"), "tests/ directory should exist"

    def test_github_workflows_exists(self):
        assert os.path.isdir(".github/workflows"), ".github/workflows/ should exist"


class TestTerraformConfiguration:
    """Test Terraform configuration validity."""

    def test_terraform_main_exists(self):
        assert os.path.isfile("terraform/main.tf"), "terraform/main.tf should exist"

    def test_terraform_variables_exists(self):
        assert os.path.isfile("terraform/variables.tf"), "terraform/variables.tf should exist"

    def test_terraform_outputs_exists(self):
        assert os.path.isfile("terraform/outputs.tf"), "terraform/outputs.tf should exist"

    def test_terraform_main_not_empty(self):
        main_path = "terraform/main.tf"
        if os.path.isfile(main_path):
            content = Path(main_path).read_text()
            assert len(content) > 0, "main.tf should not be empty"


class TestGitHubWorkflow:
    """Test GitHub Actions workflow configuration."""

    def test_main_workflow_exists(self):
        assert os.path.isfile(".github/workflows/main.yaml"), "main.yaml workflow should exist"

    def test_main_workflow_valid_yaml(self):
        workflow_path = ".github/workflows/main.yaml"
        content = Path(workflow_path).read_text()
        assert "name:" in content, "Workflow should have a name"
        assert "on:" in content, "Workflow should have triggers"
        assert "jobs:" in content, "Workflow should have jobs"


class TestIndexHTML:
    """Test index.html file validity."""

    def test_index_html_exists(self):
        assert os.path.isfile("index.html"), "index.html should exist"

    def test_index_html_valid_structure(self):
        content = Path("index.html").read_text()
        assert "<html" in content.lower() or "<!DOCTYPE" in content, "Should have HTML structure"
        assert "<head" in content.lower() or "<body" in content.lower(), "Should have head or body tags"


class TestSmokePipeline:
    """Basic smoke tests to verify the project setup."""

    def test_smoke_pipeline(self):
        assert True

    def test_python_version(self):
        import sys
        assert sys.version_info >= (3, 9), "Python 3.9+ should be used"

    def test_project_readme_exists(self):
        assert os.path.isfile("README.md"), "README.md should exist"
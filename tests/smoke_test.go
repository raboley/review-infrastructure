package tests

import (
	"flag"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"testing"
)

var resourceGroupName = flag.String("resourceGroupName", "", "The resource group expected to be created")

func TestResourceGroupCreated(t *testing.T) {

	expectedResourceGroupName := *resourceGroupName
	// website::tag::1:: Configure Terraform setting up a path to Terraform code.
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../terraform",
	}
	resourceGroupName := terraform.Output(t, terraformOptions, "resource_group_name")

	t.Log(expectedResourceGroupName)
	t.Log(resourceGroupName)
	assert.Equal(t, expectedResourceGroupName, resourceGroupName)
}

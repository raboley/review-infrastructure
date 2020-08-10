package tests

import (
	"flag"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"testing"
)

var resourceGroupName = flag.String("resourceGroupName", "", "The resource group expected to be created")

func TestResourceGroupCreated(t *testing.T) {
	t.Fail()

	expectedResourceGroupName := *resourceGroupName
	// website::tag::1:: Configure Terraform setting up a path to Terraform code.
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../terraform",
	}
	resourceGroupName := terraform.Output(t, terraformOptions, "resource_group_name")

	// website::tag::4:: Look up the size of the given Virtual Machine and ensure it matches the output.
	assert.Equal(t, expectedResourceGroupName, resourceGroupName)
}

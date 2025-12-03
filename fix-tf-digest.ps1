# Create key file
'{"LockID":{"S":"tfstate-ap-south-1-ks93h1demo/capstone/dev/terraform.tfstate"}}' | Out-File -Encoding ASCII key.json

# Delete the lock
aws dynamodb delete-item --table-name "terraform-lock" --key file://key.json --region ap-south-1

# Cleanup
Remove-Item key.json
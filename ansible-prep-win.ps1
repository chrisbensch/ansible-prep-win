# Configure WinRM for HTTP
winrm quickconfig -q

# Set all network connections to Private
# Get all network connection profiles
$profiles = Get-NetConnectionProfile

# Iterate through each profile and set it to private
foreach ($profile in $profiles) {
    Set-NetConnectionProfile -NetworkCategory Private -InterfaceIndex $profile.InterfaceIndex
}



# Set basic authentication and allow unencrypted messages (for testing purposes)
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

# Allow firewall rules for WinRM
New-NetFirewallRule -Name "WinRM-HTTP" -DisplayName "WinRM HTTP" -Enabled True -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5985


New-LocalUser -Name AnsibleUser -Password (ConvertTo-SecureString "StrongPassword!" -AsPlainText -Force) -FullName "Ansible User" -Description "User for Ansible remote management"

Add-LocalGroupMember -Group "Administrators" -Member "AnsibleUser"

## Optional: Configure SSL for HTTPS (recommended for production)

# Create a self-signed certificate (for testing purposes)
$thumbprint = (New-SelfSignedCertificate -DnsName $(hostname) -CertStoreLocation Cert:\LocalMachine\My).Thumbprint

# Configure WinRM for HTTPS
winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="$(hostname)"; CertificateThumbprint="$thumbprint"}

# Set basic authentication and allow encrypted messages
winrm set winrm/config/service @{AllowUnencrypted="false"}
winrm set winrm/config/service/auth @{Basic="true"}  # Use CredSSP or Kerberos in production

# Allow firewall rules for WinRM HTTPS
New-NetFirewallRule -Name "WinRM-HTTPS" -DisplayName "WinRM HTTPS" -Enabled True -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5986

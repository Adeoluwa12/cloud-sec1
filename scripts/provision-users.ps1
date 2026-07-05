# ============================================================
# Project 01 - Phase 1: Provision Test Users and Groups
# ============================================================

# Connect if not already connected
$domain = "tearinksoutlook.onmicrosoft.com"
Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All","Directory.ReadWrite.All"


$passwordProfile = @{
    Password = "SecurePass123!"
    ForceChangePasswordNextSignIn = $false
}

# Create 10 users
$users = @(
    @{ DisplayName="Ada Okonkwo";        JobTitle="Security Engineer";    Department="Engineering"; UserPrincipalName="ada.okonkwo@$domain" },
    @{ DisplayName="Bola Adeyemi";       JobTitle="DevOps Engineer";      Department="Engineering"; UserPrincipalName="bola.adeyemi@$domain" },
    @{ DisplayName="Chidi Nwosu";        JobTitle="Cloud Architect";      Department="Engineering"; UserPrincipalName="chidi.nwosu@$domain" },
    @{ DisplayName="Dami Oladele";       JobTitle="Finance Manager";      Department="Finance";     UserPrincipalName="dami.oladele@$domain" },
    @{ DisplayName="Emeka Eze";          JobTitle="Financial Analyst";    Department="Finance";     UserPrincipalName="emeka.eze@$domain" },
    @{ DisplayName="Fatima Aliyu";       JobTitle="HR Manager";           Department="HR";          UserPrincipalName="fatima.aliyu@$domain" },
    @{ DisplayName="Gbenga Afolabi";     JobTitle="Sales Lead";           Department="Sales";       UserPrincipalName="gbenga.afolabi@$domain" },
    @{ DisplayName="Halima Musa";        JobTitle="IT Administrator";     Department="IT";          UserPrincipalName="halima.musa@$domain" },
    @{ DisplayName="Ife Adeleke";        JobTitle="IT Administrator";     Department="IT";          UserPrincipalName="ife.adeleke@$domain" },
    @{ DisplayName="Jide Babatunde";     JobTitle="Security Analyst";     Department="Security";    UserPrincipalName="jide.babatunde@$domain" }
)

Write-Host "Creating users..." -ForegroundColor Cyan
$createdUsers = @{}

foreach ($user in $users) {
    try {
        $newUser = New-MgUser `
            -DisplayName $user.DisplayName `
            -UserPrincipalName $user.UserPrincipalName `
            -JobTitle $user.JobTitle `
            -Department $user.Department `
            -PasswordProfile $passwordProfile `
            -AccountEnabled:$true `
            -MailNickname ($user.UserPrincipalName.Split("@")[0])

        $createdUsers[$user.UserPrincipalName] = $newUser.Id
        Write-Host "  Created: $($user.DisplayName)" -ForegroundColor Green
    }
    catch {
        Write-Host "  Failed: $($user.DisplayName) - $_" -ForegroundColor Red
    }
}

# Create 4 security groups
Write-Host "`nCreating security groups..." -ForegroundColor Cyan

$groups = @(
    @{ DisplayName="sg-admins";       Description="IT and Security administrators" },
    @{ DisplayName="sg-engineers";    Description="Engineering department" },
    @{ DisplayName="sg-finance";      Description="Finance department" },
    @{ DisplayName="sg-all-users";    Description="All standard users" }
)

$createdGroups = @{}

foreach ($group in $groups) {
    try {
        $newGroup = New-MgGroup `
            -DisplayName $group.DisplayName `
            -Description $group.Description `
            -MailEnabled:$false `
            -SecurityEnabled:$true `
            -MailNickname $group.DisplayName

        $createdGroups[$group.DisplayName] = $newGroup.Id
        Write-Host "  Created: $($group.DisplayName)" -ForegroundColor Green
    }
    catch {
        Write-Host "  Failed: $($group.DisplayName) - $_" -ForegroundColor Red
    }
}

# Add users to groups
Write-Host "`nAdding users to groups..." -ForegroundColor Cyan

# Admins group
$adminMembers = @("halima.musa@$domain","ife.adeleke@$domain","jide.babatunde@$domain")
foreach ($upn in $adminMembers) {
    if ($createdUsers[$upn]) {
        New-MgGroupMember -GroupId $createdGroups["sg-admins"] -DirectoryObjectId $createdUsers[$upn]
        Write-Host "  Added $upn to sg-admins" -ForegroundColor Green
    }
}

# Engineers group
$engMembers = @("ada.okonkwo@$domain","bola.adeyemi@$domain","chidi.nwosu@$domain")
foreach ($upn in $engMembers) {
    if ($createdUsers[$upn]) {
        New-MgGroupMember -GroupId $createdGroups["sg-engineers"] -DirectoryObjectId $createdUsers[$upn]
        Write-Host "  Added $upn to sg-engineers" -ForegroundColor Green
    }
}

# Finance group
$finMembers = @("dami.oladele@$domain","emeka.eze@$domain")
foreach ($upn in $finMembers) {
    if ($createdUsers[$upn]) {
        New-MgGroupMember -GroupId $createdGroups["sg-finance"] -DirectoryObjectId $createdUsers[$upn]
        Write-Host "  Added $upn to sg-finance" -ForegroundColor Green
    }
}

# All users group - everyone
foreach ($upn in $createdUsers.Keys) {
    New-MgGroupMember -GroupId $createdGroups["sg-all-users"] -DirectoryObjectId $createdUsers[$upn] -ErrorAction SilentlyContinue
}

# Assign Entra ID P2 licenses to all users
Write-Host "`nAssigning P2 licenses..." -ForegroundColor Cyan

# Get the P2 SKU ID
$skus = Get-MgSubscribedSku
$p2sku = $skus | Where-Object { $_.SkuPartNumber -like "*AAD_PREMIUM_P2*" -or $_.SkuPartNumber -like "*ENTERPRISEPREMIUM*" }

if ($p2sku) {
    $licenseParams = @{
        AddLicenses = @(@{ SkuId = $p2sku[0].SkuId })
        RemoveLicenses = @()
    }
    foreach ($upn in $createdUsers.Keys) {
        try {
            Set-MgUserLicense -UserId $createdUsers[$upn] -BodyParameter $licenseParams
            Write-Host "  Licensed: $upn" -ForegroundColor Green
        }
        catch {
            Write-Host "  License failed for $upn - $_" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  P2 SKU not found - assign licenses manually in Admin Centre" -ForegroundColor Yellow
}

# Save IDs for later use
$output = @{
    Domain = $domain
    Users = $createdUsers
    Groups = $createdGroups
}
$output | ConvertTo-Json | Out-File "C:\Projects\cloud-security-portfolio\project-01\docs\tenant-ids.json"

Write-Host "`nDone! IDs saved to docs\tenant-ids.json" -ForegroundColor Cyan
Write-Host "Users created: $($createdUsers.Count)" -ForegroundColor Cyan
Write-Host "Groups created: $($createdGroups.Count)" -ForegroundColor Cyan
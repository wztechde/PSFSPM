function Invoke-SetACL {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [FMPathPermission]$InputObject
    )
    # check path prior to any activity
    If (-Not (Test-Path $InputObject.Path)) {
        Throw "Cannot find path " + [char]39 + "$($InputObject.Path)" + [char]39 + " because it does not exist"
    }
    # there are multiple paths possible
    Foreach ($Path in $InputObject.Path) {
        if ($PSCmdlet.ShouldProcess("$Path", "Set-ACL")) {
            Write-Verbose "Set Access Rule Protection on $($InputObject.Path): $($InputObject.ACRule.isProtected),$($InputObject.ACRule.preserveInheritance)"
            SetAccessRuleProtection -InputObject $InputObject -Path $Path
        }
        AddAccess -Path $Path -InputObject $InputObject    #now process the permissions
    }

}

function SetAccessRuleProtection {
    param (
        [FMPathPermission]$InputObject,
        [String]$Path
    )
    $ACL = Get-Acl -Path $Path
    $ACL.SetAccessRuleProtection($InputObject.ACRule.isProtected, $InputObject.ACRule.preserveInheritance) | Out-Null
    Set-Acl -Path $Path -AclObject $ACL | Out-Null
    Get-Acl -Path $Path
}
<#
function AddAccessRule {
    param (
        [System.Security.AccessControl.FileSystemSecurity]$ACL,
        [System.Security.AccessControl.AccessRule]$AccessObject
    )
    $ACL.AddAccessRule($ACL, $AccessObject)
    $ACL
}
#>

function AddAccess {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [String]$Path,
        [FMPathPermission]$InputObject
    )
    ForEach ($Permission in $InputObject.Permission) {
        $ACL = Get-Acl -Path $Path
        $AccessObject =
        New-Object System.Security.AccessControl.FileSystemAccessRule(
            $Permission.Identity,
            $Permission.Permission,
            ($Permission.GetInheritance()).Inherit,
            ($Permission.GetInheritance()).Propagate, "Allow")
        Write-Verbose "Add $($Permission.Identity) to ACL, Permission: $($Permission.Permission), Inheritance: $($Permission.Inheritance)"
        $ACL.AddAccessRule($AccessObject)
        if ($PSCmdlet.ShouldProcess("$Path", "Add Access Rule")) {
            Write-Verbose "AddAccessRule to $Path"
            Set-Acl -Path $Path -AclObject $ACL | Out-Null
        }
    }
}

<#
for each path
    1. SetAccessRuleProtection
    Set-ACL
    for each permisison
        1. Add Access Rule
    Set-ACL
#>
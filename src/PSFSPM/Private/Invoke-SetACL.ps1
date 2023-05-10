function Invoke-SetACL {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [FMPathPermission]$InputObject
    )
    $Output = @()
    # check path prior to any activity
    If (-Not (Test-Path $InputObject.Path)) {
        Throw "Cannot find path " + [char]39 + "$($InputObject.Path)" + [char]39 + " because it does not exist"
    }
    # there are multiple paths possible
    Foreach ($Path in $InputObject.Path) {
        $ACL = Get-Acl $Path
        foreach ($Permission in $InputObject.Permission) {
            switch -Wildcard ($Permission.Permission) {
                'Delete' { $ACL=PurgeAccessRules -Path $Path -InputObject $Permission -ACL $ACL}
                Default { $ACL=AddAccess -Path $Path -InputObject $Permission -ACL $ACL}
            }
        }
        if ($PSCmdlet.ShouldProcess("$((Get-Date).TimeofDay) $Path", "Invoke-SetACL")) {
            Write-Verbose "$((Get-Date).TimeofDay) Set Access Rule Protection on $($Path)"
            Write-Debug "$((Get-Date).TimeofDay) isProtected: $($InputObject.ACRule.isProtected), preserveInheritance: $($InputObject.ACRule.preserveInheritance)"
            # you don't need the complete object for the subroutines, but this wait it's easier and
            # better maintainable
            SetAccessRuleProtection -Path $Path -InputObject $InputObject
            Write-Verbose "$((Get-Date).TimeofDay) Add Access to Path $($Path)"
            $Output += SetAccess -Path $Path -InputObject $InputObject    #now process the permissions
        }
    }
}
$Output


function SetAccessRuleProtection {
    param (
        [String]$Path,
        [FMPathPermission]$InputObject
    )
    $ACL = Get-Acl -Path $Path
    $ACL.SetAccessRuleProtection($InputObject.ACRule.isProtected, $InputObject.ACRule.preserveInheritance) | Out-Null
    Set-Acl -Path $Path -AclObject $ACL | Out-Null
}
function AddAccess {
    param (
        [String]$Path,
        [FMPermission]$Permission
    )

}
function SetAccess {
    param (
        [String]$Path,
        [FMPathPermission]$InputObject
    )
    $ACL = Get-Acl -Path $Path
    # process all permissions
    ForEach ($Permission in $InputObject.Permission) {
        $UserID = New-Object System.Security.Principal.NTAccount $Permission.Identity
        If ($Permission.Permission -like "Delete") {
            $Acl.PurgeAccessRules($UserID)
        }
        else {
            $AccessObject =
            New-Object System.Security.AccessControl.FileSystemAccessRule(
                $UserID,
                $Permission.Permission,
            ($Permission.GetInheritance()).Inherit,
            ($Permission.GetInheritance()).Propagate, "Allow")
            $ACL.AddAccessRule($AccessObject)
        }
    }
    # and write back
    Set-Acl -Path $Path -AclObject $ACL
}

function PurgeAccessRules {
    param (
        [String]$Path,
        [FMPermission]$Permission
    )
    $ACL = Get-Acl $Path
    $UserID = New-Object System.Security.Principal.NTAccount($Permission.Identity)
    $ACL.PurgeAccessRules($UserID)
    $ACL | Set-Acl -Path $Path
}
<#
for each path
    1. SetAccessRuleProtection
    Set-ACL
    for each

#>
<#After some tests, I'd say that there's no need to use an external module for this matter.

As you can read here: https://blog.netwrix.com/2018/04/18/how-to-manage-file-system-acls-with-powershell-scripts/

You can use the method "PurgeAccessRules" to remove all right rules of a user or group. Code:

$acl = Get-Acl C:\MyFolder
$usersid = New-Object System.Security.Principal.Ntaccount("DOMAIN\Group")
$acl.PurgeAccessRules($usersid)
$acl | Set-Acl C:\MyFo
#>
function Invoke-SetACL {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [FMPathPermission]$InputObject
    )
    # check path prior to any activity
    If (-Not (Test-Path $InputObject.Path)) {
        Throw "Cannot find path " + [char]39 + "$($InputObject.Path)" + [char]39 + " because it does not exist"
    }
    Write-Verbose "Set AccessRule Protection on $($InputObject.Path)"
    # there are multiple paths possible
    Foreach ($Path in $InputObject.Path) {
        $CurrentACL = SetAccessRuleProtection -InputObject $InputObject -Path $Path
        if ($PSCmdlet.ShouldProcess("$Path", "Set-ACL")) {
            Set-ACL -Path $Path $CurrentACL
        }
    }
}

function SetAccessRuleProtection {
    param (
        [FMPathPermission]$InputObject,
        [String]$Path
    )
    $ACL = Get-ACL $Path
    $ACL.SetAccessRuleProtection($InputObject.isProtected, $InputObject.preserveInheritance)
    $ACL
}
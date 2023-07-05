enum IMInheritance {
   ThisFolderSubfoldersAndFiles
   ThisFolderAndSubfolders
   ThisFolderOnly
   ThisFolderAndFiles
   SubfoldersAndFilesOnly
   SubfoldersOnly
   FilesOnly
   File
}
# translate enum IMInheritance to System.Security.AccessControl.InheritanceFlags
# The following enum is rebuilding the internal System.Security.AccessControl.FilesystemRights for extensability purposes
# This way I'll be able to add additional "Rights" to the enum for my needs
# Firstly I integrated the right delete, which will remove the given permission(s) completely from the ACL
enum FMFileRights {
   ListDirectory = 1
   ReadData = 1
   WriteData = 2
   CreateFiles = 2
   CreateDirectories = 4
   AppendData = 4
   ReadExtendedAttributes = 8
   WriteExtendedAttributes = 16
   Traverse = 32
   ExecuteFile = 32
   DeleteSubdirectoriesAndFiles = 64
   ReadAttributes = 128
   WriteAttributes = 256
   Write = 278
   Delete = 65536
   ReadPermissions = 131072
   Read = 131209
   ReadAndExecute = 131241
   Modify = 197055
   ChangePermissions = 262144
   TakeOwnership = 524288
   Synchronize = 1048576
   FullControl = 2032127
   DeleteFromACL = 512
}
<#
$IMInheritanceConversionTable = @{
   [IMInheritance]::ThisFolderOnly               = @{Propagate = 'NoPropagateInherit'; Inherit = '' };
   [IMInheritance]::ThisFolderSubfoldersAndFiles = @{Propagate = 'None'; Inherit = 'ContainerInherit,ObjectInherit' };
   [IMInheritance]::ThisFolderAndSubfolders          = @{Propagate = 'None'; Inherit = 'ContainerInherit' };
   [IMInheritance]::ThisFolderAndFiles              = @{Propagate = 'None'; Inherit = 'ObjectInherit' };
   [IMInheritance]::SubfoldersAndFilesOnly          = @{Propagate = 'InheritOnly'; Inherit = 'ContainerInherit,ObjectInherit' };
   [IMInheritance]::SubfoldersOnly               = @{Propagate = 'InheritOnly'; Inherit = 'ContainerInherit' };
   [IMInheritance]::FilesOnly                    = @{Propagate = 'InheritOnly'; Inherit = 'ObjectInherit' }
}
#>
# https://learn.microsoft.com/de-de/powershell/module/microsoft.powershell.security/set-acl?view=powershell-7.2

Class FMPermission {
   # A helper class to manage permissions
   [String]$Identity
   #[System.Security.AccessControl.FileSystemRights]$Permission
   [FMFileRights]$FileRight
   [IMInheritance]$Inheritance

   FMPermission(
      [String]$Identity,
      [FMFileRights]$FileRight,
      [IMInheritance]$Inheritance
   ) {
      $this.Identity = $Identity
      $this.FileRight = $FileRight
      $this.Inheritance = $Inheritance
   }

   #methods
   # https://community.spiceworks.com/topic/775372-powershell-to-change-permissions-on-fodlers
   [hashtable]GetDetailedInheritance() {
      $IMInheritanceConversionTable = @{
         [IMInheritance]::ThisFolderSubfoldersAndFiles = @{Propagate = 'None'; Inherit = 'ContainerInherit, ObjectInherit' };
         [IMInheritance]::ThisFolderAndSubfolders      = @{Propagate = 'None'; Inherit = 'ContainerInherit' };
         [IMInheritance]::ThisFolderOnly               = @{Propagate = 'None'; Inherit = 'None' };
         [IMInheritance]::ThisFolderAndFiles           = @{Propagate = 'None'; Inherit = 'ObjectInherit' };
         [IMInheritance]::SubfoldersAndFilesOnly       = @{Propagate = 'InheritOnly'; Inherit = 'ContainerInherit, ObjectInherit' };
         [IMInheritance]::SubfoldersOnly               = @{Propagate = 'InheritOnly'; Inherit = 'ContainerInherit' };
         [IMInheritance]::FilesOnly                    = @{Propagate = 'InheritOnly'; Inherit = 'ObjectInherit' }
         [IMInheritance]::File                         = @{Propagate = 'None'; Inherit = 'None' }
      }
      return $IMInheritanceConversionTable[$this.Inheritance]
   }

   [System.Security.AccessControl.FileSystemAccessRule]Get_FileSystemAccessRule () {
      # mask out own permission(s) to avoid cast error
      $TempPermission = $this.Permission
      if ($TempPermission -like "DeleteFromACL") {
         $TempPermission = "Delete"
      }
      $TempPermission = $this.Identity,
      $TempPermission,
      $this.Get_ExplicitInheritance().Inherit,
      $this.Get_ExplicitInheritance().Propagate,
      [System.Security.AccessControl.AccessControlType]::Allow
      $Output = New-Object System.Security.AccessControl.FileSystemAccessRule $TempPermission
      return $Output
   }

}#end class

# helper function to call constructor

<#
   .SYNOPSIS
      New-FMPermission creates a FMPermission object  from the given identity, permission and inheritance
   .DESCRIPTION
      New-FMPermission takes a identity, permission and inheritance and creates a FMPermission object
   .PARAMETER Identity
      A string defining the identity to apply the permission to
   .PARAMETER Permission
      A string defining the permission to apply to the identity
   .PARAMETER Inheritance
      A string defining the inheritance to apply to the permission
#>
Function New-FMPermission {
   Param(
      [ValidateNotNullOrEmpty()]
      [String]$Identity,
      [ValidateNotNullOrEmpty()]
      [FMFileRights]$FileRight,
      [ValidateNotNullOrEmpty()]
      [IMInheritance]$Inheritance
   )
   [FMPermission]::New($Identity, $FileRight, $Inheritance)
}#end function

<#
FMPathPermission a path and an array of permissions to apply this path
Describe the class fmPathPermission and its members in detail with examples on how to use them

#>
Class FMPathPermission {
   [String]$Path
   [FMPermission[]]$Permission
   [hashtable]$ACRule = @{
      # as standard break inheritance and copy existing acls
      # see example 4: https://learn.microsoft.com/de-de/powershell/module/microsoft.powershell.security/set-acl?view=powershell-7.2
      isProtected         = $false
      preserveInheritance = $true
   }

   #constructor
   FMPathPermission(
      [String[]]$Path,
      [FMPermission[]]$Permission
   ) {
      $this.Path = $Path
      $this.Permission = $Permission
   }

   # methods
   [System.Security.AccessControl.FileSystemAccessRule[]]Get_FileSystemAccessRule () {
      $Output = @()
      foreach ($Perm in $this.Permission) {
         $Output += $Perm.Get_FileSystemAccessRule()
      }
      return $Output
   }

   [System.Security.AccessControl.FileSystemSecurity]Set_Access() {
      $ACL = Get-Acl $this.Path
      foreach ($Perm in $this.Permission) {
         $UserID = New-Object System.Security.Principal.NTAccount $Perm.Identity
         If ($Perm.Permission -like "DeleteFromACL") {
            $ACL.PurgeAccessRules($UserID)
         }
         else {
            if ((Get-Item $this.path).PSIscontainer) {
               $AccessObject =
               New-Object System.Security.AccessControl.FileSystemAccessRule(
                  $UserID,
                  $Perm.Permission,
            ($Perm.Get_ExplicitInheritance()).Inherit,
            ($Perm.Get_ExplicitInheritance()).Propagate, "Allow")
               $ACL.AddAccessRule($AccessObject)
            }
            else {
               # remove propagation and inheritance for explicit files
               $AccessObject =
               New-Object System.Security.AccessControl.FileSystemAccessRule(
                  $UserID,
                  $Perm.Permission,
                  'None',
                  'None', "Allow")
            }
            $ACL.AddAccessRule($AccessObject)
         }# end if
      }# end foreach
      $Output = Set-Acl -Path $this.Path -AclObject $ACL -Passthru
      return $Output
   }# end method
}#end class

#helper function to call constructor
<#
.SYNOPSIS
   New-FMPathPermission creates a FMPathPermission object  from the given path and permission
.DESCRIPTION
   New-FMPathPermission takes a path and permission and creates a FMPathPermission object
.PARAMETER Path
   A string defining the path to apply the permission to
.PARAMETER InputObject
   One or more FMPermission object(s) defining the permission(s) to apply

#>
Function New-FMPathPermission {
   [CmdletBinding()]
   Param (
      [Parameter(ParameterSetName = 'Default')]
      [Parameter(ParameterSetName = 'InputObject')]
      [ValidateNotNullOrEmpty()]
      [String]$Path,
      [Parameter(ParameterSetName = 'InputObject')]
      [ValidateNotNullOrEmpty()]
      [FMPermission[]]$InputObject,
      [Parameter(ParameterSetName = 'Default')]
      [ValidateNotNullOrEmpty()]
      [String[]]$Identity,
      [Parameter(ParameterSetName = 'Default')]
      [ValidateNotNullOrEmpty()]
      [FileRights[]]$Permission,
      [Parameter(ParameterSetName = 'Default')]
      [ValidateNotNullOrEmpty()]
      [IMInheritance[]]$Inheritance
   )
   # parameter set 'InputObject'
   if ($PSBoundParameters.ContainsKey('InputObject')) {
      [FMPathPermission]::New($Path, $InputObject)
   }
   # parameter set 'Default'
   if ($PSBoundParameters.ContainsKey('Identity')) {
      If (($Identity.Count -ne $Permission.Count) -or ($Identity.Count -ne $Inheritance.Count)) {
         Throw "Counts of identities, permissions and inheritances don't match - please check"
      }
      $TempInput = @()
      for ($i = 0; $i -lt $Identity.count; $i++) {
         $TempInput += New-FMPermission -Identity $Identity[$i] -Permission $Permission[$i] -Inheritance $Inheritance[$i]
      }
      #}
      [FMPathPermission]::New($Path, $TempInput)
   }#end if
}#end function

Class FMDirectory {
   [FMPathPermission]$Root
   [FMPathPermission[]]$Child

   FMDirectory(
      [FMPathPermission]$Root,
      [FMPathPermission[]]$Child
   ) {
      $this.Root = $Root
      # preserve inheritance must not be changed to keep the inherited acls
      $this.Root.ACRule.isProtected = $false
      # check all children for possible full path errors
      foreach ($cld in $child) {
         if ($($cld.path) -match "^\w:\\") {
            Throw "FMDirectory - children must not contain drive information $($cld.path)"
         }
      }
      $this.Child = $Child
   }

   [String]Get_ChildFullname(
      [int]$index
   ) {
      #INFO concatenates only string1 - there might be an issue with path(s) not existing
      return ("$($this.Root.Path)\$($this.Child[$index].path)")
   }
   [PSCustomObject]Set_Access() {
      # process root first
      $ReturnRoot = ($this.Root).Set_Access()
      $ReturnChild = @()
      foreach ($cld in $this.Child) {
         # concatenate hostname - changing $cld from enumeration directly results in changing the
         # base object - a object.copy() might work, too
         $Prm = @{
            Path        = Join-Path -Path ($this.Root).Path -ChildPath $cld.Path
            InputObject = $cld.Permission
         }
         $TempChild = New-FMPathPermission @Prm
         #$cld.Path = Join-Path -Path ($this.Root).Path -ChildPath $cld.Path
         $ReturnChild += $TempChild.Set_Access()
      }
      $Output = [PSCustomObject]@{
         Root  = $ReturnRoot
         Child = $ReturnChild
      }
      return $Output
   }

}

<#
.SYNOPSIS
   New-FMDirectory creates a FMDirectory from the given root and child objects
.DESCRIPTION
   New-FMDirectory takes a root FMPathPermission and one or more child FMPathPermission(s). It guarantees, that all inherited permissions will be inherited down the root
   path and NOT being changed to explicit permissions.
   The children instead WILL break inheritance, change all inherited permssions to explicit ones.
   This all is metaphorical for the function itself does not permission handling but
   only keeps the information in the described way.
.PARAMETER Root
   A FMPathPermission object defining the root element for an explicit permission structure
.PARAMETER Child
   One or more FMPathPermission object to define subfolders of the root element, where different
   permission are to be set. Only folder names for the path element of the FMPathPermission are allowed here
.NOTES
   Information or caveats about the function e.g. 'This function is not supported in Linux'
.EXAMPLE
   New-FMDirectory -Root $Root -Child $Child1,$Child2
   Get's the root and two children
#>
Function New-FMDirectory {
   Param (
      [FMPathPermission]$Root,
      [FMPathPermission[]]$Child
   )
   [FMDirectory]::New($Root, $Child)
}
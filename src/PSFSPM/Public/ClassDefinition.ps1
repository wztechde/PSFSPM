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

# The following enum is rebuilding the internal System.Security.AccessControl.FilesystemRights for extensability purposes
# This way I'll be able to add additional "Rights" to the enum for my needs
# Firstly I integrated the right delete, which will remove the given permission(s) completely from the ACL
enum FileRights {
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
   [FileRights]$Permission
   [IMInheritance]$Inheritance

   FMPermission(
      [String]$Identity,
      [FileRights]$Permission,
      [IMInheritance]$Inheritance
   ) {
      $this.Identity = $Identity
      $this.Permission = $Permission
      $this.Inheritance = $Inheritance
   }

   #methods
   # https://community.spiceworks.com/topic/775372-powershell-to-change-permissions-on-fodlers
   [hashtable]GetInheritance() {
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
}#end class

# helper function to call constructor
Function New-FMPermission {
   Param(
      [ValidateNotNullOrEmpty()]
      [String]$Identity,
      [ValidateNotNullOrEmpty()]
      [System.Security.AccessControl.FileSystemRights]$Permission,
      [ValidateNotNullOrEmpty()]
      [IMInheritance]$Inheritance
   )
   [FMPermission]::New($Identity, $Permission, $Inheritance)
}#end function

<#
FMPathPermission holds an array of paths and an array of permissions to apply on each of these paths
#>
Class FMPathPermission {
   [String[]]$Path
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
   [System.Security.AccessControl.FileSystemAccessRule[]]GetFileSystemAccessRule () {
      $Output = @()
      <#
      if ($this.Permission.Count -eq 1) {
         $TempPermission = $this.Permission.Identity,
         $this.Permission.permission,
         $this.Permission.GetInheritance().Inherit,
         $this.Permission.GetInheritance().Propagate,
         [System.Security.AccessControl.AccessControlType]::Allow
         $Output += New-Object System.Security.AccessControl.FileSystemAccessRule $TempPermission
      }
      else {
         #>
      # more than 1 permission - use loop
      for ($i = 0 ; $i -lt $this.Permission.count; $i++) {
         $TempPermission = $this.Permission[$i].Identity,
         $this.Permission[$i].permission,
         $this.Permission[$i].GetInheritance().Inherit,
         $this.Permission[$i].GetInheritance().Propagate,
         [System.Security.AccessControl.AccessControlType]::Allow
         $Output += New-Object System.Security.AccessControl.FileSystemAccessRule $TempPermission
      }
      #      }
      return $Output
   }
}#end class

#helper function to call constructor
Function New-FMPathPermission {
   [CmdletBinding()]
   Param (
      [Parameter(ParameterSetName = 'Default')]
      [Parameter(ParameterSetName = 'InputObject')]
      [ValidateNotNullOrEmpty()]
      [String[]]$Path,
      [Parameter(ParameterSetName = 'InputObject')]
      [ValidateNotNullOrEmpty()]
      [FMPermission[]]$InputObject,
      [Parameter(ParameterSetName = 'Default')]
      [ValidateNotNullOrEmpty()]
      [String[]]$Identity,
      [Parameter(ParameterSetName = 'Default')]
      [ValidateNotNullOrEmpty()]
      [System.Security.AccessControl.FileSystemRights[]]$Permission,
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
      <#
      if ($Identity.Count -eq 1) {
         $InputObject = New-FMPermission -Identity $Identity -Permission $Permission -Inheritance $Inheritance
      }
      else {
         #>
      #create permission array
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
      $this.Root.ACRule.isProtected = $false
      # preserve inheritance must not be changed to keep the inherited acls
      if ($($child.path) -match "^\w:\\") {
         Throw "FMDirectory - children must not contain drive information"
      }
      $this.Child = $Child
   }

   [String]GetChildFullname(
      [int]$index
   ) {
      #INFO concatenates only string1 - there might be an issue with path(s) not existing
      return ("$($this.Root.Path)\$($this.Child[$index].path)")
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
   [FMDirectory]::New($Root,$Child)
}

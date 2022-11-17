enum IMInheritance {
   ThisFolderOnly
   ThisFolderSubfoldersAndFiles
   ThisFolderSubfolder
   ThisFolderFiles
   OnlySubfoldersFiles
   OnlySubfolders
   OnlyFiles
}
<#
$IMInheritanceConversionTable = @{
   [IMInheritance]::ThisFolderOnly               = @{Propagate = 'NoPropagateInherit'; Inherit = '' };
   [IMInheritance]::ThisFolderSubfoldersAndFiles = @{Propagate = 'None'; Inherit = 'ContainerInherit,ObjectInherit' };
   [IMInheritance]::ThisFolderSubfolder          = @{Propagate = 'None'; Inherit = 'ContainerInherit' };
   [IMInheritance]::ThisFolderFiles              = @{Propagate = 'None'; Inherit = 'ObjectInherit' };
   [IMInheritance]::OnlySubfoldersFiles          = @{Propagate = 'InheritOnly'; Inherit = 'ContainerInherit,ObjectInherit' };
   [IMInheritance]::OnlySubfolders               = @{Propagate = 'InheritOnly'; Inherit = 'ContainerInherit' };
   [IMInheritance]::OnlyFiles                    = @{Propagate = 'InheritOnly'; Inherit = 'ObjectInherit' }
}
#>
# https://learn.microsoft.com/de-de/powershell/module/microsoft.powershell.security/set-acl?view=powershell-7.2

Class FMPermission {
   # A helper class to manage permissions
   [String]$Identity
   [System.Security.AccessControl.FileSystemRights]$Permission
   [IMInheritance]$Inheritance

   FMPermission(
      [String]$Identity,
      [System.Security.AccessControl.FileSystemRights]$Permission,
      [IMInheritance]$Inheritance
   ) {
      $this.Identity = $Identity
      $this.Permission = $Permission
      $this.Inheritance = $Inheritance
   }

   #methods
   [hashtable]GetInheritance() {
      $IMInheritanceConversionTable = @{
         [IMInheritance]::ThisFolderOnly               = @{Propagate = 'None'; Inherit = 'None' };
         [IMInheritance]::ThisFolderSubfoldersAndFiles = @{Propagate = 'None'; Inherit = 'ContainerInherit,ObjectInherit' };
         [IMInheritance]::ThisFolderSubfolder          = @{Propagate = 'None'; Inherit = 'ContainerInherit' };
         [IMInheritance]::ThisFolderFiles              = @{Propagate = 'None'; Inherit = 'ObjectInherit' };
         [IMInheritance]::OnlySubfoldersFiles          = @{Propagate = 'InheritOnly'; Inherit = 'ContainerInherit,ObjectInherit' };
         [IMInheritance]::OnlySubfolders               = @{Propagate = 'InheritOnly'; Inherit = 'ContainerInherit' };
         [IMInheritance]::OnlyFiles                    = @{Propagate = 'InheritOnly'; Inherit = 'ObjectInherit' }
      }
      return $IMInheritanceConversionTable[$this.Inheritance]
   }
}
# helper function to call constructor
Function New-FMPermission {
   Param(
      [String]$Identity,
      [System.Security.AccessControl.FileSystemRights]$Permission,
      [IMInheritance]$Inheritance
   )
   [FMPermission]::New($Identity, $Permission, $Inheritance)
}

Class FMPathPermission {
   [String[]]$Path
   [FMPermission[]]$Permission
   [hashtable]$ACRule = @{
      # as standard break inheritance and copy existing acls
      # see example 4: https://learn.microsoft.com/de-de/powershell/module/microsoft.powershell.security/set-acl?view=powershell-7.2
      isProtected         = $true
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
}

#helper function to call constructor
Function New-FMPathPermission {
   [CmdletBinding()]
   Param (
      [Parameter(ParameterSetName = 'Default')]
      [Parameter(ParameterSetName = 'InputObject')]
      [String[]]$Path,
      [Parameter(ParameterSetName = 'InputObject')]
      [FMPermission[]]$InputObject,
      [Parameter(ParameterSetName = 'Default')]
      [String[]]$Identity,
      [Parameter(ParameterSetName = 'Default')]
      [System.Security.AccessControl.FileSystemRights[]]$Permission,
      [Parameter(ParameterSetName = 'Default')]
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
      $InputObject = @()
      for ($i = 0; $i -lt $Identity.count; $i++) {
         $InputObject += New-FMPermission -Identity $Identity[$i] -Permission $Permission[$i] -Inheritance $Inheritance[$i]
      }
      #}
      [FMPathPermission]::New($Path, $InputObject)
   }
}
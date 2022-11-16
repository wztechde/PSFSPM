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
   ){
      $this.Path=$Path
      $this.Permission=$Permission
   }
}

#helper function to call constructor
Function New-FMPathPermission {
   Param (
      [Parameter(ParameterSetName='Default')]
      [Parameter(ParameterSetName='InputObject')]
      [String[]]$Path,
      [Parameter(ParameterSetName='InputObject')]
      [FMPermission[]]$InputObject
      )
         [FMPathPermission]::New($Path,$InputObject)
}
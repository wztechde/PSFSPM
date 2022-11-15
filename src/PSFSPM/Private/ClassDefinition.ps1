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
      [String]$id,
      [System.Security.AccessControl.FileSystemRights]$pm,
      [IMInheritance]$inh
   ) {
      $this.Identity = $id
      $this.Permission = $pm
      $this.Inheritance = $inh
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
      [String]$id,
      [System.Security.AccessControl.FileSystemRights]$pm,
      [IMInheritance]$inh
   )
   [FMPermission]::New($id,$pm,$inh)
}
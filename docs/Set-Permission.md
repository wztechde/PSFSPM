---
external help file: PSFSPM-help.xml
Module Name: PSFSPM
online version:
schema: 2.0.0
---

# Set-Permission

## SYNOPSIS
Set-Permission sets permission(s) on one or more paths

## SYNTAX

### Default (Default)
```
Set-Permission [-Path] <String[]> [-Identity <String[]>] [-Permission <FileRights[]>]
 [-Inheritance <IMInheritance[]>] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### PermissionObject
```
Set-Permission [-Path] <String[]> [-PermissionObject <FMPermission[]>] [-PassThru] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### PathPermissionObject
```
Set-Permission [-PathPermissionObject <FMPathPermission[]>] [-PassThru] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Set-Permission is used to set permissions on one or more paths (can even by piped in to the function).
You can set permissions for several users at once given as a list.
The function also takes several combinations of parameters to perform it's magic
Path + PermissionObject allows to give a path in combination with one or more permission objects
PathPermissionObject allows to give a full path permission objct to process (path with permissions)
DirectoryObject takes a complete directory permission object to process (root / child model)

## EXAMPLES

### EXAMPLE 1
```
Set-Permission -Path C:\Temp -Identity/Principal foo -Permission Write -Inheritance ThisFolderSubfoldersAndFiles
Set permission for C:\Temp to 'Write' for user 'foo' with inheritance 'ThisFolderSubfoldersAndFiles'
```

### EXAMPLE 2
```
Set-Permission -Path C:\Temp -Identity foo,bar -Permission Write,Read -Inheritance ThisFolderSubfoldersAndFiles,ThisFolderOnly
Set permission for C:\Temp to
   'Write' for user 'foo' with inheritance 'ThisFolderSubfoldersAndFiles'
   'Read' for user 'bar' with inheritance 'ThisFolderOnly' accordingly to the arrays given
```

### EXAMPLE 3
```
Set-Permission -Path 'C:\Temp','d:\Temp' -Identity foo,bar -Permission 'Write','Read' -Inheritance ThisFolderSubfoldersAndFiles,ThisFolderOnly
Set Permission for both C:\Temp AND D:\Temp to
   'Write' for user 'foo' with inheritance 'ThisFolderSubfoldersAndFiles'
   'Read' for user 'bar' with inheritance 'ThisFolderOnly' accordingly to the arrays given
```

### EXAMPLE 4
```
C:\Temp | Set-Permission -Identity foo,bar -Permission 'Write','Read' -Inheritance ThisFolderSubfoldersAndFiles,ThisFolderOnly
Set permission for C:\Temp to 'Write' for user 'foo' with inheritance 'ThisFolderSubfoldersAndFiles', this time using the pipeline
```

### EXAMPLE 5
```
'C:\Temp','D:\Temp' | Set-Permission -Identity foo,bar -Permission 'Write','Read' -Inheritance ThisFolderSubfoldersAndFiles,ThisFolderOnly
Set permission for both C:\Temp AND D:\Temp
   to 'Write' for user 'foo' with inheritance 'ThisFolderSubfoldersAndFiles', this time using the pipeline
```

### EXAMPLE 6
```
Get-ChilditemEnhanced C:\Temp -StartDepth 2 | Set-Permission -Identity foo,bar -Permission 'Write','Read' -Inheritance ThisFolderSubfoldersAndFiles,ThisFolderOnly
Set permssions for the result of the GCE call (all items that are two levels from given path) to
   'Write' for user 'foo' with inheritance 'ThisFolderSubfoldersAndFiles'
   'Read' for user 'bar' with inheritance 'ThisFolderOnly' accordingly to the arrays given
   using the pipeline
```

### EXAMPLE 7
```
Set-Permission C:\Temp -
```

## PARAMETERS

### -Path
One or more paths, where you want to set the permission(s) on.
The validation, if the path exists may provide wrong results - make sure, that the given path
is not available in current dir.

```yaml
Type: String[]
Parameter Sets: Default, PermissionObject
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Identity
One or more identities for which you want to set rights for

```yaml
Type: String[]
Parameter Sets: Default
Aliases: Principal

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Permission
One or more permissions to set for the according identity(ies)

```yaml
Type: FileRights[]
Parameter Sets: Default
Aliases:
Accepted values: ListDirectory, ReadData, WriteData, CreateFiles, CreateDirectories, AppendData, ReadExtendedAttributes, WriteExtendedAttributes, Traverse, ExecuteFile, DeleteSubdirectoriesAndFiles, ReadAttributes, WriteAttributes, Write, Delete, ReadPermissions, Read, ReadAndExecute, Modify, ChangePermissions, TakeOwnership, Synchronize, FullControl

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Inheritance
One or more inheritances to set for the according identity(ies)

```yaml
Type: IMInheritance[]
Parameter Sets: Default
Aliases:
Accepted values: ThisFolderSubfoldersAndFiles, ThisFolderAndSubfolders, ThisFolderOnly, ThisFolderAndFiles, SubfoldersAndFilesOnly, SubfoldersOnly, FilesOnly, File

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PermissionObject
One or more PermissionObjects to apply to the given path

```yaml
Type: FMPermission[]
Parameter Sets: PermissionObject
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PathPermissionObject
One or more PathPermissionObjects to process

```yaml
Type: FMPathPermission[]
Parameter Sets: PathPermissionObject
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
primarily for testing purposes

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

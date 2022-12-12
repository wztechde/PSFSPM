---
external help file: PSFSPM-help.xml
Module Name: PSFSPM
online version:
schema: 2.0.0
---

# New-FMPathPermission

## SYNOPSIS
{{Fill in the Synopsis}}

## SYNTAX

### InputObject
```
New-FMPathPermission [-Path <String[]>] [-InputObject <FMPermission[]>] [<CommonParameters>]
```

### Default
```
New-FMPathPermission [-Path <String[]>] [-Identity <String[]>] [-Permission <FileSystemRights[]>]
 [-Inheritance <IMInheritance[]>] [<CommonParameters>]
```

## DESCRIPTION
{{Fill in the Description}}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Identity
{{Fill Identity Description}}

```yaml
Type: String[]
Parameter Sets: Default
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Inheritance
{{Fill Inheritance Description}}

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

### -InputObject
{{Fill InputObject Description}}

```yaml
Type: FMPermission[]
Parameter Sets: InputObject
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
{{Fill Path Description}}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Permission
{{Fill Permission Description}}

```yaml
Type: FileSystemRights[]
Parameter Sets: Default
Aliases:
Accepted values: ListDirectory, ReadData, WriteData, CreateFiles, CreateDirectories, AppendData, ReadExtendedAttributes, WriteExtendedAttributes, Traverse, ExecuteFile, DeleteSubdirectoriesAndFiles, ReadAttributes, WriteAttributes, Write, Delete, ReadPermissions, Read, ReadAndExecute, Modify, ChangePermissions, TakeOwnership, Synchronize, FullControl

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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

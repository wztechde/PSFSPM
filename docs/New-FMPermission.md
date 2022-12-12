---
external help file: PSFSPM-help.xml
Module Name: PSFSPM
online version:
schema: 2.0.0
---

# New-FMPermission

## SYNOPSIS
{{Fill in the Synopsis}}

## SYNTAX

```
New-FMPermission [[-Identity] <String>] [[-Permission] <FileSystemRights>] [[-Inheritance] <IMInheritance>]
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
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Inheritance
{{Fill Inheritance Description}}

```yaml
Type: IMInheritance
Parameter Sets: (All)
Aliases:
Accepted values: ThisFolderSubfoldersAndFiles, ThisFolderAndSubfolders, ThisFolderOnly, ThisFolderAndFiles, SubfoldersAndFilesOnly, SubfoldersOnly, FilesOnly, File

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Permission
{{Fill Permission Description}}

```yaml
Type: FileSystemRights
Parameter Sets: (All)
Aliases:
Accepted values: ListDirectory, ReadData, WriteData, CreateFiles, CreateDirectories, AppendData, ReadExtendedAttributes, WriteExtendedAttributes, Traverse, ExecuteFile, DeleteSubdirectoriesAndFiles, ReadAttributes, WriteAttributes, Write, Delete, ReadPermissions, Read, ReadAndExecute, Modify, ChangePermissions, TakeOwnership, Synchronize, FullControl

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

function Invoke-SetACL {
    param (
        [FMPathPermission]$InputObject
    )
    # check path prior to any activity
    If (-Not (Test-Path $InputObject.Path)) {
        Throw "Cannot find path " + [char]39 +"$($InputObject.Path)"+[char]39+" because it does not exist"
    }

}
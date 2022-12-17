Configuration EnvironmentVariableConfig
{
    param ()

    Import-DscResource -ModuleName 'PSDscResources'

    Node localhost
    {
        Environment CreatePathEnvironmentVariable
        {
            Name   = 'TestPathEnvironmentVariable'
            Value  = 'TestValue'
            Ensure = 'Present'
            Path   = $true
            Target = @( 'Process', 'Machine' )
        }
    }
}

EnvironmentVariableConfig

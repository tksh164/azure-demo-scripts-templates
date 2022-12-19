Configuration mconfig
{
    Import-DscResource -ModuleName 'PSDscResources'

    Node localhost
    {
        Environment CreatePathEnvironmentVariable
        {
            Name   = 'TestPathEnvironmentVariable'
            Value  = 'DefaultValue'
            Ensure = 'Present'
            Path   = $true
            Target = @( 'Process', 'Machine' )
        }
    }
}

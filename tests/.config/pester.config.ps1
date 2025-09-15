@{
    Run = @{
        Path = @(
            "tests/pipelines"
            "tests/scripts"
        )
        PassThru = $true
        Exit = $true
    }
    Output = @{
        Verbosity = "Detailed"
        StackTraceVerbosity = "Full"
    }
    TestResult = @{
        Enabled = $true
        OutputPath = "test-results.xml"
        OutputFormat = "NUnitXml"
    }
}
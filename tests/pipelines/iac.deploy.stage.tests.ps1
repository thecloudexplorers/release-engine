BeforeAll {
    # Import PowerShell YAML module if not already available
    if (-not (Get-Module -Name powershell-yaml)) {
        Install-Module -Name powershell-yaml -Force -SkipPublisherCheck
    }
    Import-Module -Name powershell-yaml

    # Path to the YAML file being tested
    $script:yamlPath = Join-Path $PSScriptRoot "..\..\common\pipelines\02-stages\iac.deploy.stage.yml"
    $script:yamlContent = Get-Content -Path $yamlPath -Raw
}

Describe "iac.deploy.stage.yml Validation" {
    Context "File Structure" {
        It "YAML file should exist" {
            Test-Path $yamlPath | Should -Be $true
        }

        It "Should be valid YAML" {
            { ConvertFrom-Yaml -Yaml $yamlContent } | Should -Not -Throw
        }
    }

    Context "Parameters" {
        BeforeAll {
            $yaml = ConvertFrom-Yaml -Yaml $yamlContent
        }

        It "Should have workloadSettings parameter" {
            $yaml.parameters | Should -Not -Be $null
            $yaml.parameters[0].name | Should -Be "workloadSettings"
            $yaml.parameters[0].type | Should -Be "object"
        }
    }

    Context "Stage Structure" {
        BeforeAll {
            $yaml = ConvertFrom-Yaml -Yaml $yamlContent
        }

        It "Should have stages defined" {
            $yaml.stages | Should -Not -Be $null
        }

        It "Should use proper stage naming convention" {
            $yaml.stages[0] | Should -Not -Be $null
            $yaml.stages[0].Keys | Should -Contain '${{ each env in parameters.workloadSettings.environments }}'
        }
    }
}